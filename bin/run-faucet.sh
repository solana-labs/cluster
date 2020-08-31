#!/bin/bash -ex

. ~/service-env.sh
exec solana-faucet \
  --keypair ~/faucet.json \
  --per-request-cap 10 \
  --per-time-cap 10 \
  --slice 10
