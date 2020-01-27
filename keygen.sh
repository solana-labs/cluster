#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"

keygen() {
  declare cmd=$@

  solana-keygen --version

  test -f bootstrap-validator-identity.json ||
    (set -x; solana-keygen $cmd --outfile bootstrap-validator-identity.json)
  test -f bootstrap-validator-vote-account.json ||
    (set -x; solana-keygen $cmd --outfile bootstrap-validator-vote-account.json)
  test -f bootstrap-validator-stake-account.json ||
    (set -x; solana-keygen $cmd --outfile bootstrap-validator-stake-account.json)
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
