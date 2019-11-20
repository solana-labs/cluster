#!/usr/bin/env bash
#
# Creates and configures the GCE machines used for mainnet.
#
# By default development machines will be created under your username.  To
# deploy the real machines set the PRODUCTION environment variable.
#
set -e

cd "$(dirname "$0")"

INSTANCE_PREFIX=
PROJECT=solana-mainnet
ZONE=us-west1-b

if [[ -z $PRODUCTION ]]; then
  INSTANCE_PREFIX="$(whoami)-test-"
  PROJECT=principal-lane-200702
fi

ENTRYPOINT_INSTANCE=${INSTANCE_PREFIX}entrypoint-mainnet-solana-com
BOOTSTRAP_LEADER_INSTANCE=${INSTANCE_PREFIX}bootstrap-leader-mainnet-solana-com
API_INSTANCE=${INSTANCE_PREFIX}api-mainnet-solana-com

INSTANCES="$ENTRYPOINT_INSTANCE $BOOTSTRAP_LEADER_INSTANCE $API_INSTANCE"

if [[ $(basename "$0" .sh) = delete-mainnet ]]; then
  (
    set -x
    gcloud --project $PROJECT compute instances delete $INSTANCES --zone $ZONE
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
  status=$(gcloud --project $PROJECT compute instances list --filter name="$instance" --format 'value(status)')
  if [[ -n $status ]]; then
    echo "Error: $instance already exists (status=$status)"
    exit 1
  fi
done

echo ==========================================================
echo "Creating $ENTRYPOINT_INSTANCE"
echo ==========================================================
(
  set -x
  gcloud --project $PROJECT compute instances create \
    "$ENTRYPOINT_INSTANCE" \
    --zone $ZONE \
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
  gcloud --project $PROJECT compute instances create \
    "$API_INSTANCE" \
    --zone $ZONE \
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
  gcloud --project $PROJECT compute instances create \
    "$BOOTSTRAP_LEADER_INSTANCE" \
    --zone $ZONE \
    --machine-type n1-standard-8 \
    --boot-disk-size=2TB \
    --tags solana-validator-minimal,solana-validator-rpc \
    --image ubuntu-minimal-1804-bionic-v20191113 --image-project ubuntu-os-cloud
)

ENTRYPOINT=mainnet.solana.com
RPC=api.mainnet.solana.com

if [[ -n $INSTANCE_PREFIX ]]; then
  ENTRYPOINT=$(gcloud --project $PROJECT compute instances list \
      --filter name="$ENTRYPOINT_INSTANCE" --format 'value(networkInterfaces[0].accessConfigs[0].natIP)')
  RPC=$(gcloud --project $PROJECT compute instances list \
      --filter name="$API_INSTANCE" --format 'value(networkInterfaces[0].accessConfigs[0].natIP)')
fi
echo "ENTRYPOINT=$ENTRYPOINT" >> service-env.sh
RPC_URL="http://$RPC:8899/"

echo ==========================================================
echo Waiting for instances to boot
echo ==========================================================
for instance in ${INSTANCES[@]}; do
  while ! gcloud --project $PROJECT compute ssh "$instance" -- true; do
    echo "Waiting for \"$instance\" to boot"
    sleep 5s
  done
done

echo ==========================================================
echo "Transferring files to $ENTRYPOINT_INSTANCE"
echo ==========================================================
(
  gcloud --project $PROJECT compute scp --recurse \
    remote-machine-setup.sh \
    service-env.sh \
    entrypoint.service \
    "$ENTRYPOINT_INSTANCE":
)

echo ==========================================================
echo "Transferring files to $BOOTSTRAP_LEADER_INSTANCE"
echo ==========================================================
(
  set -x
  gcloud --project $PROJECT compute scp --recurse \
    bootstrap-leader-identity.json \
    bootstrap-leader-stake-account.json \
    bootstrap-leader-vote-account.json \
    remote-machine-setup.sh \
    ledger \
    service-env.sh \
    bootstrap-leader.service \
    "$BOOTSTRAP_LEADER_INSTANCE":
)

echo ==========================================================
echo "Transferring files to $API_INSTANCE"
echo ==========================================================
(
  set -x
  gcloud --project $PROJECT compute scp --recurse \
    remote-machine-setup.sh \
    ledger \
    service-env.sh \
    api.service \
    "$API_INSTANCE":
)

for instance in $INSTANCES; do
  echo ==========================================================
  echo "Configuring $instance"
  echo ==========================================================
  (
    set -x
    gcloud --project $PROJECT compute ssh "$instance" -- bash remote-machine-setup.sh
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
