RESTART=false # Update the below block before uncommenting
if [[ "$RESTART" = true ]]; then
        WAIT_FOR_SUPERMAJORITY=0
        EXPECTED_BANK_HASH=74vc9eZcqavjLQYohoi3vGjrXtMCsNQCwTwUU77ZGgvL
        HARD_FORKS=0
fi

EXPECTED_SHRED_VERSION=23305
EXPECTED_GENESIS_HASH=EtWTRABZaYq6iMfeYKouRu166VU2xqa1wcaWoxPkrZBG
export SOLANA_METRICS_CONFIG=host=https://metrics.solana.com:8086,db=devnet,u=scratch_writer,p=topsecret
PATH=/home/sol/.local/share/solana/install/active_release/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin
RPC_URL=http://api.devnet.solana.com/
ENTRYPOINT_HOST=devnet.solana.com
ENTRYPOINT_PORT=8001
ENTRYPOINT=entrypoint.devnet.solana.com:8001
ENTRYPOINTS=(entrypoint.devnet.solana.com:8001 entrypoint2.devnet.solana.com:8001 entrypoint3.devnet.solana.com:8001 35.197.53.105:8001)
TRUSTED_VALIDATOR_PUBKEYS=(dv2eQHeP4RFrJZ6UeiZWoc3XTtmtZCUKxxCApCDcRNV dv3qDFk1DTF36Z62bNvrCXe9sKATA6xvVy6A798xxAS dv1ZAGvdsz5hHLwWXsVnM94hWf1pjbKVau1QVkaMJ92 dv4ACNkpYPcE3aKmYDqZm9G5EB3J4MRoeE7WNDRBVJB)

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
	export GOOGLE_APPLICATION_CREDENTIALS=<patht_to_credentials>
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
