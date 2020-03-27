#!/usr/bin/env bash
set -ex

#shellcheck source=/dev/null
. ~/service-env.sh

exec solana-sys-tuner --user $(whoami)
