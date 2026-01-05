#!/bin/bash 
set -euo pipefail

. utils.sh

: "${SEEDFETCHER_IMAGE:=cyberark/dap-seedfetcher}"
: "${SEEDFETCHER_TAG:=edge}"

kind_load_image() {
  local image="$1"
  local cluster_name="${KIND_CLUSTER_NAME:-kind}"
  
  echo "Loading image ${image} into kind cluster..."

  # Primary path: use kind's built-in loader
  if kind load docker-image "$image" --name "$cluster_name"; then
    return 0
  fi

  # Fallback path: manually import into the node's containerd.
  # Workaround for occasional KinD load failures like:
  #   ctr: content digest sha256:...: not found
  # which can happen when kind invokes ctr with --all-platforms.
  local control_plane_container="${cluster_name}-control-plane"
  echo "kind load failed; retrying via ctr import into ${control_plane_container}..."
  if ! docker inspect "${control_plane_container}" >/dev/null 2>&1; then
    echo "ERROR: Could not find KinD control-plane container ${control_plane_container}"
    return 1
  fi

  docker save "${image}" | \
    docker exec --privileged -i "${control_plane_container}" \
      ctr --namespace=k8s.io images import --digests --snapshotter=overlayfs -
}

main() {
  if [[ "${PLATFORM}" = "openshift" ]]; then
    set +x
    docker login -u _ -p $(oc whoami -t) $DOCKER_REGISTRY_PATH
    set -x
  fi

  if [[ $CONJUR_DEPLOYMENT == oss ]]; then
    echo "Prepare Conjur OSS cluster"
    prepare_conjur_oss_cluster
  else
    echo "Prepare DAP cluster"
    prepare_conjur_appliance_image
    prepare_seed_fetcher_image
  fi

  if [[ "${DEPLOY_MASTER_CLUSTER}" = "true" ]]; then
    prepare_conjur_cli_image
  fi

  echo "Docker images pushed."
}

prepare_conjur_appliance_image() {
  announce "Tagging and pushing Conjur appliance"

  conjur_appliance_image=$(platform_image conjur-appliance)
  docker tag $CONJUR_APPLIANCE_IMAGE $conjur_appliance_image

  if [ "${KIND}" = "true" ]; then
    kind_load_image $conjur_appliance_image
  elif [ ! is_minienv ] || [ "${DEV}" = "false" ] ; then
    docker push $conjur_appliance_image
  fi
}

prepare_conjur_cli_image() {
  announce "Pulling and pushing Conjur CLI image."

  if [ "${KIND}" = "true" ]; then
    # For KIND, skip retagging/preloading - let Kind pull images directly
    # This avoids multi-platform manifest issues with kind load
    echo "KIND mode: skipping conjur-cli and alpine image preparation (Kind will pull directly)"
    return 0
  fi

  docker pull cyberark/conjur-cli:8
  docker pull alpine:latest
  
  docker tag cyberark/conjur-cli:8 conjur-cli:$CONJUR_NAMESPACE_NAME
  docker tag alpine:latest alpine:$CONJUR_NAMESPACE_NAME

  cli_app_image=$(platform_image conjur-cli)
  docker tag conjur-cli:$CONJUR_NAMESPACE_NAME $cli_app_image

  alpine_image=$(platform_image alpine)
  docker tag alpine:$CONJUR_NAMESPACE_NAME $alpine_image

  if [ ! is_minienv ] || [ "${DEV}" = "false" ]; then
    docker push $cli_app_image
    docker push $alpine_image
  fi
}

prepare_seed_fetcher_image() {
  announce "Pulling and pushing seed-fetcher image."

  if [ "${KIND}" = "true" ]; then
    # Pull single-platform image for KIND to avoid multi-platform manifest issues
    docker pull --platform linux/amd64 "${SEEDFETCHER_IMAGE}:${SEEDFETCHER_TAG}"
  else
    docker pull "${SEEDFETCHER_IMAGE}:${SEEDFETCHER_TAG}"
  fi

  seedfetcher_image=$(platform_image seed-fetcher)
  docker tag "${SEEDFETCHER_IMAGE}:${SEEDFETCHER_TAG}" ${seedfetcher_image}

  if [ "${KIND}" = "true" ]; then
    kind_load_image $seedfetcher_image
  elif [ ! is_minienv ] || [ "${DEV}" = "false" ]; then
    docker push $seedfetcher_image
  fi
}

prepare_conjur_oss_cluster() {
  announce "Pulling and pushing Conjur OSS image."

  if [ "${KIND}" = "true" ]; then
    # For KIND, skip retagging/preloading for images we don't build
    # Kind will pull cyberark/conjur:latest directly
    echo "KIND mode: skipping Conjur OSS image preparation (Kind will pull directly)"
  else
    # Allow using local conjur images for deployment
    conjur_oss_src_image="${LOCAL_CONJUR_IMAGE:-}"
    if [[ -z "$conjur_oss_src_image" ]]; then
      conjur_oss_src_image="cyberark/conjur:latest"
      docker pull $conjur_oss_src_image
    fi

    conjur_oss_dest_image=$(platform_image "conjur")
    echo "Tagging Conjur image $conjur_oss_src_image as $conjur_oss_dest_image"
    docker tag "$conjur_oss_src_image" "$conjur_oss_dest_image"

    if [ "${DEV}" = "false" ]; then
      echo "Pushing Conjur image ${conjur_oss_dest_image} to repo..."
      docker push "$conjur_oss_dest_image"
    fi
  fi

  announce "Pulling and pushing postgres image"
  
  if [ "${KIND}" = "true" ]; then
    # For KIND, skip retagging/preloading - Kind will pull postgres:15 directly
    echo "KIND mode: skipping postgres image preparation (Kind will pull directly)"
  else
    postgres_src_image="postgres:15"
    postgres_dest_image=$(platform_image "postgres")
    
    docker pull "$postgres_src_image"
    docker tag "$postgres_src_image" "$postgres_dest_image"
    
    if [ "${DEV}" = "false" ]; then
      docker push "$postgres_dest_image"
    fi
  fi

  announce "Pulling and pushing Nginx image."

  nginx_image=$(platform_image "nginx")
  # Push nginx image to openshift repo
  pushd oss/nginx_base
    sed -i -e "s#{{ CONJUR_NAMESPACE_NAME }}#$CONJUR_NAMESPACE_NAME#g" ./proxy/ssl.conf
    if [ "${KIND}" = "true" ]; then
      # Build single-platform image for KIND without manifest lists.
      # Use DOCKER_BUILDKIT=0 to force legacy builder which produces simple
      # docker images that kind load can reliably import into containerd.
      # BuildKit (even with --platform) produces manifest lists that cause
      # "kind load docker-image" to silently fail to import.
      DOCKER_BUILDKIT=0 docker build -t $nginx_image .
    else
      docker build -t $nginx_image .
    fi

    if [ "${KIND}" = "true" ]; then
      kind_load_image $nginx_image
    elif [ "${DEV}" = "false" ]; then
      docker push $nginx_image
    fi
  popd
}

main $@
