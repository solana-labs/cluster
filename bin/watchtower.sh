#!/usr/bin/env bash
set -ex

#shellcheck source=/dev/null
. ~/service-env.sh

args=(
  --url "$RPC_URL"
  --monitor-active-stake
  --unhealthy-threshold 2
)

for tv in "${TRUSTED_VALIDATOR_PUBKEYS[@]}"; do
  args+=(--validator-identity "$tv")
done

exec solana-watchtower "${args[@]}"
