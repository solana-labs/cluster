#!/usr/bin/env bash

cd "$(dirname "$0")"
source env.sh

instanceName=$1

if [[ -z $instanceName ]]; then
  echo "Usage $0 [instance name]"
  exit 1
fi

set -x
gcloud --project $PROJECT compute ssh --zone $ZONE "$instanceName" -- journalctl -u solanad -f
