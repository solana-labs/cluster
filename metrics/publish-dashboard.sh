#!/usr/bin/env bash
set -e

cd "$(dirname "$0")"
. ../env.sh
. setup-grafcli.sh

set -x
grafcli import aisle-5.json remote/metrics
