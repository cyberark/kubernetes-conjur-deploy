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

  if [ $PLATFORM = 'kubernetes' ]; then
    $cli create namespace "$CONJUR_NAMESPACE_NAME"
  else
    $cli new-project "$CONJUR_NAMESPACE_NAME"
  fi
  
  set_namespace $CONJUR_NAMESPACE_NAME
fi
