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
  df -h . /mnt/nvme1n1/ledger/ /mnt/accounts
  du -hs ledger/ 2>/dev/null
  free -h
  uptime
)
echo --[ validator logs ]--------------------------------------------
ls -l ~/logs/solana-validator.log*
echo --[ keypairs ]--------------------------------------------------
shopt -s nullglob
for keypair in ~/identity/*.json; do
  echo "$(basename "$keypair"): $(solana-keygen pubkey "$keypair")"
done
