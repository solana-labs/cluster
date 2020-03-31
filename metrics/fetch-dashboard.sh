#!/usr/bin/env bash
set -e

cd "$(dirname "$0")"
CLUSTER=devnet
. ../env.sh
. setup-grafcli.sh

set -x
grafcli export remote/metrics/aisle-5 aisle-5.json
