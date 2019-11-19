#
# Remote setup script run on a new instance by |launch-mainnet.sh|
#

SOLANA_VERSION=edge

set -ex
cd ~

# Install minimal tools
sudo apt-get update
sudo apt-get -y install vim

# Create solanad user
sudo adduser solanad --gecos "" --disabled-password --quiet

# Install solana release as the solanad user
sudo --login -u solanad -- bash -c "
  curl -sSf https://raw.githubusercontent.com/solana-labs/solana/v0.20.3/install/solana-install-init.sh | sh -s $SOLANA_VERSION
"

# Move the systemd service file into /etc
sudo cp ./solana-*.service /etc/systemd/system/solanad.service
rm ./solana-*.service
sudo systemctl daemon-reload

# Move the remainder of the files in the home directory over to the solanad user
sudo chown -R solanad:solanad ./*
sudo mv ./* /home/solanad

# Start the solana service
sudo systemctl start solanad
sudo systemctl enable solanad
sudo systemctl status solanad

# Create easy to use software update script
cat > solana-update.sh <<EOF
#!/usr/bin/env bash

if [[ -z \$1 ]]; then
  echo "Usage: \$0 [version]"
  exit 1
fi
set -ex
sudo systemctl stop solanad
sudo --login -u solanad -- solana-install init "\$@"
sudo systemctl start solanad
sudo systemctl status solanad
EOF
chmod +x solana-update.sh
sudo cp solana-update.sh /
rm solana-update.sh

exit 0
