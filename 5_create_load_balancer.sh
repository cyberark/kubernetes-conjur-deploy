#!/bin/bash
set -euo pipefail

. utils.sh

announce "Creating load balancer for master and standbys."

set_namespace $CONJUR_NAMESPACE_NAME

$cli create -f "./$PLATFORM/conjur-ext-service.yaml"

echo "Load balancer created and configured."
