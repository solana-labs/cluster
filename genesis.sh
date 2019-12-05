#!/usr/bin/env bash
set -e

cd "$(dirname "$0")"
if [[ -d ledger ]]; then
  echo "Error: ledger/ directory already exists"
  exit 1
fi

solana-genesis --version
solana-keygen --version
solana-ledger-tool --version

solana-keygen new --silent --force --no-passphrase --outfile bootstrap-leader-identity.json
solana-keygen new --silent --force --no-passphrase --outfile bootstrap-leader-vote-account.json
solana-keygen new --silent --force --no-passphrase --outfile bootstrap-leader-stake-account.json

args=(
  --bootstrap-leader-pubkey bootstrap-leader-identity.json
  --bootstrap-vote-pubkey bootstrap-leader-vote-account.json
  --bootstrap-stake-pubkey bootstrap-leader-stake-account.json
  --bootstrap-leader-lamports             1000000000 # 1 SOL for voting
  --bootstrap-leader-stake-lamports 1000000000000000 # 1 million SOL
  --rent-burn-percentage 100                         # Burn it all!
  --target-lamports-per-signature 0                  # No transaction fees
  --ledger ledger
)
solana-genesis "${args[@]}"

du -ah ledger

echo "Genesis hash: $(RUST_LOG=none solana-ledger-tool print-genesis-hash --ledger ledger)"
