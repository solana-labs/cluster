#!/usr/bin/env bash
set -ex

#shellcheck source=/dev/null
. /home/sol/service-env.sh

exec solana-sys-tuner --user sol
