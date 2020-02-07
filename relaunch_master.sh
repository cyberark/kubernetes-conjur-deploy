#!/bin/bash
set -euo pipefail

. utils.sh

set_namespace $CONJUR_NAMESPACE_NAME

master_pod_name=$(get_master_pod_name)

kubectl delete pod $master_pod_name

echo "Master pod deleted."

wait_for_node $master_pod_name

kubectl exec $master_pod_name -- rm -rf /var/lib/postgresql/9.3
kubectl exec $master_pod_name -- ln -sf /opt/conjur/dbdata/9.3 /var/lib/postgresql/9.3
# kubectl exec $master_pod_name -- chown -h postgres:postgres /var/lib/postgresql/9.3/main

echo "Master database recovered."

kubectl exec $master_pod_name -- cp /opt/conjur/data/standby-seed.tar /opt/conjur/data/standby-seed.tar-bkup
kubectl exec $master_pod_name -- evoke unpack seed /opt/conjur/data/standby-seed.tar
kubectl exec $master_pod_name -- cp /opt/conjur/data/standby-seed.tar-bkup /opt/conjur/data/standby-seed.tar
kubectl exec $master_pod_name -- rm /etc/chef/solo.json

echo "Master configuration recovered."

kubectl label --overwrite pod $master_pod_name role=master

master_altnames="localhost,conjur-master.$CONJUR_NAMESPACE_NAME.svc.cluster.local"
if [ $PLATFORM = 'openshift' ]; then
  conjur_master_route=$($cli get routes | grep conjur-master | awk '{ print $2 }')
  master_altnames="$master_altnames,$conjur_master_route"
fi

kubectl exec $master_pod_name -- evoke configure master \
   --accept-eula \
   -h conjur-master \
   --master-altnames $master_altnames \
   --follower-altnames conjur-follower,conjur-follower.$CONJUR_NAMESPACE_NAME.svc.cluster.local \
   -p $CONJUR_ADMIN_PASSWORD \
   $CONJUR_ACCOUNT

echo "Master pod configured."

set_conjur_pod_log_level $master_pod_name

if $cli get statefulset &>/dev/null && [[ $PLATFORM != openshift ]]; then  # this returns non-0 if platform doesn't support statefulset
  kubectl exec haproxy-conjur-master -- kill -s HUP 1  # haproxy runs as PID 1, see Reloading Config here: https://hub.docker.com/_/haproxy/
  echo 'HAProxy restarted'
else
  haproxy/update_haproxy.sh haproxy-conjur-master  # non-statefulset configuration uses IPs, needs updated
  echo "HAProxy reconfigured."
fi

sleep 5

echo "Reconfiguring standbys"

standby_pods=$(kubectl get pods -l role=standby --no-headers | awk '{ print $1 }')
for pod_name in $standby_pods; do
  kubectl label --overwrite pod $pod_name role=unset
  kubectl exec $pod_name -- rm -f /etc/chef/solo.json
done

./6_configure_standbys.sh

kubectl exec $master_pod_name -- curl -s localhost/health | tee "output/$PLATFORM-relaunch-health.json"

./8_print_cluster_info.sh
