

## Cluster Entrypoint Node
* DNS: mainnet.solana.com
* Static IP: 34.83.130.52
* GCE Resource Name: mainnet-solana-com
* OS Image: Ubuntu 18.04 LTS Minimal
* Boot disk: Standard disk, 10GB
* Machine type: n1-standard-1
* Region: us-west-1
* ssh: `gcloud --project solana-mainnet compute ssh mainnet-solana-com`

### Setup
```
$ ./setup-machine.sh mainnet-solana-com
```

### Monitoring
```
$ ./monitor-machine.sh mainnet-solana-com
```

### Software Upgrade
```
$ ./update-machine.sh mainnet-solana-com
```

## RPC Node
_TBD_

## Bootstrap Leader Node
_TBD_

## Warehouse Node
_TBD_

