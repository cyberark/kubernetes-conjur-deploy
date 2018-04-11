#!/bin/bash
server_address=$3

conjur_ok=$(curl -k -s https://$server_address/health | jq '.ok')
if [[ "$conjur_ok" == "true" ]]; then
	exit 0
fi
exit -1
