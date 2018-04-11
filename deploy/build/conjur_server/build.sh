#!/bin/bash
set -eou pipefail

# builds Conjur Appliance with /etc/conjur.json (contains memory allocation config for pg)
docker build -t conjur-appliance:$CONJUR_PROJECT_NAME -f Dockerfile .
