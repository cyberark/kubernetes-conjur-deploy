#!/bin/bash
set -euo pipefail

docker build -t seed-fetcher:$CONJUR_NAMESPACE_NAME .
