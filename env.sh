# source this file

ZONE=us-west1-b

INSTANCE_PREFIX=
PROJECT=solana-mainnet

if [[ -z $PRODUCTION ]]; then
  INSTANCE_PREFIX="$(whoami)-test-"
  PROJECT=principal-lane-200702
fi
