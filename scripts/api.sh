#!/usr/bin/env bash
set -ex

#shellcheck source=/dev/null
. service-env.sh

identity_keypair=./api-identity.json
identity_pubkey=$(solana-keygen pubkey $identity_keypair)

trusted_validators=()
for tv in ${TRUSTED_VALIDATORS[@]}; do
  [[ $tv = "$identity_pubkey" ]] || trusted_validators+=(--trusted-validator "$tv")
done

exec solana-validator \
  --dynamic-port-range 8001-8010 \
  --entrypoint "${ENTRYPOINT}" \
  --gossip-port 8001 \
  --ledger ./ledger \
  --identity-keypair "$identity_keypair" \
  --limit-ledger-size 500000 \
  --log - \
  --no-genesis-fetch \
  --no-voting \
  --rpc-port 8899 \
  --enable-rpc-get-confirmed-block \
  --expected-genesis-hash "$EXPECTED_GENESIS_HASH" \
  --expected-shred-version "$EXPECTED_SHRED_VERSION" \
  --blockstream /tmp/solana-blockstream.sock \
  --wait-for-supermajority "$WAIT_FOR_SUPERMAJORITY" \
  "${trusted_validators[@]}" \
  --no-untrusted-rpc \
