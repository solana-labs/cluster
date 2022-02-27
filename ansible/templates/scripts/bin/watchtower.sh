#!/usr/bin/env bash
set -ex

#shellcheck source=/dev/null
. ~/service-env.sh

validators=()
for tv in "${TRUSTED_VALIDATOR_PUBKEYS[@]}"; do
  validators+=(--validator-identity "$tv")
done

exec solana-watchtower \
  --url "$RPC_URL" \
  --monitor-active-stake \
  --no-duplicate-notifications \
  --minimum-validator-identity-balance 5\
  "${validators[@]}" \
