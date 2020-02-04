# source this file

#RELEASE_CHANNEL_OR_TAG=beta
RELEASE_CHANNEL_OR_TAG=0.23.2

REGION=us-west1
ZONE=${REGION}-b

if [[ -z $GRAFANA_API_TOKEN ]]; then
  GRAFANA_API_TOKEN=eyJrIjoiTHJ4elY0b0VIeENMV3NUMEMwSXk5SHdQYnI3SjZCcTIiLCJuIjoiZ3JhZmNsaSIsImlkIjoyfQ==
fi

case $CLUSTER in
cluster)
  echo "### Global Cluster ###"
  PROJECT="solana-cluster"
  API_DNS_NAME=api.cluster.solana.com
  ENTRYPOINT_DNS_NAME=cluster.solana.com
  BOOTSTRAP_STAKE_AUTHORIZED_PUBKEY=3b7akieYUyCgz3Cwt5sTSErMWjg8NEygD6mbGjhGkduB # "one thanks" catch-all community pool
  SOLANA_METRICS_CONFIG="host=https://metrics.solana.com:8086,db=cluster,u=cluster_write,p=2aQdShmtsPSAgABLQiK2FpSCJGLtG8h3vMEVz1jE7Smf"
  # Tell `solana-watchtower` to notify the #slp1-validators Discord channel on a sanity failure
  # DISCORD_WEBHOOK=https://discordapp.com/api/webhooks/654940298375462932/KlprfdAahVxwyHptYsN9Lbitb8-kzRU4wOJ3e3QVndhzdwu28YbVtzRlb_BIZZA7c3ec
  ;;
tour-de-sol)
  echo "### TdS ###"
  PROJECT="tour-de-sol"
  API_DNS_NAME=tds.solana.com
  ENTRYPOINT_DNS_NAME=
  BOOTSTRAP_STAKE_AUTHORIZED_PUBKEY=
  EXTERNAL_ACCOUNTS_FILE_URL=https://raw.githubusercontent.com/solana-labs/tour-de-sol/master/validators/all-pubkey.yml
  FAUCET=1
  SOLANA_METRICS_CONFIG="host=https://metrics.solana.com:8086,db=tds,u=testnet_write,p=c4fa841aa918bf8274e3e2a44d77568d9861b3ea"
  ;;
*)
  echo "Error: unsupported CLUSTER='$CLUSTER'. Try 'cluster' or 'tour-de-sol'"
  exit 1
esac

STORAGE_BUCKET="${PROJECT}-ledger"
INSTANCE_PREFIX=
if [[ -z $PRODUCTION ]]; then
  INSTANCE_PREFIX="`whoami`-${PROJECT}-"
  STORAGE_BUCKET="`whoami`-$STORAGE_BUCKET"
  PROJECT=principal-lane-200702 # Jump to common development project

  TESTNET_KEYPAIRS=1            # Never use testnet keypairs in production

  API_DNS_NAME=                 # Ditch static IPs
  ENTRYPOINT_DNS_NAME=

  RECREATE_STORAGE_BUCKET=1     # Flush the ledger on restarts
  ARCHIVE_INTERVAL_MINUTES=10   # Archive faster for easier testing
fi

if [[ -n $PRODUCTION ]]; then
  echo "!!!!!!!!!!!!!! PRODUCTION !!!!!!!!!!!!!!"
  sleep 2
fi
