#!/usr/bin/env bash

#shellcheck source=/dev/null
. ~/service-env.sh

echo ----------------------------------------------------------------
shopt -s nullglob
for keypair in ~/*.json; do
  echo "$(basename "$keypair"): $(solana-keygen pubkey "$keypair")"
done
