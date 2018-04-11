#!/bin/bash -e
set -eou pipefail

docker build -t test-app:$CONJUR_PROJECT_NAME .
