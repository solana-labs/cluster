#!/usr/bin/env bash

#shellcheck source=/dev/null
. ~/service-env.sh

echo ----------------------------------------------------------------
solana-install info
echo ----------------------------------------------------------------
shopt -s nullglob
for keypair in ~/*.json; do
  echo "$(basename "$keypair"): $(solana-keygen pubkey "$keypair")"
done
