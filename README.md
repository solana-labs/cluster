

## Cluster Entrypoint Node
* DNS: mainnet.solana.com
* Static IP: 34.83.130.52
* GCE Resource Name: mainnet-solana-com
* OS Image: Ubuntu 18.04 LTS Minimal
* Boot disk: Standard disk, 200GB
* Machine type: n1-standard-1
* Region: us-west-1
* ssh: `gcloud --project solana-mainnet compute ssh mainnet-solana-com`

### Create command

```bash
gcloud --project solana-mainnet compute instances create \
  mainnet-solana-com \
  --zone us-west1-b \
  --machine-type n1-standard-1 \
  --boot-disk-size=200GB \
  --tags solana-validator-minimal \
  --image ubuntu-minimal-1804-bionic-v20191113 --image-project ubuntu-os-cloud \
  --address mainnet-solana-com
```

then run:
```
./setup-machine.sh mainnet-solana-com
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
* DNS: api.mainnet.solana.com
* Static IP: 34.82.79.31
* GCE Resource Name: api.mainnet-solana-com
* OS Image: Ubuntu 18.04 LTS Minimal
* Boot disk: Standard disk, 2TB
* Machine type: n1-standard-8
* Region: us-west-1
* ssh: `gcloud --project solana-mainnet compute ssh api-mainnet-solana-com`

### Create command
```bash
gcloud --project solana-mainnet compute instances create \
  api-mainnet-solana-com \
  --zone us-west1-b \
  --machine-type n1-standard-8 \
  --boot-disk-size=2TB \
  --tags solana-validator-minimal,solana-validator-rpc \
  --image ubuntu-minimal-1804-bionic-v20191113 --image-project ubuntu-os-cloud \
  --address api-mainnet-solana-com
```

then run:
```
./setup-machine.sh api-mainnet-solana-com
```

## Bootstrap Leader Node
_TBD_

## Warehouse Node
_TBD_

