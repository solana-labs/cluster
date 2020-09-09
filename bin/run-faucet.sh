#!/bin/bash -ex

. ~/service-env.sh
exec solana-faucet \
  --keypair ~/faucet.json \
  --per-request-cap 10 \
  --per-time-cap 50 \
  --slice 10
