#!/bin/bash
set -euo pipefail

. utils.sh

announce "Creating Conjur namespace."

set_namespace default

if has_namespace "$CONJUR_NAMESPACE_NAME"; then
  echo "Namespace '$CONJUR_NAMESPACE_NAME' exists, not going to create it."
  set_namespace $CONJUR_NAMESPACE_NAME
else
  echo "Creating '$CONJUR_NAMESPACE_NAME' namespace."
  kubectl create namespace "$CONJUR_NAMESPACE_NAME"
  set_namespace $CONJUR_NAMESPACE_NAME
fi
