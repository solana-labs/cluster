#!/usr/bin/env bash
#
# Remote setup script run on a new instance by |launch-cluster.sh|
#

set -ex
cd ~

SOLANA_VERSION=$1
NODE_TYPE=$2
DNS_NAME=$3

test -n "$SOLANA_VERSION"
test -n "$NODE_TYPE"

# Setup timezone
sudo ln -sf /usr/share/zoneinfo/America/Los_Angeles /etc/localtime

# Install minimal tools
sudo apt-get update
sudo apt-get --assume-yes install \
  cron \
  graphviz \
  iotop \
  iputils-ping \
  less \
  lsof \
  psmisc \
  screen \
  silversearcher-ag \
  software-properties-common \
  vim \

# Create sol user
sudo adduser sol --gecos "" --disabled-password --quiet
sudo adduser sol sudo
sudo adduser sol adm
sudo -- bash -c 'echo "sol ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers'

# Install solana release as the sol user
sudo --login -u sol -- bash -c "
  curl -sSf https://raw.githubusercontent.com/solana-labs/solana/v1.0.0/install/solana-install-init.sh | sh -s $SOLANA_VERSION
"

sudo --login -u sol -- bash -c "
  echo ~/bin/print-keys.sh >> ~/.profile;
  mkdir ~/.ssh;
  chmod 0700 ~/.ssh;
  echo 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKU6YrfEw24+hhxOsu7bAXr1m38G9CCmtUtPpgOjXys4 mvines@sol' >> ~/.ssh/authorized_keys;
  echo 'ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBKMl07qHaMCmnvRKBCmahbBAR6GTWkR5BVe8jdzDJ7xzjXLZlf1aqfaOjt5Cu2VxvW7lUtpJQGLJJiMnWuD4Zmc= dan@Dans-MBP.local' >> ~/.ssh/authorized_keys;

"

ln -s /etc/systemd/system/sol.service .

# Setup log rotation
cat > logrotate.sol <<EOF
/home/sol/solana-validator.log {
  rotate 7
  daily
  missingok
  postrotate
    systemctl kill -s USR1 sol.service
  endscript
}
EOF
sudo cp logrotate.sol /etc/logrotate.d/sol
rm logrotate.sol

cat > stop <<EOF
#!/usr/bin/env bash
# Stop the $NODE_TYPE software

set -ex
sudo systemctl stop sol
EOF
chmod +x stop

cat > restart <<EOF
#!/usr/bin/env bash
# Restart the $NODE_TYPE software

set -ex
sudo systemctl daemon-reload
sudo systemctl restart sol
EOF
chmod +x restart

cat > journalctl <<EOF
#!/usr/bin/env bash
# Follow new journalctl entries for a service to the console

set -ex
sudo journalctl -f "\$@"
EOF
chmod +x journalctl

cat > sol <<EOF
#!/usr/bin/env bash
# Switch to the sol user

set -ex
sudo --login -u sol -- "\$@"
EOF
chmod +x sol

cat > update <<EOF
#!/usr/bin/env bash
# Software update

if [[ -z \$1 ]]; then
  echo "Usage: \$0 [version]"
  exit 1
fi
set -ex
if [[ \$USER != sol ]]; then
  sudo --login -u sol -- solana-install init "\$@"
else
  solana-install init "\$@"
fi
sudo systemctl daemon-reload
sudo systemctl restart sol
sudo systemctl --no-pager status sol
EOF
chmod +x update


# Move the remainder of the files in the home directory over to the sol user
sudo chown -R sol:sol ./*
sudo mv ./* /home/sol

# Move the systemd service files into /etc
sudo cp /home/sol/bin/solana-sys-tuner.service /etc/systemd/system/solana-sys-tuner.service
sudo cp /home/sol/bin/"$NODE_TYPE".service /etc/systemd/system/sol.service
sudo systemctl daemon-reload

# Start the solana-sys-tuner service
sudo systemctl enable --now solana-sys-tuner
sudo systemctl --no-pager status solana-sys-tuner

# Start the solana service
sudo systemctl enable --now sol
sudo systemctl --no-pager status sol

sudo --login -u sol -- bash -c "
  set -ex;
  echo '#!/bin/sh' > ~/on-reboot;
  echo '/home/sol/bin/run-monitors.sh &' > ~/on-reboot;
  if [[ -f /home/sol/faucet.json ]]; then
    echo '/home/sol/bin/run-faucet.sh &' > ~/on-reboot;
  fi;
  chmod +x ~/on-reboot;

  echo '@reboot /home/sol/on-reboot' | crontab -;
  crontab -l;
  screen -dmS on-reboot ~/on-reboot
"

[[ $NODE_TYPE = api ]] || exit 0

# Create a self-signed certificate for haproxy to use
# https://security.stackexchange.com/questions/74345/provide-subjectaltname-to-openssl-directly-on-the-command-line
openssl genrsa -out ca.key 2048
openssl req -new -x509 -days 365 -key ca.key -subj "/C=CN/ST=GD/L=SZ/O=Acme, Inc./CN=Acme Root CA" -out ca.crt
openssl req -newkey rsa:2048 -nodes -keyout server.key -subj "/C=CN/ST=GD/L=SZ/O=Acme, Inc./CN=*.example.com" -out server.csr
openssl x509 -req -extfile <(printf "subjectAltName=DNS:example.com,DNS:www.example.com") -days 365 -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt
sudo bash -c "cat server.key server.crt >> /etc/ssl/private/haproxy.pem"

rm ca.key ca.crt ca.srl server.crt server.csr server.key

sudo add-apt-repository --yes ppa:certbot/certbot -r
sudo apt-get --assume-yes install haproxy certbot

{
  cat <<EOF
frontend http
    bind *:80

    # rate limit to 10 RPC requests in 2 seconds per IP
    stick-table  type ip  size 100k  expire 30s  store http_req_rate(2s)
    http-request track-sc0 src
    http-request deny deny_status 429 if { sc_http_req_rate(0) gt 10 }

    stats enable
    stats hide-version
    stats refresh 30s
    stats show-node
    stats uri /stats

    acl letsencrypt-acl path_beg /.well-known/acme-challenge/
    use_backend letsencrypt if letsencrypt-acl
    acl is_websocket hdr(Upgrade) -i WebSocket

    default_backend jsonrpc
    use_backend pubsub if is_websocket

frontend https
    bind *:443 ssl crt /etc/ssl/private/haproxy.pem
    bind *:8443 ssl crt /etc/ssl/private/haproxy.pem

    # rate limit to 10 RPC requests in 2 seconds per IP
    stick-table  type ip  size 100k  expire 30s  store http_req_rate(2s)
    http-request track-sc0 src
    http-request deny deny_status 429 if { sc_http_req_rate(0) gt 10 }

    stats enable
    stats hide-version
    stats refresh 30s
    stats show-node
    stats uri /stats

    #acl letsencrypt-acl path_beg /.well-known/acme-challenge/
    #use_backend letsencrypt if letsencrypt-acl
    acl is_websocket hdr(Upgrade) -i WebSocket

    default_backend jsonrpc
    use_backend pubsub if is_websocket

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


# Skip letsencrypt TLS setup if no DNS name
[[ -n $DNS_NAME ]] || exit 0

{
  cat <<EOF
#!/usr/bin/env bash

if [[ \$(id -u) != 0 ]]; then
  echo Not root
  exit 1
fi

set -ex

if [[ -r /letsencrypt.tgz ]]; then
  tar -C / -zxf /letsencrypt.tgz
fi

certbot certonly \
  --standalone -d $DNS_NAME \
  --non-interactive \
  --agree-tos \
  --email maintainers@solana.com \
  --http-01-port=4444

tar zcf /letsencrypt.new.tgz /etc/letsencrypt
mv -f /letsencrypt.new.tgz /letsencrypt.tgz
ls -l /letsencrypt.tgz

if [[ -z \$maybeDryRun ]]; then
  cat \
    /etc/letsencrypt/live/$DNS_NAME/fullchain.pem \
    /etc/letsencrypt/live/$DNS_NAME/privkey.pem \
    | tee /etc/ssl/private/haproxy.pem
fi

systemctl restart haproxy
systemctl --no-pager status haproxy
EOF
} | sudo tee /solana-renew-cert.sh
sudo chmod +x /solana-renew-cert.sh

sudo /solana-renew-cert.sh
cat > solana-renew-cert <<EOF
@weekly /solana-renew-cert.sh
EOF
sudo cp solana-renew-cert /etc/cron.d/
rm solana-renew-cert

exit 0
