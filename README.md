

## Cluster Entrypoint Node
* DNS: mainnet.solana.com
* Static IP: 34.83.130.52
* GCE Resource Name: mainnet-solana-com
* OS Image: Ubuntu 18.04 LTS Minimal
* Boot disk: Standard disk, 10GB
* Machine type: n1-standard-1
* Region: us-west-1
* ssh: `gcloud --project solana-mainnet compute ssh mainnet-solana-com`


### Machine Setup
First complete the [Common Machine Setup](#common-machine-setup).

Then ssh into the machine and:
```
$ sudo vim /etc/systemd/system/solana-entrypoint.service
```
and copy in the contents of the file `solana-entrypoint.service`.


Run the following to activate the service:
```
$ sudo systemctl daemon-reload
$ sudo systemctl start solana-entrypoint
$ sudo systemctl enable solana-entrypoint
$ sudo systemctl status solana-entrypoint
$ sudo reboot
```

The entrypoint should come up automatically upon reboot.

### Monitoring
```
$ gcloud --project solana-mainnet compute ssh mainnet-solana-com -- journalctl -u solana-entrypoint -f
```

### Solana Software Upgrade
```
$ sudo systemctl stop solana-entrypoint
$ sudo --login -u solana solana-install update
$ sudo systemctl start solana-entrypoint
$ sudo systemctl status solana-entrypoint
```

## RPC Node
_TBD_

## Bootstrap Leader Node
_TBD_

## Warehouse Node
_TBD_



### Common Machine Setup

Once the machine is created, ssh into it as your normal user and:
```
$ sudo apt-get update
$ sudo apt-get install vim
$ sudo adduser solana --gecos "" --disabled-password --quiet
$ sudo deluser solana google-sudoers
$ sudo --login -u solana
$ curl -sSf https://raw.githubusercontent.com/solana-labs/solana/v0.20.3/install/solana-install-init.sh | sh -s
$ export PATH="/home/solana/.local/share/solana/install/active_release/bin:$PATH"
$ solana-install init edge
```
