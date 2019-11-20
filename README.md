
# Machine Overview

Each machine is configured as similarly as possible.  The solana sofware runs
under the user `solanad` as a systemd service.  The name of the systemd service
is the same across all nodes, `solanad`.

The ledger is stored in /home/solanad/ledger

## Cluster Entrypoint Node
* DNS: mainnet.solana.com
* Static IP: 34.83.130.52
* GCE Instance Name: entrypoint-mainnet-solana-com
* OS Image: Ubuntu 18.04 LTS Minimal
* Boot disk: Standard disk, 200GB
* Machine type: n1-standard-1
* Region: us-west-1
* ssh: `gcloud --project solana-mainnet compute ssh entrypoint-mainnet-solana-com`

## Bootstrap Leader Node
* DNS: none
* Static IP: none
* GCE Instance Name: bootstrap-leader-mainnet-solana-com
* OS Image: Ubuntu 18.04 LTS Minimal
* Boot disk: Standard disk, 2TB
* Machine type: n1-standard-8
* Region: us-west-1
* ssh: `gcloud --project solana-mainnet compute ssh bootstrap-leader-mainnet-solana-com`

## RPC Node
* DNS: api.mainnet.solana.com
* Static IP: 34.82.79.31
* GCE Resource Name: api-mainnet-solana-com
* OS Image: Ubuntu 18.04 LTS Minimal
* Boot disk: Standard disk, 2TB
* Machine type: n1-standard-8
* Region: us-west-1
* ssh: `gcloud --project solana-mainnet compute ssh api-mainnet-solana-com`

# Metrics
```
SOLANA_METRICS_CONFIG="host=https://metrics.solana.com:8086,db=mainnet,u=mainnet_writer,p=2aQdShmtsPSAgABLQiK2FpSCJGLtG8h3vMEVz1jE7Smf"
```

Metrics [dashboard](https://metrics.solana.com:3000/d/testnet-edge/testnet-monitor-edge?orgId=2&from=now-5m&to=now&refresh=5s&var-testnet=mainnet&var-hostid=All)

# Workflows

## Changing the deployed Solana software version
There are two places to be modified to update the Solana software version to deploy:
1. On your machine as genesis will be build on your local machine.  Run `solana-install init <desired version>`.
1. Modify the `SOLANA_VERSION=` variable in `remote-machine-setup.sh`.

## Launch a development mainnet
A development mainnet can be created at any time by anybody.   The instances
will be created in the standard GCE development project, scoped by your
username.

Procedure:
1. Ensure the desired Solana release is installed on your machine
1. Run `./genesis.sh` to produce the genesis configuration
1. Run `./launch-mainnet.sh` to create the development mainnet instances

When done run `./delete-mainnet.sh` to delete the instances.

## Launch *THE* mainnet
Same as launching a development mainnet except:
1. You need access to the `solana-mainnet` GCE project
1. `export PRODUCTION=1` before running `./launch-mainnet.sh`

The `./launch-mainnet.sh` script programmatically creates and configures the
mainnet instances.

## Manipulating the systemd service
The file `/etc/systemd/system/solanad.service` describes the systemd service for
each of the instances.

From a shell on the instance, view the current status of the services with
```
$ sudo systemctl status solanad
```

Follow logs with:
```
$ journalctl -u solanad -f
```

If `/etc/systemd/system/solanad.service` is modified, apply the changes with:
```
$ sudo systemctl daemon-reload
$ sudo systemctl restart solanad
```

## Updating the solana software
From a shell on the instance run:
```
$ /solana-update.sh 0.21.0
```

There's no mechanism to automatically update the software across all the nodes
at once.

