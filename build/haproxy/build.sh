#!/bin/bash
set -euo pipefail

docker build -t haproxy:$CONJUR_NAMESPACE_NAME .
