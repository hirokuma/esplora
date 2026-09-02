#!/bin/bash
WALLET_NAME="wallet"
AUTO_GENERATE=20

DOCKER_CONTAINER_NAME=esplora
DOCKER_IMAGE_NAME=esplora-hirokuma:latest
ELECTRUM_PORT=50001
HTTP_PORT=8094
RPC_PORT=48443
P2P_PORT=48444

function run_nodes() {
  docker run --name $DOCKER_CONTAINER_NAME \
           -p $ELECTRUM_PORT:50001 -p $HTTP_PORT:80 \
           -p $RPC_PORT:18443 -p $P2P_PORT:18444 \
           -d --rm -t $DOCKER_IMAGE_NAME \
           bash -c "/srv/explorer/run.sh bitcoin-regtest explorer"
}

function run_cmd() {
  result=$(docker exec $DOCKER_CONTAINER_NAME /bin/cli $@)
  echo $result | tr -d '\r'
}

if [[ $# == 0 ]]; then
  echo "Help:"
  echo "    $0 start: start bitcoin node and create wallet"
  echo "    $0 generate      : generatetoaddress 1"
  echo "    $0 generate <NUM>: generatetoaddress <NUM>"
  exit 1
elif [[ $# == 1 ]] && [[ "$1" == "start" ]]; then
  run_nodes
  sleep 5
  run_cmd createwallet "$WALLET_NAME"
  sleep 1
  addr=$(run_cmd getnewaddress)
  run_cmd generatetoaddress 101 "$addr"
  run_cmd getbalance
elif [[ $# == 1 ]] && [[ "$1" == "stop" ]]; then
  run_cmd stop
  sleep 1
  docker stop $DOCKER_CONTAINER_NAME
elif [[ $# == 1 ]] && [[ "$1" == "generate" ]]; then
  addr=$(run_cmd getnewaddress)
  run_cmd generatetoaddress 1 "$addr"
elif [[ $# -ge 2 ]] && [[ "$1" == "generate" ]]; then
  addr=$(run_cmd getnewaddress)
  if [[ "$2" == "auto" ]]; then
    if [[ $# -ge 3 ]]; then
      AUTO_GENERATE=$3
    fi
    while :; do
      run_cmd generatetoaddress 1 $addr
      sleep $AUTO_GENERATE
    done
  else
    run_cmd generatetoaddress $2 "$addr"
  fi
else
  run_cmd $@
fi
