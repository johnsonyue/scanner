#!/bin/bash

#get and dump latest bgp snapshot and get the target ip list.
cwd="target/"
target_file="ip_list_cn"

bgpdump -m `python routeviews.py $cwd` | python target.py "CN" $cwd $target_file

#start scanning with scamper.
scamper 
