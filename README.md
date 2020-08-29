_WARNING_: THIS README IS OUTDATED

# Machine Overview

Each machine is configured as similarly as possible.  The solana sofware runs
under the user `sol` as a systemd service.  The name of the systemd service
is the same across all nodes, `sol`.

The ledger is stored in /home/sol/ledger

## Cluster Entrypoint Node
* DNS: cluster.solana.com
* Static IP: 35.227.139.150
* GCE Instance Name: cluster-entrypoint
* OS Image: Ubuntu 20.04 LTS Minimal
* Boot disk: Standard disk, 200GB
* Machine type: n1-standard-1
* Region: us-west-1
* ssh: `gcloud --project solana-cluster compute ssh cluster-entrypoint`

## Bootstrap Validator Node
* DNS: none
* Static IP: none
* GCE Instance Name: cluster-bootstrap-validator
* OS Image: Ubuntu 20.04 LTS Minimal
* Boot disk: Standard disk, 2TB
* Machine type: n1-standard-16
* Region: us-west-1
* ssh: `gcloud --project solana-cluster compute ssh cluster-bootstrap-validator`

## RPC Node
* DNS: api.cluster.solana.com
* Static IP: 35.197.59.229
* GCE Resource Name: cluster-api
* OS Image: Ubuntu 20.04 LTS Minimal
* Boot disk: Standard disk, 2TB
* Machine type: n1-standard-16
* Region: us-west-1
* ssh: `gcloud --project solana-cluster compute ssh cluster-api`

## Warehouse Node
* DNS: none
* Static IP: none
* GCE Instance Name: cluster-warehouse
* OS Image: Ubuntu 20.04 LTS Minimal
* Boot disk: Standard disk, 2TB
* Machine type: n1-standard-16
* Region: us-west-1
* ssh: `gcloud --project solana-cluster compute ssh cluster-warehouse`

## Watchtower Node
* DNS: none
* Static IP: none
* GCE Instance Name: cluster-watchtower
* OS Image: Ubuntu 20.04 LTS Minimal
* Boot disk: Standard disk, 200GB
* Machine type: n1-standard-1
* Region: us-west-1
* ssh: `gcloud --project solana-cluster compute ssh cluster-watchtower`

# Metrics
The following metrics configuration is used in production:
```
# These public credentials are a known risk
SOLANA_METRICS_CONFIG="host=https://metrics.solana.com:8086,db=cluster,u=cluster_write,p=2aQdShmtsPSAgABLQiK2FpSCJGLtG8h3vMEVz1jE7Smf"
```

Production metrics [dashboard](http://bit.ly/solana-cluster)

# Internal Workflows
## Changing the deployed Solana software version
There are two places to be modified to update the Solana software version to deploy:
1. On your machine as genesis will be build on your local machine.  Run `solana-install init <desired version>`.
1. Modify the `RELEASE_CHANNEL_OR_TAG=` variable in `launch-cluster.sh`.

## Launch a development cluster
A development cluster can be created at any time by anybody.   The instances
will be created in the standard GCE development project, scoped by your
username.

Procedure:
1. Ensure the desired Solana release is installed on your machine
1. Run `./genesis.sh` to produce the genesis configuration.  To override the
   default cluster creation time of _now_, include the `--creation-time` argument
   (eg `./genesis.sh --creation-time '2020-01-01T12:00:00-08:00'`)
1. If metrics are desired set SOLANA_METRICS_CONFIG in your environment
1. Run `./launch-cluster.sh` to create the development cluster instances

When done run `./delete-cluster.sh` to delete the instances.

## Launch *THE* cluster
Same as launching a development cluster except:
1. You need access to the `solana-cluster` GCE project
1. `SOLANA_METRICS_CONFIG` is automatically configured
1. `export CLUSTER=cluster` before running `./launch-cluster.sh`

The `./launch-cluster.sh` script programmatically creates and configures the
cluster instances.

## Manipulating the systemd service
The file `/etc/systemd/system/sol.service` describes the systemd service for
each of the instances.

From a shell on the instance, view the current status of the services with
```
$ sudo systemctl status sol
```

Follow logs with:
```
$ journalctl -u sol -f
```

If `/etc/systemd/system/sol.service` is modified, apply the changes with:
```
$ sudo systemctl daemon-reload
$ sudo systemctl restart sol
```

## Updating the solana software
From a shell on the instance run:
```
$ /solana-update.sh 0.22.0
```

There's no mechanism to automatically update the software across all the nodes
at once.

## Delegating Stake to a Validator
As external validators boot they receive 1m SOL in equal stake.

To locate the online validators run:
```bash
$ solana show-validators
```

The `solana catchup` command can be used to block until a given validator has
caught up to the cluster.

Then use the `solana delegate-stake` command for each validator using a **TBD**
stake account.

## Fetching a ledger snapshot
To view the available ledger snapshots, run:
```bash
$ ./fetch-ledger-snapshot.sh
```

Downloading a snapshot can be accomplished with:
```bash
$ ./fetch-ledger-snapshot.sh 2019-12-03T22:54:59Z  # <-- replace with the desired snapshot timestamp
```

Boot a validator from the downloaded snapshot with:
```bash
$ solana-validator \
  --ledger ledger-snapshot \
  --no-genesis-fetch \
  --no-snapshot-fetch ...
```

# Validator Workflow
The minimal steps required of a validator participating in the initial boot of the cluster are:

## Installing the software
`
  $ curl -sSf https://raw.githubusercontent.com/solana-labs/solana/v0.21.1/install/solana-install-init.sh | sh -s - 0.21.2
`

then configure the command-line tool's RPC endpoint URL:
```bash
$ solana set --url http://34.82.79.31/
```

## Starting your validator:
Assuming that `~/validator-keypair.json` and `~/validator-vote-keypair.json`
contain the validator identity and vote keypairs that were registered in the
genesis configuration, run:

```bash
# These public credentials are a known risk
$ export SOLANA_METRICS_CONFIG="host=https://metrics.solana.com:8086,db=cluster,u=cluster_write,p=2aQdShmtsPSAgABLQiK2FpSCJGLtG8h3vMEVz1jE7Smf"
$ export EXPECTED_GENESIS_HASH=##### <--- To be communicated by Solana
$ solana-validator \
  --identity-keypair ~/validator-keypair.json \
  --voting-keypair ~/validator-vote-keypair.json \
  --ledger ~/validator-ledger \
  --rpc-port 8899 \
  --entrypoint 34.83.130.52:8001
  --limit-ledger-size \
  --expected-genesis-hash $EXPECTED_GENESIS_HASH \
  --expected-shred-version ${EXPECTED_SHRED_VERSION} \
```
