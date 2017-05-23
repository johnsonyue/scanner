#!/bin/bash

cwd=$(awk -F " *= *" '/cwd/ {print $2}' config.ini)
target_file=$(awk -F " *= *" '/target_file/ {print $2}' config.ini)
trace_ip_file=$(awk -F " *= *" '/trace_ip_file/ {print $2}' config.ini)
node_name=$(awk -F " *= *" '/node_name/ {print $2}' config.ini)

env_dir=$(awk -F " *= *" '/env_dir/ {print $2}' config.ini)
iffinder_path=$(awk -F " *= *" '/iffinder_path/ {print $2}' config.ini)
midar_path=$(awk -F " *= *" '/midar_path/ {print $2}' config.ini)
iffinder=$env_dir/$iffinder_path
midar=$env_dir/$midar_path
interface=$(awk -F " *= *" '/interface/ {print $2}' config.ini)
mper_port=$(awk -F " *= *" '/mper_port/ {print $2}' config.ini)

src_path=$(awk -F " *= *" '/src_path/ {print $2}' config.ini)
user=$(awk -F " *= *" '/user/ {print $2}' config.ini)
remote_ip=$(awk -F " *= *" '/remote_ip/ {print $2}' config.ini)
ssh_port=$(awk -F " *= *" '/ssh_port/ {print $2}' config.ini)
password=$(awk -F " *= *" '/password/ {print $2}' config.ini)

[ ! -d $cwd ] && echo "mkdir -p $cwd"
[ ! -d $cwd ] && mkdir -p $cwd

start_remote(){
	expect -c "set timeout -1
	spawn ssh $user@$remote_ip -p $ssh_port \"nohup $src_path/remote.sh $cwd >>$src_path/log 2>&1 &\"
	expect -re \".*password.*\" {send \"$password\r\"}
	expect eof"
}

sync_files(){
	user=$1
	remote_ip=$2
	ssh_port=$3
	password=$4

	expect -c "set timeout -1
	spawn rsync -avrt -e \"ssh -p $ssh_port\" root@$remote_ip:$cwd/*.sync $cwd
	expect -re \".*password.*\" {send \"$password\r\"}
	expect eof"
}

check_remote(){
	user=$1
	remote_ip=$2
	ssh_port=$3
	password=$4
	
	sync_files $user $remote_ip $ssh_port $password

	is_finished=0
	expect -c "set timeout -1
	spawn ssh $user@$remote_ip -p $ssh_port \"ls $cwd\"
	expect -re \".*password.*\" {send \"$password\r\"}
	expect eof" | while read line; do [ "$line" == "finish" ] && is_finished=1; [ ! -z $(echo $line | grep "warts") ] && date=$(echo $line | awk -F'.' '{print $1}'); done

	if [ $is_finished -eq 1 ]; then
		echo $date
	else
		echo ""
	fi
}

echo "> start_remote $user $remote_ip $ssh_port $password"
start_remote $user $remote_ip $ssh_port $password
while true; do
	start_ts=$(date +%s)
	echo "> check_remote $user $remote_ip $ssh_port $password"
	date=$(check_remote $user $remote_ip $ssh_port $password | tail -n 1)
	end_ts=$(date +%s)
	time_used=$((end_ts-start_ts))
	echo "time used: $time_used"
	[ ! -z $date"" ] && break
	[ $time_used -lt 200 ] && echo "> sleep $((200-time_used))" && sleep $((200-time_used)) #check remote every five minutes.
done

exit

#alias resolution with midar-full.
out_file_midar=$cwd/$date"."$node_name".midar"
echo "gateway=\`route -n | awk '{if ($1=="0.0.0.0" || $1=="default") {print $0}}' | awk '{print $2}'\`" #get gateway address by route
gateway=`route -n | awk '{if ($1=="0.0.0.0" || $1=="default") {print $0}}' | awk '{print $2}'` #get gateway address by route

echo "kill \`ps -ef | grep ping | awk '{print \$2}'\` >/dev/null 2>&1"
kill `ps -ef | grep ping | awk '{print $2}'` >/dev/null 2>&1 #kill active ping.
echo "nohup ping $gateway -i 45 >/dev/null 2>&1 &"
nohup ping $gateway -i 45 >/dev/null 2>&1 & #to refresh arp cache of the gateway address

echo "kill \`ps -ef | grep mper | awk '{print \$2}'\` >/dev/null 2>&1"
kill `ps -ef | grep mper | awk '{print $2}'` >/dev/null 2>&1 #kill active mper.
echo "mper -p 100 -D $mper_port -G $gateway -I $interface &"
mper -p 1000 -D $mper_port -G $gateway -I $interface & #run mper probing engine.

echo "kill \`ps -ef | grep midar-full | awk '{print \$2}'\` >/dev/null 2>&1"
kill `ps -ef | grep midar-full | awk '{print $2}'` >/dev/null 2>&1 #kill active midar-full.

[ -d $cwd/run-$date ] && echo "rm -rf $cwd/run-$date"
[ -d $cwd/run-$date ] && rm -rf $cwd/run-$date #delete pre-existing file.
echo "$midar --autostep --run-id=$date --dir=$cwd --mper-pps=100 --targets=$cwd/$trace_ip_file start"
#$midar --autostep --run-id=$date --dir=$cwd --mper-port=$mper_port --mper-pps=1000 --targets=$cwd/$trace_ip_file start
$midar --autostep --run-id=$date --dir=$cwd --mper-port=$mper_port --mper-pps=100 --targets=$cwd/$trace_ip_file start #debug
