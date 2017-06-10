set_state(){
	date=$1
	state=$2
	if [ -z "$(grep $date state)" ]; then
		echo $date" "$state >>state
	else
		sed -i "s/^$date.*/$date $state/g" state
	fi
}

get_state(){
	date=$1
	grep $date state | cut -d' ' -f2
}

while true; do
	date=$(date +%Y%m%d-%H%M)
	cwd=$(awk -F " *= *" '/cwd/ {print $2}' config.ini | sed "s/\/$//g" | sed "s/[^/]*$//g")
	cwd=$(echo "$cwd" | sed -e "s/\//\\\\\//g")$date"\/"
	echo "> set_state $date remote"
	set_state $date remote
	sed -i "s/^cwd.*/cwd = $cwd/g" config.ini
	echo "> nohup ./local.sh >$date".log" 2>&1 &"
	nohup ./local.sh >$date".log" 2>&1 &
	
	while true; do
		[ "$(get_state $date)" == "local" ] && break
		sleep 200
done

