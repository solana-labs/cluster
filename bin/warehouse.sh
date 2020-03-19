#!/usr/bin/env bash

set -e
shopt -s nullglob

here=$(dirname "$0")

panic() {
  echo "error: $*" >&2
  exit 1

}

#shellcheck source=/dev/null
source ~/service-env.sh

#shellcheck source=/dev/null
source ~/service-env-warehouse-*.sh

#shellcheck source=./configure-metrics.sh
source "$here"/configure-metrics.sh

if [[ -z $ENTRYPOINT ]]; then
  echo ENTRYPOINT environment variable not defined
  exit 1
fi

if [[ -z $EXPECTED_GENESIS_HASH ]]; then
  echo EXPECTED_GENESIS_HASH environment variable not defined
  exit 1
fi

if [[ -z $EXPECTED_SHRED_VERSION ]]; then
  echo EXPECTED_SHRED_VERSION environment variable not defined
  exit 1
fi

if [[ -z $LEDGER_ARCHIVE_INTERVAL_MINUTES ]]; then
  echo LEDGER_ARCHIVE_INTERVAL_MINUTES environment variable not defined
  exit 1
fi

if [[ -z $STORAGE_BUCKET ]]; then
  echo STORAGE_BUCKET environment variable not defined
  exit 1
fi

if [[ -z $RPC_URL ]]; then
  echo RPC_URL environment variable not defined
  exit 1
fi

ledger_dir=~/ledger
exit_signal_file=~/warehouse-exit-signal

if [[ -f $exit_signal_file ]]; then
  echo $exit_signal_file present, refusing to start
  exit 0
fi


identity_keypair=~/warehouse-identity-$ZONE.json
identity_pubkey=$(solana-keygen pubkey "$identity_keypair")

datapoint_error() {
  declare event=$1
  declare args=$2

  declare comma=
  if [[ -n $args ]]; then
    comma=,
  fi

  $metricsWriteDatapoint "infra-warehouse-node,host_id=$identity_pubkey error=1,event=\"$event\"$comma$args"
}

datapoint() {
  declare event=$1
  declare args=$2

  declare comma=
  if [[ -n $args ]]; then
    comma=,
  fi

  $metricsWriteDatapoint "infra-warehouse-node,host_id=$identity_pubkey error=0,event=\"$event\"$comma$args"
}


trusted_validators=()
for tv in "${TRUSTED_VALIDATOR_PUBKEYS[@]}"; do
  [[ $tv = "$identity_pubkey" ]] || trusted_validators+=(--trusted-validator "$tv")
done

args=(
  --dynamic-port-range 8001-8010
  --entrypoint "$ENTRYPOINT"
  --expected-genesis-hash "$EXPECTED_GENESIS_HASH"
  --expected-shred-version "$EXPECTED_SHRED_VERSION"
  --wait-for-supermajority "$WAIT_FOR_SUPERMAJORITY"
  --gossip-port 8001
  --identity "$identity_keypair"
  --ledger "$ledger_dir"
  --log ~/validator.log
  --no-genesis-fetch
  --no-voting
  --rpc-port 8899
  "${trusted_validators[@]}"
  --no-untrusted-rpc
  --init-complete-file ~/.init-complete
)

pid=
kill_node() {
  # Note: do not echo anything from this function to ensure $pid is actually
  # killed when stdout/stderr are redirected
  set +ex
  if [[ -n $pid ]]; then
    declare _pid=$pid
    pid=
    kill "$_pid" || true
    wait "$_pid" || true
  fi
}
kill_node_and_exit() {
  kill_node
  exit
}
trap 'kill_node_and_exit' INT TERM ERR


upload_to_storage_bucket() {
  if [[ ! -d ~/"$STORAGE_BUCKET" ]]; then
    return
  fi
  killall gsutil || true

  for rocksdb in ~/"$STORAGE_BUCKET"/*/rocksdb; do
    SECONDS=
    (
      cd "$(dirname "$rocksdb")"
      declare archive_dir=$PWD
      echo "Creating rocksdb.tar.bz2 in $archive_dir"
      rm -rf rocksdb.tar.bz2
      tar jcf rocksdb.tar.bz2 rocksdb
      rm -rf rocksdb
      echo "$archive_dir/rocksdb.tar.bz2 created in $SECONDS seconds"
    )
    datapoint created-rocksdb-tar-bz2 "duration_secs=$SECONDS"
  done

  SECONDS=
  while ! timeout $((LEDGER_ARCHIVE_INTERVAL_MINUTES / 2))m gsutil -m rsync -r ~/"$STORAGE_BUCKET" gs://"$STORAGE_BUCKET"/; do
    echo "gsutil rsync failed..."
    datapoint_error gsutil-rsync-failure
    sleep 5

    if [[ $((SECONDS / 60)) -lt $((LEDGER_ARCHIVE_INTERVAL_MINUTES / 2)) ]]; then
      echo Failure to upload ledger in $SECONDS seconds
      return
    fi
  done
  echo Ledger upload took $SECONDS seconds
  datapoint ledger-upload-complete "duration_secs=$SECONDS"
  rm -rf ~/"$STORAGE_BUCKET"
}

get_latest_snapshot() {
  declare dir="$1"
  if [[ ! -d "$dir" ]]; then
    panic "get_latest_snapshot: not a directory: $dir"
  fi

  find "$dir" -name snapshot-\*.tar.bz2 | sort | tail -n1
}

get_snapshot_slot() {
  declare snapshot="$1"

  snapshot="$(basename "$snapshot")"
  snapshot="${snapshot#snapshot-}"
  snapshot="${snapshot%-*}"
  echo "$snapshot"
}

archive_snapshot_slot=invalid

prepare_archive_location() {
  # If a current archive directory does not exist, create it and save the latest
  # snapshot in it (if not at genesis)
  if [[ ! -d ~/ledger-archive ]]; then
    mkdir ~/ledger-archive
    declare archive_snapshot
    archive_snapshot=$(get_latest_snapshot "$ledger_dir")
    if [[ -n "$archive_snapshot" ]]; then
      ln "$archive_snapshot" ~/ledger-archive/
    fi
  fi

  # Determine the current archive slot
  declare archive_snapshot
  archive_snapshot=$(get_latest_snapshot ~/ledger-archive)
  if [[ -n "$archive_snapshot" ]]; then
    archive_snapshot_slot=$(get_snapshot_slot "$archive_snapshot")
  else
    archive_snapshot_slot=0
  fi
}

prepare_archive_location

while true; do
  rm -f ~/.init-complete

  solana-validator "${args[@]}" &
  pid=$!
  datapoint validator-started

  echo "pid: $pid"

  minutes_to_next_ledger_archive=$LEDGER_ARCHIVE_INTERVAL_MINUTES
  caught_up=false
  initialized=false
  SECONDS=
  while true; do
    if [[ -z $pid ]] || ! kill -0 "$pid"; then
      datapoint_error unexpected-validator-exit
      break  # validator exited unexpectedly, restart it
    fi

    if ! $initialized; then
      if [[ ! -f ~/.init-complete ]]; then
        echo "waiting for node to initialize..."
        if [[ $SECONDS -gt 600 ]]; then
          datapoint_error validator-not-initialized
        fi
        sleep 10
        continue
      fi
      echo Validator has initialized
      datapoint validator-initialized
      initialized=true
    fi

    if ! $caught_up; then
      if ! timeout 10m solana catchup --url "$RPC_URL" "$identity_pubkey"; then
        echo "catchup failed..."
        if [[ $SECONDS -gt 600 ]]; then
          datapoint_error validator-not-caught-up
        fi
        sleep 60
        continue
      fi
      echo Validator has caught up
      datapoint validator-caught-up
      caught_up=true
    fi

    sleep 60

    if ((--minutes_to_next_ledger_archive > 0)); then
      if ((minutes_to_next_ledger_archive % 60 == 0)); then
        datapoint waiting-to-archive "minutes_remaining=$minutes_to_next_ledger_archive"
      fi

      if [[ -f $exit_signal_file ]]; then
        echo $exit_signal_file present, forcing ledger archive
      else
        echo "$minutes_to_next_ledger_archive minutes before next ledger archive"
        continue
      fi
    fi

    latest_snapshot=$(get_latest_snapshot "$ledger_dir")
    if [[ -z $latest_snapshot ]]; then
      echo "Validator has not produced a snapshot yet"
      datapoint_error snapshot-missing
      minutes_to_next_ledger_archive=1 # try again later
      continue
    fi
    latest_snapshot_slot=$(get_snapshot_slot "$latest_snapshot")
    echo "Latest snapshot: slot $latest_snapshot_slot: $latest_snapshot"

    if [[ "$archive_snapshot_slot" = "$latest_snapshot_slot" ]]; then
      echo "Validator has not produced a new snapshot yet"
      datapoint_error stale-snapshot
      minutes_to_next_ledger_archive=1 # try again later
      continue
    fi

    echo Killing the node
    datapoint validator-terminated
    kill_node

    echo "Archiving snapshot from $archive_snapshot_slot and subsequent ledger"
    SECONDS=
    (
      set -x
      solana-ledger-tool --ledger "$ledger_dir" bounds | tee ~/bounds.txt
    )
    ledger_bounds="$(cat ~/bounds.txt)"
    datapoint ledger-archived "label=\"$archive_snapshot_slot\",duration_secs=$SECONDS,bounds=\"$ledger_bounds\""

    mv "$ledger_dir"/rocksdb ~/ledger-archive/

    mkdir -p ~/"$STORAGE_BUCKET"
    mv ~/ledger-archive ~/"$STORAGE_BUCKET"/"$archive_snapshot_slot"

    # Clean out the ledger directory from all artifacts other than genesis and
    # the snapshot archives, so the warehouse node restarts cleanly from its
    # last snapshot
    rm -rf "$ledger_dir"/accounts "$ledger_dir"/snapshot

    # Prepare for next archive
    rm -rf ~/ledger-archive
    prepare_archive_location

    if [[ -f $exit_signal_file ]]; then
      echo $exit_signal_file present, forcing foreground upload
      upload_to_storage_bucket
      exit 0
    fi
    upload_to_storage_bucket &

    break
  done
done
