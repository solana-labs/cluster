#!/usr/bin/env bash
set -ex

#shellcheck source=/dev/null
. service-env.sh

exec solana-validator \
  --dynamic-port-range 8001-8010 \
  --entrypoint "${ENTRYPOINT}" \
  --gossip-port 8001 \
  --identity-keypair ./bootstrap-validator-identity.json \
  --ledger ./ledger \
  --limit-ledger-size 500000 \
  --log - \
  --no-genesis-fetch \
  --rpc-port 8899 \
  --voting-keypair ./bootstrap-validator-vote-account.json \
  --expected-genesis-hash "${EXPECTED_GENESIS_HASH}" \
  --expected-shred-version "${EXPECTED_SHRED_VERSION}" \
  --wait-for-supermajority "${WAIT_FOR_SUPERMAJORITY}" \
