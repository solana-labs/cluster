#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"

source env.sh

mkdir -p "$CLUSTER"

keygen() {
  declare cmd=$@

  solana-keygen --version

  test -f "$CLUSTER"/validator-identity.json ||
    (set -x; solana-keygen $cmd --outfile "$CLUSTER"/validator-identity.json)
  test -f "$CLUSTER"/validator-vote-account.json ||
    (set -x; solana-keygen $cmd --outfile "$CLUSTER"/validator-vote-account.json)
  test -f "$CLUSTER"/validator-stake-account.json ||
    (set -x; solana-keygen $cmd --outfile "$CLUSTER"/validator-stake-account.json)

  if [[ -n $FAUCET_KEYPAIR ]]; then
    test -f "$CLUSTER"/faucet.json ||
      (set -x; solana-keygen $cmd --outfile "$CLUSTER"/faucet.json)
  fi

  test -f "$CLUSTER"/api-identity.json ||
    (set -x; solana-keygen $cmd --outfile "$CLUSTER"/api-identity.json)

  if [[ -n $WAREHOUSE_NODE ]]; then
    test -f "$CLUSTER"/warehouse-identity.json ||
      (set -x; solana-keygen $cmd --outfile "$CLUSTER"/warehouse-identity.json)
  fi
}

case "$1" in
recover)
  keygen recover
  ;;
'')
  keygen new --no-passphrase
  ;;
*)
  echo "Error: unknown argument: -$1-"
  exit 1
  ;;
esac
