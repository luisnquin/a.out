#!/bin/sh

check_connection() {
	ping -c 1 8.8.8.8 >/dev/null 2>&1
	return $?
}

capture_last_network_manager_logs() {
	logs=$(journalctl -u NetworkManager --since "5 minutes ago")
	echo "$logs"
}

while true; do
	if ! check_connection; then
		echo "No network connection"

		break
	else
		echo "[$(date -R)] I didn't lost connection yet"
	fi

	sleep 2
done

echo "[$(date -R)] I've lost network connection"

notify-send "You've lost network connection" "Check your terminal to see the logs" -a "Check network connection script" -u critical

capture_last_network_manager_logs
