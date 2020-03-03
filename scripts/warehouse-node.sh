#!/usr/bin/env bash

set -e
here=$(dirname "$0")

#shellcheck source=/dev/null
source "$here"/service-env.sh
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

if [[ -z $ARCHIVE_INTERVAL_MINUTES ]]; then
  echo ARCHIVE_INTERVAL_MINUTES environment variable not defined
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

solana-keygen new --silent --force --no-passphrase --outfile "$here"/identity.json

ledger_dir="$here"/ledger

args=(
  --dynamic-port-range 8001-8010
  --entrypoint "$ENTRYPOINT"
  --expected-genesis-hash "$EXPECTED_GENESIS_HASH"
  --expected-shred-version "$EXPECTED_SHRED_VERSION"
  --gossip-port 8001
  --identity-keypair "$here"/identity.json
  --ledger "$ledger_dir"
  --log "$here"/validator.log
  --no-genesis-fetch
  --no-voting
  --rpc-port 8899
  --skip-poh-verify
  --dev-no-sigverify
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
  solana-validator "${args[@]}" &
  pid=$!
  $metricsWriteDatapoint "infra-warehouse-node event=\"validator-started\""
  echo "pid: $pid"

  minutes_to_next_ledger_archive=$ARCHIVE_INTERVAL_MINUTES
  caught_up=false
  while true; do
    if [[ -z $pid ]] || ! kill -0 "$pid"; then
      $metricsWriteDatapoint "infra-warehouse-node,error=1 event=\"unexpected-validator-exit\""
      break  # validator exited unexpectedly, restart it
    fi

    if ! $caught_up; then
      if ! timeout 10m solana catchup --url "$RPC_URL" "$here"/identity.json; then
        echo "catchup failed..."
        sleep 5
        continue
      fi
      echo Node has caught up
      $metricsWriteDatapoint "infra-warehouse-node event=\"validator-caught-up\""
      caught_up=true
    fi

    sleep 60

    if ((--minutes_to_next_ledger_archive > 0)); then
      if ((minutes_to_next_ledger_archive % 60 == 0)); then
        $metricsWriteDatapoint "infra-warehouse-node event=\"waiting-to-archive\",minutes_remaining=$minutes_to_next_ledger_archive"
      fi
      echo "$minutes_to_next_ledger_archive minutes before next ledger archive"
      continue
    fi

    latest_snapshot="$(ls "$ledger_dir"/snapshot-*.tar.bz2 | sort | tail -n1)"
    echo "Latest snapshot: $latest_snapshot"
    if [[ ! -f "$latest_snapshot" ]]; then
      echo "Validator has not produced a snapshot yet"
      $metricsWriteDatapoint "infra-warehouse-node,error=1 event=\"snapshot-missing\""
      minutes_to_next_ledger_archive=1 # try again later
      continue
    fi

    if [[ -d "$last_ledger_dir" ]] && diff -q "$latest_snapshot" "$last_ledger_dir/snapshot.tar.bz2"; then
      echo "Validator has not produced a new snapshot yet"
      $metricsWriteDatapoint "infra-warehouse-node,error=1 event=\"stale-snapshot\""
      minutes_to_next_ledger_archive=1 # try again later
      continue
    fi

    echo Killing the node
    $metricsWriteDatapoint "infra-warehouse-node event=\"validator-terminated\""
    kill_node

    echo Open the ledger to force a rocksdb log file cleanup
    SECONDS=
    (
      set -x
      solana-ledger-tool --ledger "$ledger_dir" bounds
    )
    echo Ledger compaction took $SECONDS seconds
    $metricsWriteDatapoint "infra-warehouse-node event=\"ledger-compacted\",duration_secs=$SECONDS"

    echo Archive the current ledger and snapshot
    if [[ -n "$last_ledger_dir" ]]; then
      rm -rf "$last_ledger_dir"
    fi
    timestamp="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
    last_ledger_dir="$ledger_dir$timestamp"
    mkdir "$last_ledger_dir"
    mv "$ledger_dir"/rocksdb "$last_ledger_dir"
    ln -sf "$latest_snapshot" "$last_ledger_dir"/snapshot.tar.bz2
    ln "$latest_snapshot" "$last_ledger_dir"/

    SECONDS=
    while ! gsutil -m rsync -r "$last_ledger_dir" gs://"$STORAGE_BUCKET"/"$timestamp"; do
      echo "gsutil rsync failed..."
      $metricsWriteDatapoint "infra-warehouse-node,error=1 event=\"gsutil-rsync-failure\""
      sleep 5
    done
    echo Ledger archiving took $SECONDS seconds
    $metricsWriteDatapoint "infra-warehouse-node event=\"ledger-archived\",label=\"$timestamp\",duration_secs=$SECONDS"
    break
  done
done
