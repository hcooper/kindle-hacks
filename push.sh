for device in "kindle1" "kindle2"; do
	scp run_screensaver.sh root@$device:
	ssh root@$device chmod +x run_screensaver.sh
done
