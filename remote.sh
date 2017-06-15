#!/bin/bash
[ $# -ne 2 ] && echo './remote.sh $cwd $src_dir' && exit
cwd=$1

src_dir=$2
cd $src_dir

target_file=$(awk -F " *= *" '/target_file/ {print $2}' config.ini)
trace_ip_file=$(awk -F " *= *" '/trace_ip_file/ {print $2}' config.ini)
node_name=$(awk -F " *= *" '/node_name/ {print $2}' config.ini)

env_dir=$(awk -F " *= *" '/env_dir/ {print $2}' config.ini)
lookup_dir=$(awk -F " *= *" '/lookup_dir/ {print $2}' config.ini)
iffinder_path=$(awk -F " *= *" '/iffinder_path/ {print $2}' config.ini)
midar_path=$(awk -F " *= *" '/midar_path/ {print $2}' config.ini)
iffinder=$env_dir/$iffinder_path
midar=$env_dir/$midar_path
interface=$(awk -F " *= *" '/interface/ {print $2}' config.ini)
mper_port=$(awk -F " *= *" '/mper_port/ {print $2}' config.ini)

[ -d $cwd ] && exit 1
[ ! -d $cwd ] && echo "mkdir -p $cwd"
[ ! -d $cwd ] && mkdir -p $cwd
[ ! -d $lookup_dir ] && echo "mkdir -p $lookup_dir"
[ ! -d $lookup_dir ] && mkdir -p $lookup_dir

#get and dump latest bgp snapshot and get the target ip list.
echo "bgpdump -m \`python routeviews.py $lookup_dir\` | python target.py "CN" $lookup_dir $target_file";
bgpdump -m `python routeviews.py $lookup_dir` | python target.py "CN" $lookup_dir $target_file
cp $lookup_dir/$target_file $cwd/$target_file

#start scanning with scamper.
date=`date +%Y%m%d`
out_file=$cwd/$date"."$node_name".warts"

echo "scamper -c 'trace' -p 1000 -M $node_name -C $date -o $out_file -O warts -f $cwd/$target_file"
scamper -c 'trace' -p 1000 -M $node_name -C $date -o $out_file -O warts -f $cwd/$target_file
pwd=$(pwd)
cd $cwd
tar zcvf $target_file.tar.gz $target_file
tar zcvf $out_file.tar.gz $out_file
cd $pwd

#get trace ip for alias resolution.
echo "sc_analysis_dump $out_file | python parser.py $cwd $trace_ip_file"
sc_analysis_dump $out_file | python parser.py $cwd $trace_ip_file
pwd=$(pwd)
cd $cwd
tar zcvf $trace_ip_file.tar.gz $trace_ip_file
cd $pwd

#alias resolution with iffinder.
out_file_iffinder=$cwd/$date"."$node_name".iffinder"
kill `ps -ef | grep iffinder | awk '{print $2}'` >/dev/null 2>&1 #kill active iffinder.
echo "$iffinder -d -o $out_file_iffinder -c 100 -r 300 $cwd/$trace_ip_file"
$iffinder -d -o $out_file_iffinder -c 400 -r 1000 $cwd/$trace_ip_file
wait
pwd=$(pwd)
cd $cwd
ls "$cwd/*iffinder.*" | awk -F'/' '{print $NF}' | while read line; do tar zcvf $line.tar.gz $line; done
cd $pwd

#spawn finish flag.
touch $cwd/finish
