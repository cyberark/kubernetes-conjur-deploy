#!/bin/bash
set -eou pipefail

docker build -t haproxy:$CONJUR_PROJECT_NAME .
