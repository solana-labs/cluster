#!/bin/bash -ex

. ~/service-env.sh
exec solana-faucet --keypair ~/faucet.json
