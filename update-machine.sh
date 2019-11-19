#!/usr/bin/env bash

instanceName=$1

if [[ -z $instanceName ]]; then
  echo "Usage $0 [instance name]"
  exit 1
fi

serviceName=
case "$instanceName" in
mainnet-solana-com)
  serviceName=solana-entrypoint
  ;;
api-mainnet-solana-com)
  serviceName=solana-api
  ;;
bootstrap-leader-mainnet-solana-com)
  serviceName=solana-bs
  ;;
*)
  echo "Error: unknown instance: $instanceName"
  exit 1
esac


cat > solana-service-env.sh <<EOF
SOLANA_METRICS_CONFIG="host=https://metrics.solana.com:8086,db=tds,u=tds_writer,p=dry_run"
SOLANA_ENTRYPOINT_IP=$(dig +short mainnet.solana.com)
EOF

set -ex
gcloud --project solana-mainnet compute scp --recurse ./* "$instanceName":

gcloud --project solana-mainnet compute ssh "$instanceName" -- "
  set -ex
  sudo systemctl stop solana-\*
  sudo --login -u solana -- solana-install update
  sudo cp ./*.service /etc/systemd/system
  sudo cp service-env.sh /solana-service-env.sh
  sudo systemctl daemon-reload
  sudo systemctl start $serviceName
  sudo systemctl enable $serviceName
  sudo systemctl status $serviceName
"
