#!/usr/bin/env bash
set -ex

#shellcheck source=/dev/null
. ~/service-env.sh

~/bin/check-hostname.sh

if [[ -n $SOLANA_INSTALL_UPDATE_MANIFEST ]]; then
  while ! solana-install init --url "$RPC_URL" --pubkey "$SOLANA_INSTALL_UPDATE_MANIFEST"; do
    sleep 2
  done
fi

identity_keypair=~/api-identity.json
identity_pubkey=$(solana-keygen pubkey $identity_keypair)
ledger_dir=~/ledger

# Delete any zero-length snapshots that can cause validator startup to fail
find "$ledger_dir" -name 'snapshot-*' -size 0 -print -exec rm {} \; || true


args=(
  --gossip-port 8001
  --dynamic-port-range 8002-8012
  --entrypoint "${ENTRYPOINT}"
  --ledger "$ledger_dir"
  --identity "$identity_keypair"
  --limit-ledger-size
  --log ~/solana-validator.log
  --rpc-port 8899
  --enable-rpc-transaction-history
  --expected-genesis-hash "$EXPECTED_GENESIS_HASH"
  --no-port-check
  --no-untrusted-rpc
  --wal-recovery-mode skip_any_corrupted_record
  --skip-poh-verify
)
args+=(--bpf-jit)

for tv in "${TRUSTED_VALIDATOR_PUBKEYS[@]}"; do
  [[ $tv = "$identity_pubkey" ]] || args+=(--trusted-validator "$tv")
done

if [[ -f ~/faucet.json ]]; then
  args+=(--rpc-faucet-address 127.0.0.1:9900)
fi

if [[ -n $SNAPSHOT_COMPRESSION ]]; then
  args+=(--snapshot-compression "$SNAPSHOT_COMPRESSION")
fi

if [[ -n $PUBLIC_RPC_ADDRESS ]]; then
  args+=(--public-rpc-address "$PUBLIC_RPC_ADDRESS")
fi

if [[ -n $EXPECTED_SHRED_VERSION ]]; then
  args+=(--expected-shred-version "$EXPECTED_SHRED_VERSION")
fi

if [[ -n $GOOGLE_APPLICATION_CREDENTIALS ]]; then
  args+=(--enable-rpc-bigtable-ledger-storage)
fi


for hard_fork in "${HARD_FORKS[@]}"; do
  args+=(--hard-fork "$hard_fork")
done

if [[ -n $EXPECTED_BANK_HASH ]]; then
  args+=(--expected-bank-hash "$EXPECTED_BANK_HASH")
  if [[ -n $WAIT_FOR_SUPERMAJORITY ]]; then
    args+=(--wait-for-supermajority "$WAIT_FOR_SUPERMAJORITY")
  fi
elif [[ -n $WAIT_FOR_SUPERMAJORITY ]]; then
  echo "WAIT_FOR_SUPERMAJORITY requires EXPECTED_BANK_HASH be specified as well!" 1>&2
  exit 1
fi

if [[ -n "$RPC_HEALTH_CHECK_SLOT_DISTANCE" ]]; then
  args+=(--health-check-slot-distance "$RPC_HEALTH_CHECK_SLOT_DISTANCE")
fi

for index in "${ACCOUNT_INDEXES[@]}"; do
  args+=(--account-index "$index")
done

if [[ -n $RPC_THREADS ]]; then
  args+=(--rpc-threads "$RPC_THREADS")
fi

if [[ -r ~/api-vote-account.json ]]; then
  args+=(--vote-account ~/api-vote-account.json)
else
  args+=(--no-voting)
fi

if [[ -d "$ledger_dir"/genesis.bin ]]; then
  args+=(--no-genesis-fetch)
fi
if [[ -d "$ledger_dir"/snapshot ]]; then
  args+=(--no-snapshot-fetch)
fi

if [[ -w /mnt/solana-accounts/ ]]; then
  args+=(--accounts /mnt/solana-accounts)
fi

exec solana-validator "${args[@]}"
