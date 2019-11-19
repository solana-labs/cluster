#!/usr/bin/env bash

instanceName=$1

if [[ -z $instanceName ]]; then
  echo "Usage $0 [instance name]"
  exit 1
fi

set -ex
gcloud --project solana-mainnet compute ssh "$instanceName" -- "
  set -ex
  sudo apt-get update
  sudo apt-get -y install vim
  sudo adduser solana --gecos "" --disabled-password --quiet
  sudo deluser solana google-sudoers
  sudo --login -u solana -- bash -c 'curl -sSf https://raw.githubusercontent.com/solana-labs/solana/v0.20.3/install/solana-install-init.sh | sh -s edge'
"

"$(dirname "$0")"/update-machine.sh "$instanceName"
