#!/usr/bin/env bash
#
# Creates and configures the GCE machines used for a cluster.
#
set -e

cd "$(dirname "$0")"
source env.sh

usage() {
  exitcode=0
  if [[ -n "$1" ]]; then
    exitcode=1
    echo "Error: $*"
  fi
  cat <<EOF
usage: $0 [options]

Launch a cluster
   --release RELEASE_CHANNEL_OR_TAG    - Which release channel or tag to deploy (default: $RELEASE_CHANNEL_OR_TAG).

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

ENTRYPOINT_INSTANCE=${INSTANCE_PREFIX}entrypoint
BOOTSTRAP_VALIDATOR_INSTANCE=${INSTANCE_PREFIX}bootstrap-validator
API_INSTANCE=${INSTANCE_PREFIX}api
WAREHOUSE_INSTANCE=${INSTANCE_PREFIX}warehouse
WATCHTOWER_INSTANCE=${INSTANCE_PREFIX}watchtower

INSTANCES="
  $ENTRYPOINT_INSTANCE
  $BOOTSTRAP_VALIDATOR_INSTANCE
  $API_INSTANCE
  $WAREHOUSE_INSTANCE
  $WATCHTOWER_INSTANCE
"

LETSENCRYPT_TGZ=
if [[ -n $API_DNS_NAME ]]; then
  LETSENCRYPT_TGZ="letsencrypt-$API_DNS_NAME.tgz"
fi

if [[ $(basename "$0" .sh) = delete-cluster ]]; then
  if [[ -n $API_DNS_NAME ]]; then
    echo "Attempting to recover TLS certificate before deleting instances"
    (
      set -x
      gcloud --project "$PROJECT" compute scp --zone "$ZONE" "$API_INSTANCE":/letsencrypt.tgz "$LETSENCRYPT_TGZ"
    ) || true
    if [[ -f "$LETSENCRYPT_TGZ" ]]; then
      echo "Warning: ensure you don't delete $LETSENCRYPT_TGZ"
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

if [[ ! -d "$CLUSTER"/ledger ]]; then
  echo "Error: "$CLUSTER"/ledger/ directory does not exist"
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

GENESIS_HASH="$(RUST_LOG=none solana-ledger-tool genesis-hash --ledger "$CLUSTER"/ledger)"
SHRED_VERSION="$(RUST_LOG=none solana-ledger-tool shred-version --ledger "$CLUSTER"/ledger)"

if [[ -z $SOLANA_METRICS_CONFIG ]]; then
  echo Note: SOLANA_METRICS_CONFIG is not configured
fi

if [[ -n $RECREATE_STORAGE_BUCKET ]]; then
  # Re-create the dev bucket on each launch
  gsutil rm -r gs://"$STORAGE_BUCKET" || true
  gsutil mb -p "$PROJECT" -l "$REGION" -b on gs://"$STORAGE_BUCKET"
else
  # Create the production bucket if it doesn't already exist but do not remove old
  # data, if any, to avoid accidental data loss.
  gsutil mb -p "$PROJECT" -l "$REGION" -b on gs://"$STORAGE_BUCKET" || true
fi

(
  set -x
  gsutil -m cp -r "$CLUSTER"/ledger/genesis.tar.bz2 gs://"$STORAGE_BUCKET"
)

(
  echo EXPECTED_GENESIS_HASH="$GENESIS_HASH"
  echo EXPECTED_SHRED_VERSION="$SHRED_VERSION"
  if [[ -n $SOLANA_METRICS_CONFIG ]]; then
    echo SOLANA_METRICS_CONFIG="$SOLANA_METRICS_CONFIG"
  fi
  echo STORAGE_BUCKET="$STORAGE_BUCKET"
  echo PATH=/home/solanad/.local/share/solana/install/active_release/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin
  echo ARCHIVE_INTERVAL_MINUTES="$ARCHIVE_INTERVAL_MINUTES"
  echo DISCORD_WEBHOOK="$DISCORD_WEBHOOK"
) | tee "$CLUSTER"/service-env.sh

echo ==========================================================
echo "Creating $ENTRYPOINT_INSTANCE"
echo ==========================================================
(
  maybe_address=
  if [[ -n $ENTRYPOINT_DNS_NAME ]]; then
    maybe_address="--address $(echo $ENTRYPOINT_DNS_NAME | tr . -)"
  fi

  set -x
  gcloud --project "$PROJECT" compute instances create \
    "$ENTRYPOINT_INSTANCE" \
    --zone "$ZONE" \
    --machine-type n1-standard-1 \
    --boot-disk-size=200GB \
    --tags solana-validator-minimal \
    --image ubuntu-minimal-1804-bionic-v20191113 --image-project ubuntu-os-cloud \
    --min-cpu-platform "Intel Skylake" \
    ${maybe_address}
)

echo ==========================================================
echo "Creating $API_INSTANCE"
echo ==========================================================
(
  maybe_address=
  if [[ -n $API_DNS_NAME ]]; then
    maybe_address="--address $(echo $API_DNS_NAME | tr . -)"
  fi

  set -x
  gcloud --project "$PROJECT" compute instances create \
    "$API_INSTANCE" \
    --zone "$ZONE" \
    --machine-type n1-standard-8 \
    --boot-disk-size=2TB \
    --tags solana-validator-minimal,solana-validator-rpc \
    --image ubuntu-minimal-1804-bionic-v20191113 --image-project ubuntu-os-cloud \
    --min-cpu-platform "Intel Skylake" \
    ${maybe_address}
)

echo ==========================================================
echo "Creating $BOOTSTRAP_VALIDATOR_INSTANCE"
echo ==========================================================
(
  set -x
  gcloud --project "$PROJECT" compute instances create \
    "$BOOTSTRAP_VALIDATOR_INSTANCE" \
    --zone "$ZONE" \
    --machine-type n1-standard-8 \
    --boot-disk-size=2TB \
    --tags solana-validator-minimal,solana-validator-rpc \
    --image ubuntu-minimal-1804-bionic-v20191113 --image-project ubuntu-os-cloud \
    --min-cpu-platform "Intel Skylake" \

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
    --min-cpu-platform "Intel Skylake" \
    --scopes=storage-rw \

)

echo ==========================================================
echo "Creating $WATCHTOWER_INSTANCE"
echo ==========================================================
(
  set -x
  gcloud --project "$PROJECT" compute instances create \
    "$WATCHTOWER_INSTANCE" \
    --zone "$ZONE" \
    --machine-type n1-standard-1 \
    --boot-disk-size=200GB \
    --tags solana-validator-minimal \
    --image ubuntu-minimal-1804-bionic-v20191113 --image-project ubuntu-os-cloud \
    --min-cpu-platform "Intel Skylake" \

)

ENTRYPOINT_HOST=$ENTRYPOINT_DNS_NAME
ENTRYPOINT_PORT=8001
RPC=$API_DNS_NAME
if [[ -z $ENTRYPOINT_HOST ]]; then
  ENTRYPOINT_HOST=$(gcloud --project "$PROJECT" compute instances list \
      --filter name="$ENTRYPOINT_INSTANCE" --format 'value(networkInterfaces[0].accessConfigs[0].natIP)')
fi
if [[ -z $RPC ]]; then
  RPC=$(gcloud --project "$PROJECT" compute instances list \
      --filter name="$API_INSTANCE" --format 'value(networkInterfaces[0].accessConfigs[0].natIP)')
fi
RPC_URL="http://$RPC/"
ENTRYPOINT="${ENTRYPOINT_HOST}:${ENTRYPOINT_PORT}"

cat >> "$CLUSTER"/service-env.sh <<EOF
RPC_URL=$RPC_URL
ENTRYPOINT_HOST=$ENTRYPOINT_HOST
ENTRYPOINT_PORT=$ENTRYPOINT_PORT
ENTRYPOINT=$ENTRYPOINT
EOF

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
    "$CLUSTER"/service-env.sh \
    scripts/* \
    entrypoint.service \
    "$ENTRYPOINT_INSTANCE":
)

echo ==========================================================
echo "Transferring files to $BOOTSTRAP_VALIDATOR_INSTANCE"
echo ==========================================================
(
  set -x
  gcloud --project "$PROJECT" compute scp --zone "$ZONE" --recurse \
    "$CLUSTER"/bootstrap-validator-identity.json \
    "$CLUSTER"/bootstrap-validator-stake-account.json \
    "$CLUSTER"/bootstrap-validator-vote-account.json \
    "$CLUSTER"/service-env.sh \
    "$CLUSTER"/ledger \
    scripts/* \
    bootstrap-validator.service \
    "$BOOTSTRAP_VALIDATOR_INSTANCE":
)

echo ==========================================================
echo "Transferring files to $WAREHOUSE_INSTANCE"
echo ==========================================================
(
  set -x
  gcloud --project "$PROJECT" compute scp --zone "$ZONE" --recurse \
    "$CLUSTER"/ledger \
    "$CLUSTER"/service-env.sh \
    scripts/* \
    warehouse.service \
    "$WAREHOUSE_INSTANCE":
)

echo ==========================================================
echo "Transferring files to $WATCHTOWER_INSTANCE"
echo ==========================================================
(
  gcloud --project "$PROJECT" compute scp --zone "$ZONE" --recurse \
    "$CLUSTER"/service-env.sh \
    scripts/* \
    watchtower.service \
    "$WATCHTOWER_INSTANCE":
)

echo ==========================================================
echo "Transferring files to $API_INSTANCE"
echo ==========================================================
(
  set -x
  gcloud --project "$PROJECT" compute scp --zone "$ZONE" --recurse \
    api.service \
    "$CLUSTER"/api-identity.json \
    "$CLUSTER"/ledger \
    "$CLUSTER"/service-env.sh \
    scripts/* \
    "$API_INSTANCE":
)

if [[ -n $LETSENCRYPT_TGZ ]] && [[ -f $LETSENCRYPT_TGZ ]]; then
  (
    set -x
    gcloud --project "$PROJECT" compute scp --zone "$ZONE" "$LETSENCRYPT_TGZ" "$API_INSTANCE":~/letsencrypt.tgz
    gcloud --project "$PROJECT" compute ssh --zone "$ZONE" "$API_INSTANCE" -- sudo mv letsencrypt.tgz /
  )
fi


for instance in $INSTANCES; do
  echo ==========================================================
  echo "Configuring $instance"
  echo ==========================================================
  (
    nodeType=
    dnsName=
    case $instance in
    $API_INSTANCE)
      nodeType=api
      dnsName="$API_DNS_NAME"
      ;;
    $WAREHOUSE_INSTANCE)
      nodeType=warehouse
      ;;
    $WATCHTOWER_INSTANCE)
      nodeType=watchtower
      ;;
    $ENTRYPOINT_INSTANCE)
      nodeType=entrypoint
      ;;
    $BOOTSTRAP_VALIDATOR_INSTANCE)
      nodeType=bootstrap
      ;;
    *)
      echo "Error: Unknown instance type: $instance"
      exit 1
      ;;
    esac

    set -x
    gcloud --project "$PROJECT" compute ssh --zone "$ZONE" "$instance" -- \
      bash remote-machine-setup.sh "$RELEASE_CHANNEL_OR_TAG" "$nodeType" "$dnsName"
  )
done

echo ==========================================================
(
  set -x
  solana-gossip spy --entrypoint "$ENTRYPOINT" --timeout 10
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

(
  echo === Foundation Stake Accounts ===
  ./get_accounts_from_seed.sh "$RPC_URL" GRZwoJGisLTszcxtWpeREJ98EGg8pZewhbtcrikoU7b3 --display_summary
  ./get_accounts_from_seed.sh "$RPC_URL" J51tinoLdmEdUR27LUVymrb2LB3xQo1aSHSgmbSGdj58 --display_summary

  echo === Grant Stake Accounts ===
  ./get_accounts_from_seed.sh "$RPC_URL" DNaKiBwwbbqk1wVoC5AQxWQbuDhvaDVbAtXzsVos9mrc --display_summary
  ./get_accounts_from_seed.sh "$RPC_URL" HvXQPXAijjG1vnQs6HXVtUUtFVzi5HNgXV9LGnHvYF85 --display_summary

  echo === Community Stake Accounts ===
  ./get_accounts_from_seed.sh "$RPC_URL" BzuqQFnu7oNUeok9ZoJezpqu2vZJU7XR1PxVLkk6wwUD --display_summary
  ./get_accounts_from_seed.sh "$RPC_URL" FwMbkDZUb78aiMWhZY4BEroAcqmnrXZV77nwrg71C57d --display_summary
  ./get_accounts_from_seed.sh "$RPC_URL" 4h1rt2ic4AXwG7p3Qqhw57EMDD4c3tLYb5J3QstGA2p5 --display_summary
  ./get_accounts_from_seed.sh "$RPC_URL" 3b7akieYUyCgz3Cwt5sTSErMWjg8NEygD6mbGjhGkduB --display_summary

  echo === External Stake Accounts ===
  ./get_accounts_from_seed.sh "$RPC_URL" CDtJpwRSiPRDGeKrvymWQKM7JY9M3hU7iimEKBDxZyoP --display_summary
  ./get_accounts_from_seed.sh "$RPC_URL" HbENu65qjWLEB5TrMouSSWLq9mbtGx2bvfhPjk2FpYek --display_summary
  ./get_accounts_from_seed.sh "$RPC_URL" C9CfFpmLDsQsz6wt7MrrZquNB5oS4QkpJkmDAiboVEZZ --display_summary
  ./get_accounts_from_seed.sh "$RPC_URL" 6ne6Rbag4FAnop1KNgVdM1SEHnJEysHSWyqvRpFrzaig --display_summary
  ./get_accounts_from_seed.sh "$RPC_URL" 42yapY7Vrs5jqht9TCKZsPoyb4vDFYcPfRkqAP85NSAQ --display_summary
  ./get_accounts_from_seed.sh "$RPC_URL" GTyawCMwt3kMb51AgDtfdp97mDot7jNwc8ifuS9qqANg --display_summary
  ./get_accounts_from_seed.sh "$RPC_URL" Fqxs9MhqjKuMq6YwjBG4ktEapuZQ3kj19mpuHLZKtkg9 --display_summary
  ./get_accounts_from_seed.sh "$RPC_URL" 9MYDzj7QuAX9QAK7da1GhzPB4gA3qbPNWsW3MMSZobru --display_summary
  ./get_accounts_from_seed.sh "$RPC_URL" E4DLNkmdL34ejA48ApfPDoFVuD9XWAFqi8bXzBGRhKst --display_summary
  ./get_accounts_from_seed.sh "$RPC_URL" 8cV7zCTF5UMrZakZXiL2Jw5uY3ms2Wz4twzFXEY9Kge2 --display_summary
  ./get_accounts_from_seed.sh "$RPC_URL" JBGnGdLyo7V2z9hz51mnnbyDp9sBACtw5WYH9YRG8n7e --display_summary
  ./get_accounts_from_seed.sh "$RPC_URL" CqKdQ57mBj2mKcAbpjWc28Ls7yXzBXboxSTCRWocmUVj --display_summary
  ./get_accounts_from_seed.sh "$RPC_URL" 2SCJKvh7wWo32PtfUZdVZQ84WnMWoUpF4WTm6ZxcCJ15 --display_summary
  ./get_accounts_from_seed.sh "$RPC_URL" FeumxB3gfzrVQzABBiha8AacKPY3Rf4BTFSh2aZWHqR8 --display_summary
  ./get_accounts_from_seed.sh "$RPC_URL" HBwFWNGPVZgkf3yqUKxuAds5aANGWX62LzUFvZVCWLdJ --display_summary
  ./get_accounts_from_seed.sh "$RPC_URL" 3JMz3kaDUZEVK2JVjRqwERGMp7LbWbgUjAFBb42qxoHb --display_summary
  ./get_accounts_from_seed.sh "$RPC_URL" XTeBBZextvHkoRqDF8yb4hihjcraKQDwTEXhzjd8fip --display_summary
  ./get_accounts_from_seed.sh "$RPC_URL" E5bSU5ywqPiz3ije89ef5gaEC7jy81BAc72Zeb9MqeHY --display_summary
  ./get_accounts_from_seed.sh "$RPC_URL" 4ZemkSoE75RFE1SVLnnmHcaNWT4qN8KFrKP2wAYfv8CB --display_summary
  ./get_accounts_from_seed.sh "$RPC_URL" 72BGEwYee5txFonmpEarTEKCZVN2UxcSUgdphdhcx3V --display_summary
  ./get_accounts_from_seed.sh "$RPC_URL" DRp1Scyn4yJZQfMAdQew2x8RtvRmsNELN37JTK5Xvzgn --display_summary
) | tee accounts_owned_by.txt

(
  set -x
  gsutil -m cp accounts_owned_by* gs://"$STORAGE_BUCKET"
)

echo ==========================================================
echo Success
exit 0
