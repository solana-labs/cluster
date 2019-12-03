# source this file

REGION=us-west1
ZONE=${REGION}-b

INSTANCE_PREFIX=
PROJECT=solana-mainnet

if [[ -z $PRODUCTION ]]; then
  INSTANCE_PREFIX="$(whoami)-test-"
  PROJECT=principal-lane-200702
fi

