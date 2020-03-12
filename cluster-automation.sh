#!/usr/bin/env bash

set -e

if [[ -n "$1" ]]; then
  RELEASE_CHANNEL_OR_TAG="$1"
fi

if [[ -z $RELEASE_CHANNEL_OR_TAG ]]; then
  echo RELEASE_CHANNEL_OR_TAG not defined
  exit 1
fi

INSTALL_PATH="$(dirname "$0")"

cd "$(dirname "$0")"
if [[ -d ledger ]]; then
  rm -rf ledger
fi

curl -sSf https://raw.githubusercontent.com/solana-labs/solana/v1.0.0/install/solana-install-init.sh | sh -s - "$RELEASE_CHANNEL_OR_TAG" --data-dir "$INSTALL_PATH"

PATH="${INSTALL_PATH}/active_release/bin:$PATH"

./genesis.sh

./launch-cluster.sh --release "$RELEASE_CHANNEL_OR_TAG"
