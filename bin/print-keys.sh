#!/usr/bin/env bash

#shellcheck source=/dev/null
. ~/service-env.sh

echo ----------------------------------------------------------------
solana-install info
echo ----------------------------------------------------------------
(
  export PS4="==> "
  set -x
  df -h . ledger/
  du -hs ledger/
  free -h
  uptime
)
echo ----------------------------------------------------------------
shopt -s nullglob
for keypair in ~/*.json; do
  echo "$(basename "$keypair"): $(solana-keygen pubkey "$keypair")"
done
