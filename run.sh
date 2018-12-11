#!/bin/bash
cd `dirname $0`
eval $(ps -ef | grep "[0-9] python server_2\\.py m" | awk '{print "kill "$2}')
ulimit -n 512000
nohup python /data/shadowsocks/server_2.py>> /dev/null 2>&1 &

