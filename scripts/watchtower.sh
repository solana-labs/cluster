#!/usr/bin/env bash
set -ex

#shellcheck source=/dev/null
. service-env.sh

validators=()
for tv in ${WATCHTOWER_VALIDATORS[@]}; do
  validators+=(--validator-identity "$tv")
done

exec solana-watchtower --url "$RPC_URL" "${validators[@]}"
