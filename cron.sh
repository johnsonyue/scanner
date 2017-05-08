#!/bin/bash
#e.g.
#./cron.sh 8.8.8.8 password_here "/home/*.warts" .
[ $# -ne 4 ] && echo './cron.sh $ip $password $src_path $dst_dir' && exit
ip=$1
password=$2
src_path=$3
dst_dir=$4

fetch(){
	url=$1
	src_dir=$(echo $url | awk -F'/' '{sub($NF,"",$0); print $0}')
	file=$(echo $url | awk -F '/' '{print $NF}' | tr -d '\r')
	dst_dir=$2
	cmd="ssh root@$ip \\\"tar zcf - -C $src_dir $file\\\" | pv | tar zxv -C $dst_dir"
	expect -c "set timeout -1
	spawn bash -c \"$cmd\"
	expect -re \".*password.*\" {send \"$password\r\"}
	expect eof"
}

cnt=0
expect -c "spawn ssh root@$ip \"ls $src_path\"
expect -re \".*password.*\" {send \"$password\r\"}
expect eof" | while read line; do let cnt=cnt+1; [ $cnt -gt 2 ] && fetch $line $dst_dir; done
