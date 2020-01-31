#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"

source env.sh

mkdir -p "$CLUSTER"

if [[ -n $TESTNET_KEYPAIRS ]]; then
  if [[ ! -d testnet-keypairs ]]; then
    (
      set -x
      git clone git@github.com:solana-labs/testnet-keypairs.git
    )
  fi
  ln -sfT ../testnet-keypairs/faucet.json "$CLUSTER"/faucet.json
  ln -sfT ../testnet-keypairs/bootstrap-validator-identity.json "$CLUSTER"/bootstrap-validator-identity.json
fi

keygen() {
  declare cmd=$@

  solana-keygen --version

  test -f "$CLUSTER"/bootstrap-validator-identity.json ||
    (set -x; solana-keygen $cmd --outfile "$CLUSTER"/bootstrap-validator-identity.json)
  test -f "$CLUSTER"/bootstrap-validator-vote-account.json ||
    (set -x; solana-keygen $cmd --outfile "$CLUSTER"/bootstrap-validator-vote-account.json)
  test -f "$CLUSTER"/bootstrap-validator-stake-account.json ||
    (set -x; solana-keygen $cmd --outfile "$CLUSTER"/bootstrap-validator-stake-account.json)

  if [[ -n $FAUCET ]]; then
    test -f "$CLUSTER"/faucet.json ||
      (set -x; solana-keygen $cmd --outfile "$CLUSTER"/faucet.json)
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
