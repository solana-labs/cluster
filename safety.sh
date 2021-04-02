#/bin/bash

set -e
currenttime=`date +"%d-%b-%Y %H:%M:%S"`
logfile=`date +"%d-%b-%Y"`_log.log
ref_ip=http://10.142.0.4:8899
echo "================= $currenttime"  >> $logfile
max_slot_distance=1500

#shellcheck source=/dev/null
source ~/service-env.sh

#shellcheck source=/dev/null
source /home/sol/bin/configure-metrics.sh

identity_keypair=~/api-identity.json
identity_pubkey=$(solana-keygen pubkey "$identity_keypair")

datapoint() {
    declare event=$1
    declare args=$2
    declare comma=
    if [[ -n $args ]]; then
        comma=,
    fi

  $metricsWriteDatapoint "safety-script,host_id=$identity_pubkey error=0,event=\"$event\"$comma$args"
}

reference_slot=$(solana slot -u $ref_ip)
node_slot=$(solana slot -u http://127.0.0.1:8899)
slot_distance=$(($reference_slot-$node_slot))
echo "Cluster Slot:" $reference_slot "Current Slot:" $node_slot "Difference in Slots:" $slot_distance >> $logfile
if [[ $slot_distance -gt $max_slot_distance ]]; then
    cd ~
    ./stop
    rm -rf ledger/
    ./restart
    echo "Node was:" $slot_distance " slots behind, Services has been stopped, ledger deleted and service restarted" >> $logfile
    datapoint slot-distance-failed "slot_dif=$slot_distance"
else
    echo "Node was:" $slot_distance " slots behind, so no operation performed" >> $logfile
    datapoint slot-distance-passed "slot_dif=$slot_distance"
fi
