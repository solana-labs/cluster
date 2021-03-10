#/bin/bash
currenttime=`date +"%d-%b-%Y %H:%M:%S"`
logfile=`date +"%d-%b-%Y"`_log.log
echo "================= $currenttime"  >> $logfile
max_slot_distance=1500
CLUSTERSLOT=$(solana slot -u http://10.142.0.4:8899)
node_slot=$(solana slot -u http://127.0.0.1:8899)
DIFFSLOT=$(($CLUSTERSLOT-$NODESLOT))
echo "Cluster Slot:" $CLUSTERSLOT "Current Slot:" $NODESLOT "Difference in Slots:" $DIFFSLOT >> $logfile
if [[ $DIFFSLOT -gt $RMLEDGER ]]; then
        cd ~
        ./stop
        rm -rf ledger/
        ./restart
        echo "Node was:" $DIFFSLOT " slots behind, Services has been stopped, ledger deleted and service restarted" >> $logfile
else
        echo "Node was:" $DIFFSLOT " slots behind, so no operation performed" >> $logfile
fi
