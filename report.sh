#!/bin/bash

source ~/.bash_profile

cd ~/simple-taiko-node

#docker compose safe
if command -v docker-compose &>/dev/null
then docker_compose="docker-compose"
elif docker --help | grep -q "compose"
then docker_compose="docker compose"
fi

l2proposeLast=$($docker_compose logs taiko_client_proposer | grep "Propose transactions succeeded" | tail -1 | awk 'match($0, /[0-9][0-9]-[0-9][0-9]\|[0-9][0-9]:[0-9][0-9]/) {print substr($0, RSTART, RLENGTH)}')
l2proveLast=$($docker_compose logs taiko_client_prover_relayer | grep "Your block proof was accepted" | tail -1 | awk 'match($0, /[0-9][0-9]-[0-9][0-9]\|[0-9][0-9]:[0-9][0-9]/) {print substr($0, RSTART, RLENGTH)}')
l2fee=$($docker_compose logs taiko_client_proposer | grep "proposer does not have enough tko balance" | tail -1 | awk -F 'fee: ' '{print $2}' | sed 's/"//' | awk '{print $1/100000000}')
l2proposeCount=$($docker_compose logs taiko_client_proposer | grep "Propose transactions succeeded" | wc -l)
#l2proveCount=$($docker_compose logs taiko_client_prover_relayer | grep "Your block proof was accepted" | wc -l)

temp1=$(curl -s POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest", false],"id":1}' localhost:8547 \
   | jq -r .result.number | sed 's/0x//')
if [ -z $temp1 ]; then l2height=0; else l2height=$(( 16#$temp1 )); fi

temp1=$(curl -s POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest", false],"id":1}' https://taiko-katla.blockpi.network/v1/rpc/public \
   | jq -r .result.number | sed 's/0x//')
if [ -z $temp1 ]; then l2netHeight=0; else l2netHeight=$(( 16#$temp1 )); fi
diffblock=$(($l2netHeight-$l2height))

docker_status=$(docker inspect simple-taiko-node_l2_execution_engine_1 | jq -r .[].State.Status)
chain=katla
id=taiko-$TAIKO_ID
bucket=node

if [ $diffblock -le 5 ]
  then 
    status="ok"
    message="proposed $l2proposeCount $l2proposeLast"
  else 
    status="warning"
    message="sync $l2height/$l2netHeight"; 
fi

if [ $l2netHeight -eq 0 ]
  then 
    status="warning"
    message="cannot fetch network height"
fi

if [ "$docker_status" -ne "running" ]
then 
  status="error"
  message="docker not running"
fi

cat << EOF
{
  "id":"$id",
  "machine":"$MACHINE",
  "chain":"$chain",
  "status":"$status",
  "message":"$message",
  "height":"$l2height",
  "netHeight":"$l2netHeight",
  "lastpropose":"$lastpropose",
  "updated":"$(date --utc +%FT%TZ)"
}
EOF

# send data to influxdb
if [ ! -z $INFLUX_HOST ]
then
 curl --request POST \
 "$INFLUX_HOST/api/v2/write?org=$INFLUX_ORG&bucket=$bucket&precision=ns" \
  --header "Authorization: Token $INFLUX_TOKEN" \
  --header "Content-Type: text/plain; charset=utf-8" \
  --header "Accept: application/json" \
  --data-binary "
    status,node=$id,machine=$MACHINE status=\"$status\",message=\"$message\",version=\"$version\",url=\"$url\",chain=\"$chain\" $(date +%s%N) 
    "
fi
