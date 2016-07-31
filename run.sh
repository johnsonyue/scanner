#!/bin/bash

#get and dump latest bgp snapshot and get the target ip list.
cwd="target/"
target_file="ip_list_cn"
trace_ip_file="trace_ip_list"
node_name="hit.12"

echo "bgpdump -m \`python routeviews.py $cwd\` | python target.py "CN" $cwd $target_file";
bgpdump -m `python routeviews.py $cwd` | python target.py "CN" $cwd $target_file

#start scanning with scamper.
date=`date +%Y%m%d`
out_file=$cwd$date"."$node_name".warts"
out_file_alias=$cwd$date"."$node_name".alias.warts"

echo "scamper -c 'trace' -p 10000 -M $node_name -C "cycle-"$date -o $out_file -O warts -f $cwd$target_file"
scamper -c 'trace' -p 10000 -M $node_name -C "cycle-"$date -o $out_file -O warts -f $cwd$target_file

#alias resolution with scamper ally.
echo "sc_analysis_dump $out_file | python parser.py $cwd $trace_ip_file"
sc_analysis_dump $out_file | python parser.py $cwd $trace_ip_file

echo "scamper -c 'dealias -m ally' -p 10000 -M $node_name -C "cycle-"$date -o $out_file_alias -O warts -f $cwd$trace_ip_file"
scamper -c 'dealias -m ally' -p 10000 -M $node_name -C "cycle-"$date -o $out_file_alias -O warts -f $cwd$trace_ip_file
