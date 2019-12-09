#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"

keygen() {
  declare cmd=$@

  solana-keygen --version

  test -f bootstrap-leader-identity.json ||
    (set -x; solana-keygen $cmd --outfile bootstrap-leader-identity.json)
  test -f bootstrap-leader-vote-account.json ||
    (set -x; solana-keygen $cmd --outfile bootstrap-leader-vote-account.json)
  test -f bootstrap-leader-stake-account.json ||
    (set -x; solana-keygen $cmd --outfile bootstrap-leader-stake-account.json)
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
