#!/bin/bash

cd ~
git clone https://github.com/taikoxyz/simple-taiko-node.git
cd simple-taiko-node
cp .env.sample .env
nano .env

if [ -f ~/scripts/taiko/config/env ] 
then
  echo "Config file found."
else
  echo "Config file not found, creating one."
  cp ~/scripts/taiko/config/env.sample ~/scripts/taiko/config/env
fi
