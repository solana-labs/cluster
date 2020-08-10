# source this file

#RELEASE_CHANNEL_OR_TAG=1.0.7
RELEASE_CHANNEL_OR_TAG=stable

REGION=us-west1
DEFAULT_ZONE=us-west1-b

case $CLUSTER in
devnet)
  echo "### Devnet Cluster ###"
  PROJECT="solana-devnet"
  API_ADDRESS_NAME=api #devnet-solana-com
  API_DNS_NAME=devnet.solana.com
  FAUCET_KEYPAIR=1
  FAUCET_RPC=1
  OPERATING_MODE=development
  VALIDATOR_ZONES=($DEFAULT_ZONE)
  WAREHOUSE_ZONES=($DEFAULT_ZONE)
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
  CREATION_TIME="2020-03-16T07:29:00-07:00"
  VALIDATOR_ZONES=($DEFAULT_ZONE us-east1-b europe-west4-c asia-northeast3-a)
  WAREHOUSE_ZONES=($DEFAULT_ZONE europe-west4-c)
  [[ -z $PRODUCTION ]] || SOLANA_METRICS_CONFIG="host=https://metrics.solana.com:8086,db=mainnet-beta,u=mainnet-beta_write,p=password"
  ;;
testnet)
  echo "### Testnet ###"
  PROJECT="tour-de-sol"
  API_DNS_NAME=testnet.solana.com
  API_ADDRESS_NAME=tds-solana-com
  BOOTSTRAP_STAKE_AUTHORIZED_PUBKEY=
  ENTRYPOINT_DNS_NAME=
  ENTRYPOINT_ADDRESS_NAME=entrypoint
  EXTERNAL_ACCOUNTS_FILE_URL=https://raw.githubusercontent.com/solana-labs/tour-de-sol/master/validators/all-pubkey.yml
  FAUCET_KEYPAIR=1
  FAUCET_RPC=
  OPERATING_MODE=preview
  VALIDATOR_ZONES=($DEFAULT_ZONE)
  WAREHOUSE_ZONES=($DEFAULT_ZONE)
  [[ -z $PRODUCTION ]] || SOLANA_METRICS_CONFIG="host=https://metrics.solana.com:8086,db=tds,u=testnet_write,p=c4fa841aa918bf8274e3e2a44d77568d9861b3ea"
  ;;
*)
  echo "Error: unsupported CLUSTER='$CLUSTER'. Try 'devnet', 'testnet' or 'mainnet-beta'"
  exit 1
  ;;
esac

STORAGE_BUCKET_PREFIX="${PROJECT}-ledger"
INSTANCE_PREFIX=
if [[ -z $PRODUCTION ]]; then
  INSTANCE_PREFIX="$(whoami)-${PROJECT}-"
  STORAGE_BUCKET_PREFIX="$(whoami)-$STORAGE_BUCKET_PREFIX"

  PROJECT=principal-lane-200702 # Jump to common development project,

  API_DNS_NAME=                 # Ditch static IPs
  API_ADDRESS_NAME=
  ENTRYPOINT_DNS_NAME=
  ENTRYPOINT_ADDRESS_NAME=

  RECREATE_STORAGE_BUCKET=1     # Flush the ledger on restarts
else
  echo "!!!!!!!!!!!!!! PRODUCTION !!!!!!!!!!!!!!"
  sleep 2
fi

