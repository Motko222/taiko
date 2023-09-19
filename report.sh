#!/bin/bash

source ~/scripts/taiko/config/env
cd ~/simple-taiko-node

#docker compose safe
if command -v docker-compose &>/dev/null
then docker_compose="docker-compose"
elif docker --help | grep -q "compose"
then docker_compose="docker compose"
fi

pid=$(pgrep 'geth')
last="never";prove="never"
l2propose=$($docker_compose logs taiko_client_proposer | grep "Propose transactions succeeded" | tail -1 | awk '{print $4}')
l2prove=$($docker_compose logs taiko_client_prover_relayer | grep "Your block proof was accepted" | tail -1 | awk '{print $4}')
l2fee=$($docker_compose logs taiko_client_proposer | grep "proposer does not have enough tko balance" | tail -1 | awk -F 'fee: ' '{print $2}' | sed 's/"//' | awk '{print $1/100000000}')

temp1=$(curl -s POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest", false],"id":1}' localhost:8547 \
   | jq -r .result.number | sed 's/0x//')
if [ -z $temp1 ]; then l2height=""; else l2height=$(( 16#$temp1 )); fi

temp1=$(curl -s POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest", false],"id":1}' 43.130.29.245:8545 \
   | jq -r .result.number | sed 's/0x//')
if [ -z $temp1 ]; then l2netHeight=""; else l2netHeight=$(( 16#$temp1 )); fi
diffblock=$(($l2netHeight-$l2height))
foldersize=$(du -hs ~/simple-taiko-node | awk '{print $1}')

if [ $diffblock -le 5 ]
  then 
    status="ok"
    note=""
  else 
    status="warning"
    note="sync $l2height/$l2netHeight"; 
fi

if [ -z $l2netHeight ]
  then 
    status="warning"
    note="cannot fetch network height"
fi

if [ -z $pid ]
then 
  status="error"
  note="not running"
fi

echo "updated='$(date +'%y-%m-%d %H:%M')'"
echo "version='$version'" 
echo "process='$pid'" 
echo "status=$status"
echo "height=$l2height"
echo "netHeight=$l2netHeight"
echo "note='$note'" 
echo "network='$network'" 
echo "type=$type"
echo "folder=$foldersize"
echo "id=$id"
echo "lastpropose='$l2propose'" 
echo "lastprove='$l2prove'" 
