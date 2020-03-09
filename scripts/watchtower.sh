#!/usr/bin/env bash
set -ex

#shellcheck source=/dev/null
. service-env.sh

trusted_validators=()
for tv in ${TRUSTED_VALIDATORS[@]}; do
  trusted_validators+=(--validator-identity "$tv")
done

exec solana-watchtower \
  --url "$RPC_URL" \
  "${trusted_validators[@]}" \
