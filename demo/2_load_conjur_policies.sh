#!/bin/bash
set -eou pipefail

. utils.sh

announce "Loading Conjur policy."

set_context $CONJUR_CONTEXT_NAME

conjur_master=$(get_master_pod_name)

# (re)install Conjur policy plugin
kubectl exec $conjur_master -- touch /opt/conjur/etc/plugins.yml
kubectl exec $conjur_master -- conjur plugin uninstall policy
kubectl exec $conjur_master -- conjur plugin install policy

pushd policy
  sed -e "s#{{ SERVICE_ID }}#$AUTHENTICATOR_SERVICE_ID#g" ./authn-k8s.template.yml |
    sed -e "s#{{ TEST_APP_CONTEXT_NAME }}#$TEST_APP_CONTEXT_NAME#g" > ./authn-k8s.yml

  sed -e "s#{{ TEST_APP_CONTEXT_NAME }}#$TEST_APP_CONTEXT_NAME#g" ./apps.template.yml > ./apps.yml
popd

kubectl cp ./policy conjur-cluster-1396572337-c7265:/policy

kubectl exec $conjur_master -- conjur authn login -u admin -p $CONJUR_ADMIN_PASSWORD
kubectl exec $conjur_master -- conjur policy load --as-group security_admin "policy/conjur.yml"

kubectl exec $conjur_master -- rm -rf ./policy

echo "Conjur policy loaded."

password=$(openssl rand -hex 12)

kubectl exec $conjur_master -- conjur variable values add test-app-db/password $password

announce "Added DB password value: $password"

kubectl exec $conjur_master -- conjur authn logout
