#!/usr/bin/env bash
#
# Creates and configures the GCE machines used for a cluster.
#
# By default development machines will be created under your username.  To
# deploy the real machines set the PRODUCTION environment variable.
#
set -e

cd "$(dirname "$0")"
source env.sh

#RELEASE_CHANNEL_OR_TAG=beta
RELEASE_CHANNEL_OR_TAG=0.21.2

usage() {
  exitcode=0
  if [[ -n "$1" ]]; then
    exitcode=1
    echo "Error: $*"
  fi
  cat <<EOF
usage: $0 [options]

Launch a cluster
   --release RELEASE_CHANNEL_OR_TAG          - Which release channel or tag to deploy (default: $RELEASE_CHANNEL_OR_TAG).

EOF
  exit $exitcode
}

while [[ -n $1 ]]; do
  if [[ ${1:0:2} = -- ]]; then
    if [[ $1 = --release ]]; then
      RELEASE_CHANNEL_OR_TAG="$2"
      shift 2
    else
      usage "Unknown long option: $1"
    fi
  else
    usage "Unknown option: $1"
  fi
done

ENTRYPOINT_INSTANCE=${INSTANCE_PREFIX}cluster-entrypoint
BOOTSTRAP_LEADER_INSTANCE=${INSTANCE_PREFIX}cluster-bootstrap-leader
API_INSTANCE=${INSTANCE_PREFIX}cluster-api
WAREHOUSE_INSTANCE=${INSTANCE_PREFIX}cluster-warehouse

INSTANCES="
  $ENTRYPOINT_INSTANCE
  $BOOTSTRAP_LEADER_INSTANCE
  $API_INSTANCE
  $WAREHOUSE_INSTANCE
"

if [[ $(basename "$0" .sh) = delete-cluster ]]; then
  if [[ -n $PRODUCTION ]]; then
    echo "Attempting to recover TLS certificate before deleting instances"
    (
      set -x
      gcloud --project "$PROJECT" compute scp --zone "$ZONE" "$API_INSTANCE":/letsencrypt.tgz .
    ) || true
    if [[ -f letsencrypt.tgz ]]; then
      echo "Warning: ensure you don't delete letsencrypt.tgz"
    fi
  fi

  (
    set -x
    # shellcheck disable=SC2086 # Don't want to double quote INSTANCES
    gcloud --project "$PROJECT" compute instances delete $INSTANCES --zone "$ZONE" --quiet
  )
  exit 0
fi

(
  set -x
  solana-gossip --version
  solana --version
)

if [[ ! -d ledger ]]; then
  echo "Error: ledger/ directory does not exist"
  exit 1
fi

for instance in $INSTANCES; do
  echo "Checking that \"$instance\" does not exist"
  status=$(gcloud --project "$PROJECT" compute instances list --filter name="$instance" --format 'value(status)')
  if [[ -n $status ]]; then
    echo "Error: $instance already exists (status=$status)"
    exit 1
  fi
done

GENESIS_HASH="$(RUST_LOG=none solana-ledger-tool print-genesis-hash --ledger ledger)"

if [[ -n $PRODUCTION ]]; then
  SOLANA_METRICS_CONFIG="host=https://metrics.solana.com:8086,db=cluster,u=cluster_write,p=2aQdShmtsPSAgABLQiK2FpSCJGLtG8h3vMEVz1jE7Smf"

  # Create the production bucket if it doesn't already exist but do not remove old
  # data, if any, to avoid accidental data loss.
  gsutil mb -p "$PROJECT" -l "$REGION" -b on gs://$"STORAGE_BUCKET" || true
else
  if [[ -z $SOLANA_METRICS_CONFIG ]]; then
    echo Note: SOLANA_METRICS_CONFIG is not configured
  fi
  # Re-create the dev bucket on each launch
  gsutil rm -r gs://"$STORAGE_BUCKET" || true
  gsutil mb -p "$PROJECT" -l "$REGION" -b on gs://"$STORAGE_BUCKET"
fi

(
  set -x
  gsutil -m cp -r ledger/genesis.tar.bz2 gs://"$STORAGE_BUCKET"
)

(
  echo EXPECTED_GENESIS_HASH="$GENESIS_HASH"
  if [[ -n $SOLANA_METRICS_CONFIG ]]; then
    echo SOLANA_METRICS_CONFIG="$SOLANA_METRICS_CONFIG"
  fi
  echo STORAGE_BUCKET="$STORAGE_BUCKET"
  echo PATH=/home/solanad/.local/share/solana/install/active_release/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin
  echo PRODUCTION="$PRODUCTION"
) | tee scripts/service-env.sh


echo ==========================================================
echo "Creating $ENTRYPOINT_INSTANCE"
echo ==========================================================
(
  set -x
  gcloud --project "$PROJECT" compute instances create \
    "$ENTRYPOINT_INSTANCE" \
    --zone "$ZONE" \
    --machine-type n1-standard-1 \
    --boot-disk-size=200GB \
    --tags solana-validator-minimal \
    --image ubuntu-minimal-1804-bionic-v20191113 --image-project ubuntu-os-cloud \
    ${PRODUCTION:+ --address mainnet-solana-com}
)

echo ==========================================================
echo "Creating $API_INSTANCE"
echo ==========================================================
(
  set -x
  gcloud --project "$PROJECT" compute instances create \
    "$API_INSTANCE" \
    --zone "$ZONE" \
    --machine-type n1-standard-8 \
    --boot-disk-size=2TB \
    --tags solana-validator-minimal,solana-validator-rpc \
    --image ubuntu-minimal-1804-bionic-v20191113 --image-project ubuntu-os-cloud \
    ${PRODUCTION:+ --address api-mainnet-solana-com}
)

echo ==========================================================
echo "Creating $BOOTSTRAP_LEADER_INSTANCE"
echo ==========================================================
(
  set -x
  gcloud --project "$PROJECT" compute instances create \
    "$BOOTSTRAP_LEADER_INSTANCE" \
    --zone "$ZONE" \
    --machine-type n1-standard-8 \
    --boot-disk-size=2TB \
    --tags solana-validator-minimal,solana-validator-rpc \
    --image ubuntu-minimal-1804-bionic-v20191113 --image-project ubuntu-os-cloud
)

echo ==========================================================
echo "Creating $WAREHOUSE_INSTANCE"
echo ==========================================================
(
  set -x
  gcloud --project "$PROJECT" compute instances create \
    "$WAREHOUSE_INSTANCE" \
    --zone "$ZONE" \
    --machine-type n1-standard-8 \
    --boot-disk-size=2TB \
    --tags solana-validator-minimal,solana-validator-rpc \
    --image ubuntu-minimal-1804-bionic-v20191113 --image-project ubuntu-os-cloud \
    --scopes=storage-rw
)

#ENTRYPOINT=mainnet.solana.com
#RPC=api.mainnet.solana.com
ENTRYPOINT=34.83.130.52
RPC=34.82.79.31

if [[ -n $INSTANCE_PREFIX ]]; then
  ENTRYPOINT=$(gcloud --project "$PROJECT" compute instances list \
      --filter name="$ENTRYPOINT_INSTANCE" --format 'value(networkInterfaces[0].accessConfigs[0].natIP)')
  RPC=$(gcloud --project "$PROJECT" compute instances list \
      --filter name="$API_INSTANCE" --format 'value(networkInterfaces[0].accessConfigs[0].natIP)')
fi
RPC_URL="http://$RPC/"
echo "RPC_URL=$RPC_URL" >> scripts/service-env.sh
echo "ENTRYPOINT=$ENTRYPOINT" >> scripts/service-env.sh

echo ==========================================================
echo Waiting for instances to boot
echo ==========================================================
# shellcheck disable=SC2068 # Don't want to double quote INSTANCES
for instance in ${INSTANCES[@]}; do
  while ! gcloud --project "$PROJECT" compute ssh --zone "$ZONE" "$instance" -- true; do
    echo "Waiting for \"$instance\" to boot"
    sleep 5s
  done
done

echo ==========================================================
echo "Transferring files to $ENTRYPOINT_INSTANCE"
echo ==========================================================
(
  gcloud --project "$PROJECT" compute scp --zone "$ZONE" --recurse \
    scripts/* \
    entrypoint.service \
    "$ENTRYPOINT_INSTANCE":
)

echo ==========================================================
echo "Transferring files to $BOOTSTRAP_LEADER_INSTANCE"
echo ==========================================================
(
  set -x
  gcloud --project "$PROJECT" compute scp --zone "$ZONE" --recurse \
    bootstrap-leader-identity.json \
    bootstrap-leader-stake-account.json \
    bootstrap-leader-vote-account.json \
    bootstrap-leader.service \
    ledger \
    scripts/* \
    "$BOOTSTRAP_LEADER_INSTANCE":
)

echo ==========================================================
echo "Transferring files to $WAREHOUSE_INSTANCE"
echo ==========================================================
(
  set -x
  gcloud --project "$PROJECT" compute scp --zone "$ZONE" --recurse \
    ledger \
    scripts/* \
    warehouse.service \
    "$WAREHOUSE_INSTANCE":
)

echo ==========================================================
echo "Transferring files to $API_INSTANCE"
echo ==========================================================
(
  set -x
  gcloud --project "$PROJECT" compute scp --zone "$ZONE" --recurse \
    api.service \
    ledger \
    scripts/* \
    "$API_INSTANCE":
)
if [[ -n $PRODUCTION && -f letsencrypt.tgz ]]; then
  (
    set -x
    gcloud --project "$PROJECT" compute scp --zone "$ZONE" letsencrypt.tgz "$API_INSTANCE":~/letsencrypt.tgz
    gcloud --project "$PROJECT" compute ssh --zone "$ZONE" "$API_INSTANCE" -- sudo mv letsencrypt.tgz /
  )
fi


for instance in $INSTANCES; do
  echo ==========================================================
  echo "Configuring $instance"
  echo ==========================================================
  (
    nodeType=
    case $instance in
    $API_INSTANCE)
      nodeType=api
      ;;
    $WAREHOUSE_INSTANCE)
      nodeType=warehouse
      ;;
    $ENTRYPOINT_INSTANCE)
      nodeType=entrypoint
      ;;
    $BOOTSTRAP_LEADER_INSTANCE)
      nodeType=bootstrap
      ;;
    *)
      echo "Error: Unknown instance type: $instance"
      exit 1
      ;;
    esac

    if [[ -n $PRODUCTION ]]; then
      nodeType="${nodeType}production"
    fi

    set -x
    gcloud --project "$PROJECT" compute ssh --zone "$ZONE" "$instance" -- \
      bash remote-machine-setup.sh "$RELEASE_CHANNEL_OR_TAG" "$nodeType"
  )
done

echo ==========================================================
(
  set -x
  solana-gossip spy --entrypoint "$ENTRYPOINT":8001 --timeout 10
)
echo ==========================================================
(
  set -x
  solana --url "$RPC_URL" cluster-version
  solana --url "$RPC_URL" get-genesis-hash
  solana --url "$RPC_URL" get-epoch-info
  solana --url "$RPC_URL" show-validators
)

echo ==========================================================
echo Success
exit 0
