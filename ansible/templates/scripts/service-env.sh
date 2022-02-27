RESTART={{ restart }} # Update the below block before uncommenting
if [[ "$RESTART" = true ]]; then
        WAIT_FOR_SUPERMAJORITY={{ wait_for_supermajority }}
        EXPECTED_BANK_HASH={{ expected_bank_hash }}
        HARD_FORKS={{ hard_fork }}
fi

EXPECTED_SHRED_VERSION={{ expected_shred_version }}
EXPECTED_GENESIS_HASH={{ genesis_hash }}
export SOLANA_METRICS_CONFIG={{ metrics_config }}
PATH={{ path }}
RPC_URL={{ rpc_url }}
ENTRYPOINT_HOST={{ entrypoint_host }}
ENTRYPOINT_PORT={{ entrypoint_port }}
ENTRYPOINT={{ entrypoint }}
ENTRYPOINTS=({{ entrypoints }})
TRUSTED_VALIDATOR_PUBKEYS=({{ trusted_validators }})

ENABLE_ACCOUNT_INDEXES={{ enable_account_indexes }}
if [[ "$ENABLE_ACCOUNT_INDEXES" = true ]]; then
        ACCOUNT_INDEXES=({{ account_indexes }})
fi

ENABLE_EXCLUDE_KEYS={{ enable_exclude_keys }}
if [[ "$ENABLE_EXCLUDE_KEYS" = true ]]; then
	EXCLUDE_KEYS=({{ index_exclude_keys }})
fi
	
export RUST_BACKTRACE={{ rust_backtrace }}
export RUST_LOG={{ rust_log }}

ENABLE_BIGTABLE={{ enable_bigtable }}
if [[ "$ENABLE_BIGTABLE" = true ]]; then
	export GOOGLE_APPLICATION_CREDENTIALS={{ bigtable_credentials_path }}
fi

ENABLE_BPF_JIT={{ enable_bpf_jit }}
DISABLE_ACCOUNTSDB_CACHE={{ disable_accountsdb_cache }}
ENABLE_CPI_AND_LOG_STORAGE={{ enable_cpi_and_log_storage }}
DISABLE_ACCOUNTS_DB_INDEX_HASHING={{ disable_accounts_db_index_hashing }}

ENABLE_RAYON_HACK={{ enable_rayon_hack }}
if [[ "$ENABLE_RAYON_HACK" = true ]]; then
	export SOLANA_RAYON_THREADS={{ rayon_threads }}
fi

ENABLE_SYNTH_ALERT={{ enable_synth_alert }}
if [[ "$ENABLE_SYNTH_ALERT" = true ]]; then
	export SYNTH_SLACK_WEBHOOK={{ synth_slack_webhook }}
fi 
#Exlclusive for warehouse nodes
STORAGE_BUCKET={{ storage_bucket }}
