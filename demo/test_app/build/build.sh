#!/bin/bash
set -eou pipefail

docker build -t test-app:$CONJUR_NAMESPACE_NAME .
