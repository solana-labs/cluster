#!/usr/bin/env bash
set -e

cd "$(dirname "$0")"
source env.sh

if [[ -d "$CLUSTER"/ledger ]]; then
  echo "Error: "$CLUSTER"/ledger/ directory already exists"
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
  --bootstrap-validator-pubkey "$CLUSTER"/bootstrap-validator-identity.json
  --bootstrap-vote-pubkey "$CLUSTER"/bootstrap-validator-vote-account.json
  --bootstrap-stake-pubkey "$CLUSTER"/bootstrap-validator-stake-account.json
  --bootstrap-validator-lamports             1000000000 # 1 SOL for voting
  --bootstrap-validator-stake-lamports  500000000000000 # 500,000 thousand SOL
  --rent-burn-percentage 100                         # Burn it all!
  --target-lamports-per-signature 0                  # No transaction fees
  --ledger "$CLUSTER"/ledger
)

if [[ -n $BOOTSTRAP_STAKE_AUTHORIZED_PUBKEY ]]; then
  args+=(--bootstrap-stake-authorized-pubkey $BOOTSTRAP_STAKE_AUTHORIZED_PUBKEY)
fi

if [[ -n $FAUCET ]]; then
  args+=(--faucet-pubkey "$CLUSTER"/faucet.json --faucet-lamports 500000000000000000)
fi

if [[ -n $EXTERNAL_ACCOUNTS_FILE_URL ]]; then
  (
    set -x
    wget "$EXTERNAL_ACCOUNTS_FILE_URL" -O "$CLUSTER"/external-accounts.yml
  )
  args+=(--primordial-accounts-file "$CLUSTER"/external-accounts.yml)
fi

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
