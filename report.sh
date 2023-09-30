#!/bin/bash

source ~/scripts/taiko/config/env
cd ~/simple-taiko-node

#docker compose safe
if command -v docker-compose &>/dev/null
then docker_compose="docker-compose"
elif docker --help | grep -q "compose"
then docker_compose="docker compose"
fi

pid=$(ps aux | grep -E "geth --taiko" | grep -v grep | awk '{print $2}')

l2proposeLast=$($docker_compose logs taiko_client_proposer | grep "Propose transactions succeeded" | tail -1 | awk 'match($0, /[0-9][0-9]-[0-9][0-9]\|[0-9][0-9]:[0-9][0-9]/) {print substr($0, RSTART, RLENGTH)}')
l2proveLast=$($docker_compose logs taiko_client_prover_relayer | grep "Your block proof was accepted" | tail -1 | awk 'match($0, /[0-9][0-9]-[0-9][0-9]\|[0-9][0-9]:[0-9][0-9]/) {print substr($0, RSTART, RLENGTH)}')
l2fee=$($docker_compose logs taiko_client_proposer | grep "proposer does not have enough tko balance" | tail -1 | awk -F 'fee: ' '{print $2}' | sed 's/"//' | awk '{print $1/100000000}')
l2proposeCount=$($docker_compose logs taiko_client_proposer | grep "Propose transactions succeeded" | wc -l)
l2proveCount=$($docker_compose logs taiko_client_prover_relayer | grep "Your block proof was accepted" | wc -l)

temp1=$(curl -s POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest", false],"id":1}' localhost:8547 \
   | jq -r .result.number | sed 's/0x//')
if [ -z $temp1 ]; then l2height=0; else l2height=$(( 16#$temp1 )); fi

temp1=$(curl -s POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest", false],"id":1}' 43.130.29.245:8545 \
   | jq -r .result.number | sed 's/0x//')
if [ -z $temp1 ]; then l2netHeight=0; else l2netHeight=$(( 16#$temp1 )); fi
diffblock=$(($l2netHeight-$l2height))
foldersize=$(du -hs ~/simple-taiko-node | awk '{print $1}')

if [ $diffblock -le 5 ]
  then 
    status="ok"
    note="proved $l2proveCount $l2proveLast, proposed $l2proposeCount $l2proposeLast"
  else 
    status="warning"
    note="sync $l2height/$l2netHeight"; 
fi

if [ $l2netHeight -eq 0 ]
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
echo "lastpropose='$l2proposeLast'" 
echo "lastprove='$l2proveLast'" 
