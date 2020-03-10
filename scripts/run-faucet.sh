#!/bin/bash -ex

cd ~
. service-env.sh
exec solana-faucet --keypair ~/faucet.json
