#!/usr/bin/env bash

LAMPORTS_PER_SOL=1000000000 # 1 billion
rpc_port=8899
display_summary=
display_details=

usage() {
  exitcode=0
  if [[ -n "$1" ]]; then
    exitcode=1
    echo "Error: $*"
  fi
  cat <<EOF
usage: $0 [cluster_rpc_url] [identity_pubkey] [options]

 Report the account addresses and balances of all stake accounts
 for which a given key is the authorized staker.
 Also report the system account balance for that same key.

 Required arguments:
   cluster_rpc_url      - RPC URL for a running Solana cluster (ex: http://34.83.146.144)
   identity_pubkey      - Base58 pubkey that is an authorized staker for at least one stake account on the cluster.

 Optional arguments:
   --rpc_port [port]    - Port on which to send RPC requests to cluster_rpc_url (default: $rpc_port)
   --display_summary    - If set, will print summed account balance totals to the console
   --display_details    - If set, will print a table of pubkeys and balances for each individual account

EOF
  exit $exitcode
}

function display_results_summary {
  stake_account_balance_total=0
  num_stake_accounts=0
  {
  read
  while IFS=, read -r program account_pubkey lamports lockup_epoch; do
    case $program in
      SYSTEM)
        system_account_balance=$lamports
        ;;
      STAKE)
        stake_account_balance_total=$((stake_account_balance_total + $lamports))
        num_stake_accounts=$((num_stake_accounts + 1))
        ;;
      *)
        echo "Unknown program: $program"
        exit 1
        ;;
    esac
  done
  } < "$results_file"

  stake_account_balance_total_sol="$(bc <<< "scale=3; $stake_account_balance_total/$LAMPORTS_PER_SOL")"
  system_account_balance_sol="$(bc <<< "scale=3; $system_account_balance/$LAMPORTS_PER_SOL")"

  all_account_total_balance="$(bc <<< "scale=3; $system_account_balance+$stake_account_balance_total")"
  all_account_total_balance_sol="$(bc <<< "scale=3; ($system_account_balance+$stake_account_balance_total)/$LAMPORTS_PER_SOL")"

  echo "--------------------------------------------------------------------------------------"
  echo "Summary of accounts owned by $system_account_pubkey"
  echo ""
  printf "Number of STAKE accounts: %'d\n" $num_stake_accounts
  printf "Balance of all STAKE accounts: %'d lamports\n" $stake_account_balance_total
  printf "Balance of all STAKE accounts: %'.3f SOL\n" $stake_account_balance_total_sol
  printf "\n"
  printf "Balance of SYSTEM account: %'d lamports\n" $system_account_balance
  printf "Balance of SYSTEM account: %'.3f SOL\n" $system_account_balance_sol
  printf "\n"
  printf "Total Balance of ALL accounts: %'d lamports\n" $all_account_total_balance
  printf "Total Balance of ALL accounts: %'.3f SOL\n" $all_account_total_balance_sol
  echo "--------------------------------------------------------------------------------------"
}

function display_results_details {
  echo "------------------------------------------------"
  cat $results_file | column -t -s,
  echo "------------------------------------------------"
}

rpc_url=$1
[[ -n $rpc_url ]] || usage
shift
system_account_pubkey=$1
[[ -n $system_account_pubkey ]] || usage
shift

while [[ -n $1 ]]; do
  if [[ ${1:0:2} = -- ]]; then
    if [[ $1 = --rpc_port ]]; then
      rpc_port="$2"
      shift 2
    elif [[ $1 = --display_summary ]]; then
      display_summary=true
      shift 1
    elif [[ $1 = --display_details ]]; then
      display_details=true
      shift 1
    else
      usage "Unknown option: $1"
    fi
  else
    usage "Unknown option: $1"
    shift
  fi
done

results_file=accounts_owned_by_${system_account_pubkey}.csv
echo "Program,Account_Pubkey,Lamports" > $results_file

system_account_lamports="$(curl -s -X POST -H "Content-Type: application/json" -d \
    '{"jsonrpc":"2.0","id":1, "method":"getAccountInfo", "params":["'$system_account_pubkey'"]}' $rpc_url:$rpc_port | jq -r '(.result | .value | .lamports)')"
  if [[ "$system_account_lamports" == "null" ]]; then
    echo "The provided pubkey is not found in the system program: $system_account_pubkey"
    exit 1
  fi
echo SYSTEM,$system_account_pubkey,$system_account_lamports >> $results_file

seed=0
while true; do
  stake_account_address="$(solana create-address-with-seed --from $system_account_pubkey $seed STAKE)"
  stake_account_lamports="$(curl -s -X POST -H "Content-Type: application/json" -d \
    '{"jsonrpc":"2.0","id":1, "method":"getAccountInfo", "params":["'$stake_account_address'"]}' $rpc_url:$rpc_port | jq -r '(.result | .value | .lamports)')"
  if [[ "$stake_account_lamports" == "null" ]]; then
    break
  fi
  echo STAKE,$stake_account_address,$stake_account_lamports >> $results_file
  seed=$(($seed + 1))
done
if [[ "$seed" == 0 ]]; then
    echo "No stake accounts were found that are authorized by the given pubkey: $system_account_pubkey"
fi

echo "Results written to: $results_file"
if [[ -n $display_details ]]; then
  display_results_details
fi
if [[ -n $display_summary ]]; then
  display_results_summary
fi