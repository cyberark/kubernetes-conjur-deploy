#!/bin/bash
set -euo pipefail

if [[ ! "${CONJUR_SEED_FILE_URL}" =~ ^http[s]?:// ]]; then
    echo "WARN: Seed URL not found - assuming seedfile exists on the follower!"
    exit 0
fi

echo "Trying to fetch seedfile from $CONJUR_SEED_FILE_URL..."
echo "Hostname is --- $FOLLOWER_HOSTNAME ---"

# TODO: remove the insecure request
wget --post-data "follower_hostname=$FOLLOWER_HOSTNAME" \
     --no-check-certificate \
     -O "$SEEDFILE_DIR/follower-seed.tar" \
     "$CONJUR_SEED_FILE_URL"
cp /usr/bin/start-follower.sh $SEEDFILE_DIR

echo "Seedfile downloaded!"