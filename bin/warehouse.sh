#!/usr/bin/env bash

set -e
here=$(dirname "$0")

#shellcheck source=/dev/null
source ~/service-env.sh ~/service-env-*.sh

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

identity_keypair=~/warehouse-identity-$ZONE.json
identity_pubkey=$(solana-keygen pubkey "$identity_keypair")

datapoint_error() {
  declare event=$1
  declare args=$2

  declare comma=
  if [[ -n $args ]]; then
    comma=,
  fi

  $metricsWriteDatapoint "infra-warehouse-node,host_id=$identity_pubkey,error=1 event=\"$event\"$comma$args"
}

datapoint() {
  declare event=$1
  declare args=$2

  declare comma=
  if [[ -n $args ]]; then
    comma=,
  fi

  $metricsWriteDatapoint "infra-warehouse-node,host_id=$identity_pubkey event=\"$event\"$comma$args"
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
  --identity-keypair "$identity_keypair"
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

last_ledger_dir=
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
        sleep 60
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
      echo "$minutes_to_next_ledger_archive minutes before next ledger archive"
      continue
    fi

    latest_snapshot="$(ls "$ledger_dir"/snapshot-*.tar.bz2 | sort | tail -n1)"
    echo "Latest snapshot: $latest_snapshot"
    if [[ ! -f "$latest_snapshot" ]]; then
      echo "Validator has not produced a snapshot yet"
      datapoint_error snapshot-missing
      minutes_to_next_ledger_archive=1 # try again later
      continue
    fi

    if [[ -d "$last_ledger_dir" ]] && [[ -f "$last_ledger_dir/$(basename "$latest_snapshot")" ]] ; then
      echo "Validator has not produced a new snapshot yet"
      datapoint_error stale-snapshot
      minutes_to_next_ledger_archive=1 # try again later
      continue
    fi

    echo Killing the node
    datapoint validator-terminated
    kill_node

    echo Open the ledger to force a rocksdb log file cleanup
    SECONDS=
    (
      set -x
      solana-ledger-tool --ledger "$ledger_dir" bounds | tee bounds.txt
    )
    ledger_bounds="$(cat bounds.txt)"
    echo Ledger compaction took $SECONDS seconds
    datapoint ledger-compacted "duration_secs=$SECONDS"

    echo Archive the current ledger and snapshot
    if [[ -n "$last_ledger_dir" ]]; then
      rm -rf "$last_ledger_dir"
    fi
    timestamp="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
    last_ledger_dir="$ledger_dir$timestamp"
    mkdir "$last_ledger_dir"
    mv "$ledger_dir"/rocksdb "$last_ledger_dir"
    ln "$latest_snapshot" "$last_ledger_dir"/

    SECONDS=
    while ! gsutil -m rsync -r "$last_ledger_dir" gs://"$STORAGE_BUCKET"/"$timestamp"; do
      echo "gsutil rsync failed..."
      datapoint_error gsutil-rsync-failure
      sleep 5
    done
    echo Ledger archiving took $SECONDS seconds
    datapoint ledger-archived "label=\"$timestamp\",duration_secs=$SECONDS,bounds=\"$ledger_bounds\""
    break
  done
done
