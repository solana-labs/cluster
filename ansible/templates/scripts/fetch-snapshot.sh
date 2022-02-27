#!/usr/bin/env bash

if [[ -z $1 ]]; then
  echo "Usage: $0 [bv1|bv2|bv3|bv4]"
  echo "Downloads the latest snapshot from a trusted validator over the internal GCP network"
  exit 0
fi

case $1 in
bv1)
  host=validator-us-west1-c
  ;;
bv2)
  host=validator-us-east1-c
  ;;
bv3)
  host=validator-europe-west4-c
  ;;
bv4)
  host=validator-asia-east2
  ;;
*)
  echo "Error: unknown validator: '$1'"
  exit 1
  ;;
esac

set -ex
cd ~/ledger
exec wget --trust-server-names http://$host/snapshot.tar.bz2
