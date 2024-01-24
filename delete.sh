#!/bin.bash

read -p "This action will wipe current installation, are you sure? " sure
case $sure in 
 y|Y) ;;
 *) exit 1 ;;
esac

bash ~/scripts/taiko/stop.sh
docker volume rm $(docker volume ls -q | grep taiko)
rm -r ~/simple-taiko-node
rm -r ~/scripts/taiko
