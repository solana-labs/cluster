RESTART=false # Update the below block before uncommenting
if [[ "$RESTART" = true ]]; then
        WAIT_FOR_SUPERMAJORITY=96542804
        EXPECTED_BANK_HASH=5x6cLLsvsEbgbQxQNPoT1LvbTfYrx22kpXyzRxLKAMN3
        HARD_FORKS=96542805
fi

EXPECTED_SHRED_VERSION=8573
EXPECTED_GENESIS_HASH=5eykt4UsFv8P8NJdTREpY1vzqKqZKvdpKuc147dw2N9d
export SOLANA_METRICS_CONFIG=host=https://metrics.solana.com:8086,db=mainnet-beta,u=mainnet-beta_write,p=password
PATH=/home/sol/.local/share/solana/install/active_release/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin
RPC_URL=https://api.mainnet-beta.solana.com
ENTRYPOINT_HOST=mainnet-beta.solana.com
ENTRYPOINT_PORT=8001
ENTRYPOINT=mainnet-beta.solana.com:8001
ENTRYPOINTS=(entrypoint.mainnet-beta.solana.com:8001 entrypoint2.mainnet-beta.solana.com:8001 entrypoint3.mainnet-beta.solana.com:8001 entrypoint4.mainnet-beta.solana.com:8001 entrypoint5.mainnet-beta.solana.com:8001)
TRUSTED_VALIDATOR_PUBKEYS=(7Np41oeYqPefeNQEHSv1UDhYrehxin3NStELsSKCT4K2 GdnSyH3YtwcxFvQrVVJMm1JhTS4QVX7MFsX56uJLUfiZ DE1bawNcRJB9rVm3buyMVfr8mBEoyyu73NBovf2oXJsJ CakcnaRDHka2gXyfbEd2d3xsvkJkqsLw2akB3zsN1D2S)

ENABLE_ACCOUNT_INDEXES=true
if [[ "$ENABLE_ACCOUNT_INDEXES" = true ]]; then
        ACCOUNT_INDEXES=(program-id spl-token-owner spl-token-mint)
fi

ENABLE_EXCLUDE_KEYS=true
if [[ "$ENABLE_EXCLUDE_KEYS" = true ]]; then
	EXCLUDE_KEYS=(kinXdEcpDQeHPEuQnqmUgtYykqKGVFq6CeVX5iAHJq6 TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA)
fi
	
export RUST_BACKTRACE=1
export RUST_LOG=info,solana_runtime::bank::executor_cache=trace

ENABLE_BIGTABLE=true
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
