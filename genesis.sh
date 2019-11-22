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

solana-keygen new --silent --force --outfile bootstrap-leader-identity.json
solana-keygen new --silent --force --outfile bootstrap-leader-vote-account.json
solana-keygen new --silent --force --outfile bootstrap-leader-stake-account.json

args=(
  --bootstrap-leader-pubkey bootstrap-leader-identity.json
  --bootstrap-vote-pubkey bootstrap-leader-vote-account.json
  --bootstrap-stake-pubkey bootstrap-leader-stake-account.json
  --bootstrap-leader-lamports 1000000000   # 1 SOL for voting
  --bootstrap-leader-stake-lamports 1      # Smallest possible stake
  --rent-exemption-threshold 0             # Disable rent
  --target-lamports-per-signature 1        # Smallest non-zero signature fee
  --ledger ledger
)
solana-genesis "${args[@]}"

du -ah ledger
