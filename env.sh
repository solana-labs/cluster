# source this file

REGION=us-west1
ZONE=${REGION}-b

INSTANCE_PREFIX=
PROJECT=solana-mainnet

if [[ -z $PRODUCTION ]]; then
  INSTANCE_PREFIX="$(whoami)-test-"
  PROJECT=principal-lane-200702
fi

if [[ -z $GRAFANA_API_TOKEN ]]; then
  GRAFANA_API_TOKEN=eyJrIjoiTHJ4elY0b0VIeENMV3NUMEMwSXk5SHdQYnI3SjZCcTIiLCJuIjoiZ3JhZmNsaSIsImlkIjoyfQ==
fi

STORAGE_BUCKET=${INSTANCE_PREFIX}solana-ledger
