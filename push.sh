for device in "kindle01" "kindle02"; do
	scp run_screensaver.sh root@$device:
	ssh root@$device chmod +x run_screensaver.sh
done
