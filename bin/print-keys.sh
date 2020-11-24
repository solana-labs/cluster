#!/usr/bin/env bash

#shellcheck source=/dev/null
. ~/service-env.sh

echo --[ solana version ]--------------------------------------------
solana-install info
echo --[ system summary ]--------------------------------------------
(
  export PS4="==> "
  set -x
  ~/bin/hc
  df -h . ledger/ /mnt/solana-accounts
  du -hs ledger/
  free -h
  uptime
)
echo --[ validator logs ]--------------------------------------------
ls -l ~/solana-validator.log*
echo --[ keypairs ]--------------------------------------------------
shopt -s nullglob
for keypair in ~/*.json; do
  echo "$(basename "$keypair"): $(solana-keygen pubkey "$keypair")"
done
