RESTART=false # Update the below block before uncommenting
if [[ "$RESTART" = true ]]; then
        WAIT_FOR_SUPERMAJORITY=110973418
        EXPECTED_BANK_HASH=WVDsuJJbhcdqH6vQrpZi5GYoPnMAaKw4THMtwes77DS
        HARD_FORKS=0
fi

EXPECTED_SHRED_VERSION=12339
EXPECTED_GENESIS_HASH=4uhcVJyU9pJkvQyS88uRDiswHXSCkY3zQawwpjk2NsNY
export SOLANA_METRICS_CONFIG=host=http://35.222.139.230:8086,db=tds,u=testnet_write,p=c4fa841aa918bf8274e3e2a44d77568d9861b3ea
PATH=/home/sol/.local/share/solana/install/active_release/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin
RPC_URL=https://api.testnet.solana.com/
ENTRYPOINT_HOST=entrypoint.testnet.solana.com
ENTRYPOINT_PORT=8001
ENTRYPOINT=entrypoint.testnet.solana.com:8001
ENTRYPOINTS=(entrypoint2.testnet.solana.com:8001 entrypoint3.testnet.solana.com:8001)
TRUSTED_VALIDATOR_PUBKEYS=(eoKpUABi59aT4rR9HGS3LcMecfut9x7zJyodWWP43YQ 9YVpEeZf8uBoUtzCFC6SSFDDqPt16uKFubNhLvGxeUDy 4958nAd4Gp1MZQEg97b7prdDKAgC5Ab3iQtNzAWyHqEV 4jhyvbBHbsRDF6och7pDQ7ahYTUr7wNkAYJTLLuMUtku D2ULkLgZk1d6RW3Wmd14vFNfkBgi6NMM8CDNsNuNXvfV Bszp6hDL19ymPZ8efp9venQYb4ae2rRmEtVp4aG6k8nx)

ENABLE_ACCOUNT_INDEXES=false
if [[ "$ENABLE_ACCOUNT_INDEXES" = true ]]; then
        ACCOUNT_INDEXES=(program-id spl-token-owner spl-token-mint)
fi

ENABLE_EXCLUDE_KEYS=false
if [[ "$ENABLE_EXCLUDE_KEYS" = true ]]; then
	EXCLUDE_KEYS=(kinXdEcpDQeHPEuQnqmUgtYykqKGVFq6CeVX5iAHJq6 TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA)
fi
	
export RUST_BACKTRACE=1
export RUST_LOG=info,solana_runtime::bank::executor_cache=trace

ENABLE_BIGTABLE=false
if [[ "$ENABLE_BIGTABLE" = true ]]; then
	export GOOGLE_APPLICATION_CREDENTIALS=<path_to_credentials>
fi

ENABLE_BPF_JIT=false
DISABLE_ACCOUNTSDB_CACHE=false
ENABLE_CPI_AND_LOG_STORAGE=false
DISABLE_ACCOUNTS_DB_INDEX_HASHING=false

ENABLE_RAYON_HACK=false
if [[ "$ENABLE_RAYON_HACK" = true ]]; then
	export SOLANA_RAYON_THREADS=8
fi

ENABLE_SYNTH_ALERT=false
if [[ "$ENABLE_SYNTH_ALERT" = true ]]; then
	export SYNTH_SLACK_WEBHOOK=<webhook>
fi 
#Exlclusive for warehouse nodes
STORAGE_BUCKET=<bucket>
