#!/usr/bin/env bash
set -ex
shopt -s nullglob

#shellcheck source=/dev/null
source ~/service-env.sh

#shellcheck source=/dev/null
source ~/service-env-validator-*.sh

identity_keypair=~/validator-identity-"$ZONE".json
identity_pubkey=$(solana-keygen pubkey "$identity_keypair")

authorized_voter_args=()
for av in ~/validator-authorized-voter*.json; do
  authorized_voter_args+=(--authorized-voter "$av")
done

trusted_validator_args=()
for tv in "${TRUSTED_VALIDATOR_PUBKEYS[@]}"; do
  [[ $tv = "$identity_pubkey" ]] || trusted_validator_args+=(--trusted-validator "$tv")
done

if [[ ${#trusted_validator_args[@]} -gt 0 ]]; then
  trusted_validator_args+=(--halt-on-trusted-validators-accounts-hash-mismatch)
  trusted_validator_args+=(--no-untrusted-rpc)
fi

frozen_accounts=()
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
    frozen_accounts+=(--frozen-account "$tv")
  done
fi



args=(
  --dynamic-port-range 8002-8012
  --gossip-port 8001
  --identity "$identity_keypair"
  --ledger ~/ledger
  --limit-ledger-size 250000000000
  --log ~/solana-validator.log
  --rpc-port 8899
  --private-rpc
  --vote-account ~/validator-vote-account-"$ZONE".json
  --expected-genesis-hash "$EXPECTED_GENESIS_HASH"
  --expected-shred-version "$EXPECTED_SHRED_VERSION"
  --wait-for-supermajority "$WAIT_FOR_SUPERMAJORITY"
  "${authorized_voter_args[@]}"
  "${trusted_validator_args[@]}"
  "${frozen_accounts[@]}"
)

if [[ -n $GOSSIP_HOST ]]; then
  args+=(--gossip-host "$GOSSIP_HOST")
else
  args+=(--entrypoint "$ENTRYPOINT")
  args+=(--no-genesis-fetch)
fi

exec solana-validator "${args[@]}"
