#!/bin/bash
set -eou pipefail

docker build -t haproxy:$CONJUR_CONTEXT_NAME .
