#!/bin/bash
set -eou pipefail

docker build -t haproxy:$CONJUR_NAMESPACE_NAME .
