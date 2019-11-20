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

GENESIS_HASH="$(RUST_LOG=none solana-ledger-tool print-genesis-hash --ledger ledger)"

tar jcfS ledger/genesis.tar.bz2 -C ledger genesis.bin rocksdb
du -ah ledger

(
  echo EXPECTED_GENESIS_HASH="$GENESIS_HASH"
  echo SOLANA_METRICS_CONFIG="host=https://metrics.solana.com:8086,db=mainnet,u=mainnet_write,p=2aQdShmtsPSAgABLQiK2FpSCJGLtG8h3vMEVz1jE7Smf"
) | tee service-env.sh

