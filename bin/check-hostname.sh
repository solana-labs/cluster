#!/bin/sh

if [ ! -r ~/.hostname ] || ! diff /etc/hostname ~/.hostname; then
  if [ -f ~/api-identity.json ]; then
    echo "Hostname has changed, regenerating keys"
    solana-keygen new --force --outfile ~/api-identity.json --no-passphrase
    cp /etc/hostname ~/.hostname
  else
    echo "Error: hostname has changed. To continue, run: cp /etc/hostname ~/.hostname"
    exit 1
  fi
fi
