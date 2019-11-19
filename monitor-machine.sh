#!/usr/bin/env bash

instanceName=$1

if [[ -z $instanceName ]]; then
  echo "Usage $0 [instance name]"
  exit 1
fi

set -x
gcloud --project solana-mainnet compute ssh "$instanceName" -- journalctl -u "solana-\*" -f
