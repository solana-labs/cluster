#!/usr/bin/env bash
set -e

cd "$(dirname "$0")"
if [[ -d ledger ]]; then
  echo "Error: ledger/ directory already exists"
  exit 1
fi

solana-genesis --version
solana-ledger-tool --version

./keygen.sh

default_arg() {
  declare name=$1
  declare value=$2

  for arg in "${args[@]}"; do
    if [[ $arg = "$name" ]]; then
      return
    fi
  done

  if [[ -n $value ]]; then
    args+=("$name" "$value")
  else
    args+=("$name")
  fi
}

args=(
  --bootstrap-leader-pubkey bootstrap-leader-identity.json
  --bootstrap-vote-pubkey bootstrap-leader-vote-account.json
  --bootstrap-stake-pubkey bootstrap-leader-stake-account.json
  --bootstrap-stake-authorized-pubkey GRZwoJGisLTszcxtWpeREJ98EGg8pZewhbtcrikoU7b3 # Foundation key
  --bootstrap-leader-lamports             1000000000 # 1 SOL for voting
  --bootstrap-leader-stake-lamports  500000000000000 # 500,000 thousand SOL
  --rent-burn-percentage 100                         # Burn it all!
  --target-lamports-per-signature 0                  # No transaction fees
  --ledger ledger
)

while [[ -n $1 ]]; do
  if [[ ${1:0:1} = - ]]; then
    if [[ $1 = --creation-time ]]; then
      args+=("$1" "$2")
      shift 2
    else
      echo "Unknown argument: $1"
      $program --help
      exit 1
    fi
  else
    echo "Unknown argument: $1"
    $program --help
    exit 1
  fi
done

default_arg --creation-time "$(date --iso-8601=seconds)"
(
  set -x
  solana-genesis "${args[@]}"
)
du -ah ledger

echo "Genesis hash: $(RUST_LOG=none solana-ledger-tool print-genesis-hash --ledger ledger)"
