#!/usr/bin/env bash
set -ex
shopt -s nullglob

#shellcheck source=/dev/null
source ~/service-env.sh

~/bin/check-hostname.sh

# Delete any zero-length snapshots that can cause validator startup to fail
find ~/ledger/ -name 'snapshot-*' -size 0 -print -exec rm {} \; || true

#shellcheck source=/dev/null
source ~/service-env-validator-*.sh

identity_keypair=~/validator-identity-"$ZONE".json
identity_pubkey=$(solana-keygen pubkey "$identity_keypair")

ledger_dir=~/ledger
args=(
  --dynamic-port-range 8002-8012
  --gossip-port 8001
  --identity "$identity_keypair"
  --ledger "$ledger_dir"
  --limit-ledger-size
  --log ~/solana-validator.log
  --rpc-port 8899
  --vote-account ~/validator-vote-account-"$ZONE".json
  --expected-genesis-hash "$EXPECTED_GENESIS_HASH"
  --no-port-check
  --wal-recovery-mode skip_any_corrupted_record
)
args+=(--bpf-jit)

if [[ -n $PUBLIC_RPC_ADDRESS ]]; then
  args+=(--public-rpc-address "$PUBLIC_RPC_ADDRESS")
fi

for av in ~/validator-authorized-voter*.json; do
  args+=(--authorized-voter "$av")
done

for hard_fork in "${HARD_FORKS[@]}"; do
  args+=(--hard-fork "$hard_fork")
done

trusted_validator_args=()
for tv in "${TRUSTED_VALIDATOR_PUBKEYS[@]}"; do
  [[ $tv = "$identity_pubkey" ]] || args+=(--trusted-validator "$tv")
done

if [[ ${#trusted_validator_args[@]} -gt 0 ]]; then
  args+=(--halt-on-trusted-validators-accounts-hash-mismatch)
  args+=(--no-untrusted-rpc)
fi

if [[ -r ~/frozen-accounts ]]; then
  #
  # The frozen-accounts file should be formatted as:
  #   FROZEN_ACCOUNT_PUBKEYS=()
  #   FROZEN_ACCOUNT_PUBKEYS+=(PUBKEY1)
  #   FROZEN_ACCOUNT_PUBKEYS+=(PUBKEY2)
  #

  #shellcheck source=/dev/null
  . ~/frozen-accounts
  for tv in "${FROZEN_ACCOUNT_PUBKEYS[@]}"; do
    args+=(--frozen-account "$tv")
  done
fi

if [[ -n $EXPECTED_SHRED_VERSION ]]; then
  args+=(--expected-shred-version "$EXPECTED_SHRED_VERSION")
fi

if [[ -n $SNAPSHOT_COMPRESSION ]]; then
  args+=(--snapshot-compression "$SNAPSHOT_COMPRESSION")
fi

if [[ -n $EXPECTED_BANK_HASH ]]; then
  args+=(--expected-bank-hash "$EXPECTED_BANK_HASH")
  if [[ -n $WAIT_FOR_SUPERMAJORITY ]]; then
    args+=(--wait-for-supermajority "$WAIT_FOR_SUPERMAJORITY")
  fi
elif [[ -n $WAIT_FOR_SUPERMAJORITY ]]; then
  echo "WAIT_FOR_SUPERMAJORITY requires EXPECTED_BANK_HASH be specified as well!" 1>&2
  exit 1
fi

if [[ -n $GOSSIP_HOST ]]; then
  args+=(--gossip-host "$GOSSIP_HOST")
else
  args+=(--entrypoint "$ENTRYPOINT")
  args+=(--no-snapshot-fetch --no-genesis-fetch)
fi

if [[ -w /mnt/solana-accounts/ ]]; then
  args+=(--accounts /mnt/solana-accounts)
fi

exec solana-validator "${args[@]}"
