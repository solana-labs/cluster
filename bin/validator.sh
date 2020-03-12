#!/usr/bin/env bash
set -ex

#shellcheck source=/dev/null
source ~/service-env.sh

#shellcheck source=/dev/null
source ~/service-env-validator-*.sh

identity_keypair=~/validator-identity-$ZONE.json
identity_pubkey=$(solana-keygen pubkey $identity_keypair)

trusted_validators=()
for tv in ${TRUSTED_VALIDATOR_PUBKEYS[@]}; do
  [[ $tv = "$identity_pubkey" ]] || trusted_validators+=(--trusted-validator "$tv")
done

exec solana-validator \
  --dynamic-port-range 8001-8010 \
  --entrypoint "$ENTRYPOINT" \
  --gossip-port 8001 \
  --identity-keypair "$identity_keypair" \
  --ledger ~/ledger \
  --limit-ledger-size 1000000 \
  --log - \
  --no-genesis-fetch \
  --rpc-port 8899 \
  --voting-keypair ~/validator-vote-account-$ZONE.json \
  --expected-genesis-hash "$EXPECTED_GENESIS_HASH" \
  --expected-shred-version "$EXPECTED_SHRED_VERSION" \
  --wait-for-supermajority "$WAIT_FOR_SUPERMAJORITY" \
  "${trusted_validators[@]}" \
  --no-untrusted-rpc \
