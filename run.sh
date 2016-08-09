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

[ ! -d $cwd ] && echo "mkdir -p $cwd"
[ ! -d $cwd ] && mkdir -p $cwd

#get and dump latest bgp snapshot and get the target ip list.
echo "bgpdump -m \`python routeviews.py $cwd\` | python target.py "CN" $cwd $target_file";
bgpdump -m `python routeviews.py $cwd` | python target.py "CN" $cwd $target_file

#start scanning with scamper.
date=`date +%Y%m%d`
out_file=$cwd/$date"."$node_name".warts"

echo "scamper -c 'trace' -p 10000 -M $node_name -C $date -o $out_file -O warts -f $cwd/$target_file"
scamper -c 'trace' -p 10000 -M $node_name -C $date -o $out_file -O warts -f $cwd/$target_file

#get trace ip for alias resolution.
echo "sc_analysis_dump $out_file | python parser.py $cwd $trace_ip_file"
sc_analysis_dump $out_file | python parser.py $cwd $trace_ip_file

#alias resolution with iffinder.
out_file_iffinder=$cwd/$date"."$node_name".iffinder"
kill `ps -ef | grep iffinder | awk '{print $2}'` >/dev/null 2>&1 #kill active iffinder.
echo "$iffinder -d -o $out_file_iffinder -c 100 -r 300 $cwd/$trace_ip_file"
$iffinder -d -o $out_file_iffinder -c 100 -r 300 $cwd/$trace_ip_file

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
mper -p 100 -D $mper_port -G $gateway -I $interface & #run mper probing engine.

echo "kill \`ps -ef | grep midar-full | awk '{print \$2}'\` >/dev/null 2>&1"
kill `ps -ef | grep midar-full | awk '{print $2}'` >/dev/null 2>&1 #kill active midar-full.

[ -d $cwd/run-$date ] && echo "rm -rf $cwd/run-$date"
[ -d $cwd/run-$date.run ] && rm -rf $cwd/run-$date #delete pre-existing file.
echo "$midar --autostep --run-id=$date --dir=$cwd --mper-pps=100 --targets=$cwd/$trace_ip_file start"
$midar --autostep --run-id=$date --dir=$cwd --mper-port=$mper_port --mper-pps=100 --targets=$cwd/$trace_ip_file start
