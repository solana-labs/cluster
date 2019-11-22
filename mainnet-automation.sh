#!/usr/bin/env bash

set -e
set -x

if [[ -n "$1" ]] ; then
  RELEASE_CHANNEL_OR_TAG="$1"
fi

if [[ -z $RELEASE_CHANNEL_OR_TAG ]] ; then
  echo RELEASE_CHANNEL_OR_TAG not defined
  exit 1
fi

INSTALL_PATH="$(dirname "$0")"

cd "$(dirname "$0")"
if [[ -d ledger ]]; then
  rm -rf ledger
fi

if [[ "$(uname)" == "Linux" ]] ; then
  echo Linux OS Detected
  TARBALL_NAME=solana-release-x86_64-unknown-linux-gnu.tar.bz2
elif [[ "$(uname)" == "Darwin" ]] ; then
  echo Mac OS Detected
  TARBALL_NAME=solana-release-x86_64-apple-darwin.tar.bz2
else
  echo Unknown OS detected
  exit 1
fi

DOWNLOAD_URL=http://release.solana.com/"$RELEASE_CHANNEL_OR_TAG"/"$TARBALL_NAME"
OUTFILE=solana-release.tar.bz2

if [[ -d "$OUTFILE" ]]; then
  rm -rf "$OUTFILE"
fi

wget $DOWNLOAD_URL -O $OUTFILE
tar jxf $OUTFILE

solana-release/bin/solana-install init edge --data-dir "$INSTALL_PATH"
PATH="${INSTALL_PATH}/active_release/bin:$PATH"

./genesis.sh

./launch-mainnet.sh --release "$RELEASE_CHANNEL_OR_TAG"
