#!/usr/bin/env bash

set -e
cd ~

source ./service-env.sh

mkdir -p pid/

(
  # shellcheck source=./configure-metrics.sh
  source bin/configure-metrics.sh
  sudo SOLANA_METRICS_CONFIG="$SOLANA_METRICS_CONFIG" bin/monitors/oom-monitor.sh
) > oom-monitor.log 2>&1 &
echo $! > pid/oom-monitor.pid

bin/monitors/fd-monitor.sh > fd-monitor.log 2>&1 &
echo $! > pid/fd-monitor.pid

bin/monitors/net-stats.sh  > net-stats.log 2>&1 &
echo $! > pid/net-stats.pid

bin/monitors/system-stats.sh  > system-stats.log 2>&1 &
echo $! > pid/system-stats.pid

wait
