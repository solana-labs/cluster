#!/usr/bin/env bash

set -e

cd "$(dirname "$0")"
source env.sh


snapshot=$1
if [[ -z $snapshot ]]; then
  (
    set -x
    gsutil ls gs://"$STORAGE_BUCKET"
  )
  exit 0
fi

(
  set -x
  rm -rf ledger-snapshot/
  mkdir ledger-snapshot/
  cd ledger-snapshot/
  gsutil -m rsync -r gs://"$STORAGE_BUCKET"/"$snapshot" .
  gsutil -m cp gs://"$STORAGE_BUCKET"/genesis.tar.bz2 .
  tar jvxf genesis.tar.bz2 genesis.bin
)

echo "Ledger snapshot downloaded to ledger-snapshot/"
du -hs ledger-snapshot/
