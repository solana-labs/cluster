# source this file

#RELEASE_CHANNEL_OR_TAG=1.0.5
RELEASE_CHANNEL_OR_TAG=beta

REGION=us-west1
ZONE=${REGION}-b

case $CLUSTER in
devnet)
  echo "### Devnet Cluster ###"
  PROJECT="solana-devnet"
  API_ADDRESS_NAME=devnet-solana-com
  API_DNS_NAME=devnet.solana.com
  FAUCET_KEYPAIR=1
  FAUCET_RPC=1
  OPERATING_MODE=development
  WAREHOUSE_NODE=1
  [[ -z $PRODUCTION ]] || SOLANA_METRICS_CONFIG="host=https://metrics.solana.com:8086,db=devnet,u=scratch_writer,p=topsecret"
  ;;
mainnet-beta)
  echo "### Mainnet Beta Cluster ###"
  PROJECT="mainnet-beta"
  API_ADDRESS_NAME=api-mainnet-beta-solana-com
  API_DNS_NAME=api.mainnet-beta.solana.com
  BOOTSTRAP_STAKE_AUTHORIZED_PUBKEY=3b7akieYUyCgz3Cwt5sTSErMWjg8NEygD6mbGjhGkduB # "one thanks" catch-all community pool
  ENTRYPOINT_ADDRESS_NAME=mainnet-beta-solana-com
  ENTRYPOINT_DNS_NAME=mainnet-beta.solana.com
  FAUCET_KEYPAIR=
  FAUCET_RPC=
  OPERATING_MODE=stable
  WAREHOUSE_NODE=1
  CREATION_TIME="2020-03-16T07:29:00-07:00"
  [[ -z $PRODUCTION ]] || SOLANA_METRICS_CONFIG="host=https://metrics.solana.com:8086,db=mainnet-beta,u=mainnet-beta_write,p=password"
  ;;
slp)
  echo "### SLP Cluster ###"
  PROJECT="solana-mainnet"
  API_ADDRESS_NAME=api-mainnet-solana-com
  BOOTSTRAP_STAKE_AUTHORIZED_PUBKEY=3b7akieYUyCgz3Cwt5sTSErMWjg8NEygD6mbGjhGkduB # "one thanks" catch-all community pool
  ENTRYPOINT_ADDRESS_NAME=mainnet-solana-com
  EXTERNAL_ACCOUNTS_FILE=slp-validator-identity-accounts.yml
  FAUCET_KEYPAIR=
  FAUCET_RPC=
  OPERATING_MODE=stable
  WAREHOUSE_NODE=1
  [[ -z $PRODUCTION ]] || SOLANA_METRICS_CONFIG="host=https://metrics.solana.com:8086,db=cluster,u=cluster_write,p=slp2"
  # Tell `solana-watchtower` to notify the #slp1-validators Discord channel on a sanity failure
  # DISCORD_WEBHOOK=https://discordapp.com/api/webhooks/654940298375462932/KlprfdAahVxwyHptYsN9Lbitb8-kzRU4wOJ3e3QVndhzdwu28YbVtzRlb_BIZZA7c3ec
  ;;
tour-de-sol)
  echo "### TdS ###"
  PROJECT="tour-de-sol"
  API_DNS_NAME=tds.solana.com
  API_ADDRESS_NAME=tds-solana-com
  BOOTSTRAP_STAKE_AUTHORIZED_PUBKEY=
  ENTRYPOINT_DNS_NAME=
  EXTERNAL_ACCOUNTS_FILE_URL=https://raw.githubusercontent.com/solana-labs/tour-de-sol/master/validators/all-pubkey.yml
  FAUCET_KEYPAIR=1
  FAUCET_RPC=
  OPERATING_MODE=preview
  WAREHOUSE_NODE=
  [[ -z $PRODUCTION ]] || SOLANA_METRICS_CONFIG="host=https://metrics.solana.com:8086,db=tds,u=testnet_write,p=c4fa841aa918bf8274e3e2a44d77568d9861b3ea"
  ;;
*)
  echo "Error: unsupported CLUSTER='$CLUSTER'. Try 'slp' or 'tour-de-sol'"
  exit 1
esac

STORAGE_BUCKET="${PROJECT}-ledger"
INSTANCE_PREFIX=
ARCHIVE_INTERVAL_MINUTES=720 # 12 hours

if [[ -z $PRODUCTION ]]; then
  INSTANCE_PREFIX="`whoami`-${PROJECT}-"
  STORAGE_BUCKET="`whoami`-$STORAGE_BUCKET"
  PROJECT=principal-lane-200702 # Jump to common development project

  API_DNS_NAME=                 # Ditch static IPs
  API_ADDRESS_NAME=
  ENTRYPOINT_DNS_NAME=
  ENTRYPOINT_ADDRESS_NAME=

  RECREATE_STORAGE_BUCKET=1     # Flush the ledger on restarts
  ARCHIVE_INTERVAL_MINUTES=10   # Archive faster for easier testing
fi

if [[ -n $PRODUCTION ]]; then
  echo "!!!!!!!!!!!!!! PRODUCTION !!!!!!!!!!!!!!"
  sleep 2
fi
