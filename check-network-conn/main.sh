#!/bin/sh

log() {
	echo "[$(date -R)] $1"
}

capture_last_network_manager_logs() {
	logs=$(journalctl -u NetworkManager --since "5 minutes ago")
	echo "$logs"
}

check_connection() {
	ping -c 1 8.8.8.8 >/dev/null 2>&1
	return $?
}

evaluate_conn_recover() {
	if [ "$1" = "0" ]; then
		return 1
	fi

	log "Evaluating network recovery, $1 attempt(s) left..."

	if check_connection; then
		return 0
	fi

	sleep "$2"

	evaluate_conn_recover $(($1 - 1)) "$2"
}

while true; do
	if ! check_connection; then
		log "I've lost network connection, trying again..."
		if ! evaluate_conn_recover 5 3; then
			log "Definitely lost network connection"
			break
		fi

		log "Connection recovered"
	else
		log "I didn't lost connection yet"
	fi

	sleep 2
done

notify-send "You've lost network connection" "Check your terminal to see the logs" -a "Check network connection script" -u critical

capture_last_network_manager_logs
