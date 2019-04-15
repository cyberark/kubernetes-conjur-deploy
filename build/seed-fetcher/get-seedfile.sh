#!/bin/bash
set -euo pipefail

cp /usr/bin/start-follower.sh $SEEDFILE_DIR

if [[ ! "${CONJUR_SEED_FILE_URL}" =~ ^http[s]?:// ]]; then
    echo "WARN: Seed URL not found - assuming seedfile exists on the follower!"
    exit 0
fi

if [[ "${CONJUR_SEED_FILE_URL}" =~ ^https:// ]] && [[ "${CONJUR_SSL_CERTIFICATE}" = "" ]]; then
    echo "ERROR: CONJUR_SSL_CERTIFICATE not set!"
    exit 1
fi

MASTER_SSL_CERT_PATH="/tmp/master.crt"
TOKEN_PATH="/run/secrets/kubernetes.io/serviceaccount/token"

echo "Trying to fetch seedfile from $CONJUR_SEED_FILE_URL..."
echo "Hostname is --- $FOLLOWER_HOSTNAME ---"

MASTER_HOSTNAME=$(echo "${CONJUR_SEED_FILE_URL}" | cut -d'/' -f3)

WGET_CERT_ARGS=()

export CONJUR_APPLIANCE_URL="http://$MASTER_HOSTNAME"
if [[ "${CONJUR_SEED_FILE_URL}" =~ ^https:// ]]; then
    echo "$CONJUR_SSL_CERTIFICATE" > "$MASTER_SSL_CERT_PATH"
    export CONJUR_APPLIANCE_URL="https://$MASTER_HOSTNAME"

    echo "Using master ssl cert from ${MASTER_SSL_CERT_PATH}"
    WGET_CERT_ARGS=( "--ca-certificate" "${MASTER_SSL_CERT_PATH}" )
fi

export CONJUR_AUTHN_URL="$CONJUR_APPLIANCE_URL/authn-k8s/$AUTHENTICATOR_ID"

echo "Calculated vars:"
echo "- CONJUR_APPLIANCE_URL: $CONJUR_APPLIANCE_URL"
echo "- CONJUR_AUTHN_URL: $CONJUR_AUTHN_URL"
echo "- CONJUR_AUTHN_LOGIN: $CONJUR_AUTHN_LOGIN"
echo "- WGET_CERT_ARGS: $WGET_CERT_ARGS"
echo

echo "Running authenticator..."
/usr/bin/authenticator

echo "Parsing Conjur token..."
conjur_api_token=$(cat "/run/conjur/access-token" | base64 | tr -d '\r\n')

if [[ "${conjur_api_token}" == "" ]]; then
  echo "ERROR: API token is invalid (empty)!"
  exit 1
fi


# TODO: Follower hostname should be changed to be alt names
echo "Fetching seed file from $CONJUR_SEED_FILE_URL"
wget --post-data "follower_hostnames=$FOLLOWER_HOSTNAME.$MY_POD_NAMESPACE.svc.cluster.local" \
     --header "Authorization: Token token=\"$conjur_api_token\"" \
     "${WGET_CERT_ARGS[@]}" \
     -O "$SEEDFILE_DIR/follower-seed.tar" \
     "$CONJUR_SEED_FILE_URL"

echo "Seedfile downloaded!"