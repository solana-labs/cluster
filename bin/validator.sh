#!/usr/bin/env bash
set -ex
shopt -s nullglob

#shellcheck source=/dev/null
source ~/service-env.sh

~/bin/check-hostname.sh

# Delete any zero-length snapshots that can cause validator startup to fail
find /home/sol/ledger -name 'snapshot-*' -size 0 -print -exec rm {} \; || true

identity_keypair=/home/sol/identity/internal-rpc-am6-1-identity.json
identity_pubkey=$(solana-keygen pubkey "$identity_keypair")

ledger_dir=/home/sol/ledger
args=(
  --dynamic-port-range 8002-8015
  --gossip-port 8001
  --identity "$identity_keypair"
  --ledger "$ledger_dir"
  --limit-ledger-size
  --log /home/sol/logs/solana-validator.log
  --rpc-port 8899
  --expected-genesis-hash "$EXPECTED_GENESIS_HASH"
  --wal-recovery-mode skip_any_corrupted_record
)

if [[ -n $PUBLIC_RPC_ADDRESS ]]; then
  args+=(--public-rpc-address "$PUBLIC_RPC_ADDRESS")
fi

if [[ -f /home/sol/identity-vote-account.json ]]; then
  args+=(--vote-account /home/sol/identity-vote-account.json)
else
  args+=(--no-voting)
fi

if [[ -f /home/sol/identity-authorized-voter.json ]]; then
  args+=(--authorized-voter /home/sol/identity-authorized-voter.json)
fi

trusted_validators=
for tv in "${TRUSTED_VALIDATOR_PUBKEYS[@]}"; do
  if [[ $tv != "$identity_pubkey" ]]; then
    args+=(--trusted-validator "$tv")
    trusted_validators=1
  fi
done

if [[ -n $trusted_validators ]]; then
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

if [[ $RESTART = true ]]; then
  args+=(--expected-bank-hash "$EXPECTED_BANK_HASH")
  args+=(--wait-for-supermajority "$WAIT_FOR_SUPERMAJORITY")
  args+=(--hard-fork "$hard_fork")
fi

if [[ -n $GOSSIP_HOST ]]; then
  args+=(--gossip-host "$GOSSIP_HOST")
else
  if [[ -n "$ENTRYPOINT" ]]; then
    args+=(--entrypoint "$ENTRYPOINT")
  fi

  if ! solana --version | ag '1\.4'; then
    for entrypoint in "${ENTRYPOINTS[@]}"; do
      args+=(--entrypoint "$entrypoint")
    done
  fi
fi

if [[ -d "$ledger_dir" ]]; then
  args+=(--no-genesis-fetch)
  args+=(--no-snapshot-fetch)
fi

if [[ -w /mnt/accounts ]]; then
  args+=(--accounts /mnt/accounts)
fi

if ! [[ $(solana --version) =~ \ 1\.4\.[0-9]+ ]]; then
  if [[ $ENABLE_BPF_JIT = true ]]; then
    args+=(--bpf-jit)
  fi
  if [[ $DISABLE_ACCOUNTSDB_CACHE = true ]]; then
    args+=(--no-accounts-db-caching)
  fi
  if [[ $ENABLE_CPI_AND_LOG_STORAGE = true ]]; then
    args+=(--enable-cpi-and-log-storage)
  fi
  for entrypoint in "${ENTRYPOINTS[@]}"; do
    args+=(--entrypoint "$entrypoint")
  done
fi

exec solana-validator "${args[@]}"
