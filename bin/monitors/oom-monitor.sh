#!/usr/bin/env bash
#
# Reports Linux OOM Killer activity
#
set -e

cd "$(dirname "$0")"

# shellcheck source=scripts/configure-metrics.sh
source ~/bin/configure-metrics.sh

[[ $(uname) = Linux ]] || exit 0

syslog=/var/log/syslog
[[ -r $syslog ]] || {
  echo Unable to read $syslog
  exit 1
}

while read -r victim; do
  echo "Out of memory event detected, $victim killed"
  ~/bin/metrics-write-datapoint.sh "oom-killer,victim=$victim,hostname=$HOSTNAME killed=1"
done < <( \
  tail --follow=name --retry -n0 $syslog \
  | sed --unbuffered -n "s/^.* earlyoom\[[0-9]*\]: Killing process .\(.*\). with signal .*/\1/p" \
)

exit 1
