#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"

source env.sh

mkdir -p "$CLUSTER"

keygen() {
  declare cmd=$*

  solana-keygen --version
  for zone in "${VALIDATOR_ZONES[@]}"; do
    test -f "$CLUSTER"/validator-identity-"$zone".json ||
      (set -x; solana-keygen $cmd --outfile "$CLUSTER"/validator-identity-"$zone".json)
    test -f "$CLUSTER"/validator-vote-account-"$zone".json ||
      (set -x; solana-keygen $cmd --outfile "$CLUSTER"/validator-vote-account-"$zone".json)
    test -f "$CLUSTER"/validator-stake-account-"$zone".json ||
      (set -x; solana-keygen $cmd --outfile "$CLUSTER"/validator-stake-account-"$zone".json)
  done

  if [[ -n $FAUCET_KEYPAIR ]]; then
    test -f "$CLUSTER"/faucet.json ||
      (set -x; solana-keygen $cmd --outfile "$CLUSTER"/faucet.json)
  fi

  test -f "$CLUSTER"/api-identity.json ||
    (set -x; solana-keygen $cmd --outfile "$CLUSTER"/api-identity.json)

  for zone in "${WAREHOUSE_ZONES[@]}"; do
    test -f "$CLUSTER"/warehouse-identity-"$zone".json ||
      (set -x; solana-keygen $cmd --outfile "$CLUSTER"/warehouse-identity-"$zone".json)
  done
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
