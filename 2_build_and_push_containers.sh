#!/bin/bash
set -euo pipefail

. utils.sh

announce "Building and pushing haproxy image."

pushd build/haproxy
  ./build.sh
popd

docker_tag_and_push "haproxy"

echo "Docker images pushed."
