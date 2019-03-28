#!/bin/bash
set -euo pipefail

if [[ ! "${CONJUR_SEED_FILE_URL}" =~ ^http[s]?:// ]]; then
    echo "WARN: Seed URL not found - assuming seedfile exists on the follower!"
    exit 0
fi

if [[ "${CONJUR_SEED_FILE_URL}" =~ ^https:// ]] && [[ ! -f "${MASTER_SSL_CERT_PATH}" ]]; then
    echo "ERR: Master ssl cert not found at $MASTER_SSL_CERT_PATH!"
    exit 1
fi

echo "Trying to fetch seedfile from $CONJUR_SEED_FILE_URL..."
echo "Hostname is --- $FOLLOWER_HOSTNAME ---"

WGET_CERT_ARGS=()
if [[ "${CONJUR_SEED_FILE_URL}" =~ ^https:// ]]; then
    echo "Using master ssl cert from ${MASTER_SSL_CERT_PATH}"
    WGET_CERT_ARGS=( "--ca-certificate" "${MASTER_SSL_CERT_PATH}" )
fi

# Follower hostname should be changed to be alt names
wget --post-data "follower_hostname=$FOLLOWER_HOSTNAME.$MY_POD_NAMESPACE.svc.cluster.local" \
     "${WGET_CERT_ARGS[@]}" \
     -O "$SEEDFILE_DIR/follower-seed.tar" \
     "$CONJUR_SEED_FILE_URL"
cp /usr/bin/start-follower.sh $SEEDFILE_DIR

echo "Seedfile downloaded!"