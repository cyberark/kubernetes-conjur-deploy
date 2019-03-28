#!/bin/bash

if [[ $# -lt 1 ]]; then
  echo "ERROR: Destination arg not specified!"
  echo "Usage: $0 <cert_dest>"
  exit 1
fi

if [[ ! "${FOLLOWER_SEED}" =~ ^https?:// ]]; then
    exit 0
fi

SERVER_CERT_DEST="$1"

echo "Extracting server domain"
HOSTNAME=$(echo "${FOLLOWER_SEED}" | cut -d'/' -f3)

echo "Saving cert from server ${HOSTNAME}:443 to ${SERVER_CERT_DEST}"
echo -n | openssl s_client -showcerts -connect $HOSTNAME:443 | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > $SERVER_CERT_DEST

echo "Server cert was saved."
