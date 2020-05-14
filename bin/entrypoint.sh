#!/usr/bin/env bash
set -ex

#shellcheck source=/dev/null
. ~/service-env.sh

exec solana-gossip spy --gossip-port $ENTRYPOINT_PORT --gossip-host $ENTRYPOINT_HOST --shred-version $EXPECTED_SHRED_VERSION
