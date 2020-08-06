#!/usr/bin/env bash
set -ex

~/bin/check-hostname.sh

#shellcheck source=/dev/null
. ~/service-env.sh

identity_keypair=~/api-identity.json
identity_pubkey=$(solana-keygen pubkey $identity_keypair)

trusted_validators=()
for tv in "${TRUSTED_VALIDATOR_PUBKEYS[@]}"; do
  [[ $tv = "$identity_pubkey" ]] || trusted_validators+=(--trusted-validator "$tv")
done

if [[ -f ~/faucet.json ]]; then
  maybe_rpc_faucet_address="--rpc-faucet-address 127.0.0.1:9900"
fi

exec solana-validator \
  --gossip-port 8001 \
  --dynamic-port-range 8002-8012 \
  --entrypoint "${ENTRYPOINT}" \
  --ledger ~/ledger \
  --identity "$identity_keypair" \
  --limit-ledger-size 600000000 \
  --log ~/solana-validator.log \
  --no-genesis-fetch \
  --no-voting \
  --rpc-port 8899 \
  --enable-rpc-transaction-history \
  ${maybe_rpc_faucet_address} \
  --expected-genesis-hash "$EXPECTED_GENESIS_HASH" \
  --expected-shred-version "$EXPECTED_SHRED_VERSION" \
  --expected-bank-hash "$EXPECTED_BANK_HASH" \
  --wait-for-supermajority "$WAIT_FOR_SUPERMAJORITY" \
  "${trusted_validators[@]}" \
  --no-untrusted-rpc \
