#
# Remote setup script run on a new instance by |launch-mainnet.sh|
#

set -ex
cd ~

SOLANA_VERSION=$1
IS_API=$2

test -n "$SOLANA_VERSION"

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
sudo cp ./*.service /etc/systemd/system/solanad.service
rm ./*.service
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

[[ -n $IS_API ]] || exit 0;

echo TODO: Use a real certificate in production

# Create a self-signed certificate for haproxy to use
# https://security.stackexchange.com/questions/74345/provide-subjectaltname-to-openssl-directly-on-the-command-line
openssl genrsa -out ca.key 2048
openssl req -new -x509 -days 365 -key ca.key -subj "/C=CN/ST=GD/L=SZ/O=Acme, Inc./CN=Acme Root CA" -out ca.crt
openssl req -newkey rsa:2048 -nodes -keyout server.key -subj "/C=CN/ST=GD/L=SZ/O=Acme, Inc./CN=*.example.com" -out server.csr
openssl x509 -req -extfile <(printf "subjectAltName=DNS:example.com,DNS:www.example.com") -days 365 -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt
sudo bash -c "cat server.key server.crt >> /etc/ssl/private/haproxy.pem"
rm -rf ./*

sudo apt-get -y install haproxy
cp /etc/haproxy/haproxy.cfg .
cat >> haproxy.cfg <<EOF
frontend jsonrpc_http
    bind 0.0.0.0:80
    default_backend jsonrpc
frontend jsonrpc_https
    bind 0.0.0.0:443 ssl crt /etc/ssl/private/haproxy.pem
    default_backend jsonrpc
frontend pubsub_wss
    bind 0.0.0.0:8901 ssl crt /etc/ssl/private/haproxy.pem
    default_backend pubsub
backend jsonrpc
    mode http
    server rpc 127.0.0.1:8899
backend pubsub
    mode http
    server rpc 127.0.0.1:8900
EOF

sudo cp haproxy.cfg /etc/haproxy
rm haproxy.cfg
sudo haproxy -c -f /etc/haproxy/haproxy.cfg
sudo systemctl restart haproxy
sudo systemctl status haproxy

exit 0
