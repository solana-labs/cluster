#!/usr/bin/env bash
#
# Remote setup script run on a new instance by |launch-mainnet.sh|
#

set -ex
cd ~

SOLANA_VERSION=$1
NODE_TYPE=$2

test -n "$SOLANA_VERSION"

# Setup timezone
sudo ln -sf /usr/share/zoneinfo/America/Los_Angeles /etc/localtime

# Install minimal tools
sudo apt-get update
sudo apt-get --assume-yes install vim software-properties-common

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
sudo systemctl --no-pager status solanad

# Create easy to use software update script
{
  cat <<EOF
#!/usr/bin/env bash

if [[ -z \$1 ]]; then
  echo "Usage: \$0 [version]"
  exit 1
fi
set -ex
sudo systemctl stop solanad
sudo --login -u solanad -- solana-install init "\$@"
sudo systemctl start solanad
sudo systemctl --no-pager status solanad
EOF
} | sudo tee /solana-update.sh
sudo chmod +x /solana-update.sh

if [[ $NODE_TYPE != api && $NODE_TYPE != apiproduction ]]; then
  exit 0
fi

# Create a self-signed certificate for haproxy to use
# https://security.stackexchange.com/questions/74345/provide-subjectaltname-to-openssl-directly-on-the-command-line
openssl genrsa -out ca.key 2048
openssl req -new -x509 -days 365 -key ca.key -subj "/C=CN/ST=GD/L=SZ/O=Acme, Inc./CN=Acme Root CA" -out ca.crt
openssl req -newkey rsa:2048 -nodes -keyout server.key -subj "/C=CN/ST=GD/L=SZ/O=Acme, Inc./CN=*.example.com" -out server.csr
openssl x509 -req -extfile <(printf "subjectAltName=DNS:example.com,DNS:www.example.com") -days 365 -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt
sudo bash -c "cat server.key server.crt >> /etc/ssl/private/haproxy.pem"
rm -rf ./*

sudo add-apt-repository --yes ppa:certbot/certbot
sudo apt-get --assume-yes install haproxy certbot

{
  cat <<EOF
frontend http
    bind *:80
    default_backend jsonrpc
    stats enable
    stats hide-version
    stats refresh 30s
    stats show-node
    stats uri /stats
    acl letsencrypt-acl path_beg /.well-known/acme-challenge/
    use_backend letsencrypt if letsencrypt-acl

frontend https
    bind *:443 ssl crt /etc/ssl/private/haproxy.pem
    default_backend jsonrpc
    stats enable
    stats hide-version
    stats refresh 30s
    stats show-node
    stats uri /stats
    #acl letsencrypt-acl path_beg /.well-known/acme-challenge/
    #use_backend letsencrypt if letsencrypt-acl

frontend wss
    bind *:8901 ssl crt /etc/ssl/private/haproxy.pem
    default_backend pubsub

backend jsonrpc
    mode http
    server rpc 127.0.0.1:8899

backend pubsub
    mode http
    server rpc 127.0.0.1:8900

backend letsencrypt
    mode http
    server letsencrypt 127.0.0.1:4444
EOF
} | sudo tee -a /etc/haproxy/haproxy.cfg

sudo haproxy -c -f /etc/haproxy/haproxy.cfg
sudo systemctl restart haproxy
sudo systemctl --no-pager status haproxy

{
  cat <<'EOF'
#!/usr/bin/env bash

if [[ $(id -u) != 0 ]]; then
  echo Not root
  exit 1
fi

set -ex

maybeDryRun=
# Uncomment during testing to avoid hitting LetsEncrypt API limits while iterating
#maybeDryRun=--dry-run

if [[ -r /letsencrypt.tgz ]]; then
  tar -C / -zxf /letsencrypt.tgz
fi

certbot certonly \
  --standalone -d "api.mainnet.solana.com" \
  --non-interactive \
  --agree-tos \
  --email maintainers@solana.com \
  \$maybeDryRun \
  --http-01-port=4444

tar zcf /letsencrypt.new.tgz /etc/letsencrypt
mv -f /letsencrypt.new.tgz /letsencrypt.tgz
ls -l /letsencrypt.tgz

if [[ -z $maybeDryRun ]]; then
  cat \
    /etc/letsencrypt/live/api.mainnet.solana.com/fullchain.pem \
    /etc/letsencrypt/live/api.mainnet.solana.com/privkey.pem \
    | tee /etc/ssl/private/haproxy.pem
fi

systemctl restart haproxy
systemctl --no-pager status haproxy
EOF
} | sudo tee /solana-renew-cert.sh
sudo chmod +x /solana-renew-cert.sh


if [[ $NODE_TYPE = apiproduction ]]; then
  sudo /solana-renew-cert.sh
  # TODO: By default, LetsEncrypt creates a CRON entry at /etc/cron.d/certbot.
  # The entry runs twice a day (by default, LetsEncrypt will only renew the
  # certificate if its expiring within 30 days).
  #
  # What I like to do is to run a bash script that's run monthly, and to force a renewal of the certificate every time.
  #
  # We can start by editing the CRON file to run a script monthly:
  # "0 0 1 * * root bash /opt/update-certs.sh"
fi


exit 0
