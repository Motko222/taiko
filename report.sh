#!/bin/bash

source ~/scripts/taiko/config/env

pid=$(pgrep 'geth')
last="never";prove="never"
l2propose=$($docker_compose logs taiko_client_proposer | grep "Propose transactions succeeded" | tail -1 | awk '{print $4}')
l2prove=$($docker_compose logs taiko_client_prover_relayer | grep "Your block proof was accepted" | tail -1 | awk '{print $4}')
l2fee=$($docker_compose logs taiko_client_proposer | grep "proposer does not have enough tko balance" | tail -1 | awk -F 'fee: ' '{print $2}' | sed 's/"//' | awk '{print $1/100000000}')

temp1=$(curl -s POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest", false],"id":1}' localhost:8547 \
   | jq -r .result.number | sed 's/0x//')
if [ -z $temp1 ]; then l2height="err"; else l2height=$(( 16#$temp1 )); fi


if [ -z $pid ]; then status="error";note="not running"; else status="ok";note="h2=$l2height, f2=$l2fee"; fi
foldersize=$(du -hs $HOME/simple-taiko-node | awk '{print $1}')

echo "updated='$(date +'%y-%m-%d %H:%M')'"
echo "version='$version'" 
echo "process='$pid'" 
echo "status=$status"
echo "note='$note'" 
echo "network='$network'" 
echo "type=$type"
echo "folder=$foldersize"
echo "id=$id"
echo "lastpropose='$l2propose'" 
echo "lastprove='$l2prove'" 
