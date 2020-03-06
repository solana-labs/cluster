#!/usr/bin/env bash
set -ex

#shellcheck source=/dev/null
. service-env.sh

exec solana-validator \
  --dynamic-port-range 8001-8010 \
  --entrypoint "${ENTRYPOINT}" \
  --gossip-port 8001 \
  --ledger ./ledger \
  --identity-keypair ./api-identity.json \
  --limit-ledger-size 500000 \
  --log - \
  --no-genesis-fetch \
  --no-voting \
  --rpc-port 8899 \
  --enable-rpc-get-confirmed-block \
  --expected-genesis-hash "${EXPECTED_GENESIS_HASH}" \
  --expected-shred-version "${EXPECTED_SHRED_VERSION}" \
  --blockstream /tmp/solana-blockstream.sock \
  --skip-poh-verify  \
  --dev-no-sigverify \
  --wait-for-supermajority 0 \
