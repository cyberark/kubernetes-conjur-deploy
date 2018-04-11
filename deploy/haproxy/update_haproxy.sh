#!/bin/bash
set -eo pipefail

# This script updates the HAProxy configuration for currently running Conjur containers
# and restarts the proxy daemon

. ./utils.sh

declare template_file="./haproxy/haproxy.template.cfg"
declare destination_file="./haproxy/haproxy.cfg"

# takes one argument: the name of the HAProxy container to update
main() {
  haproxy_pod_name=$1

  echo "# This file is generated by $0 in $(pwd)." > $destination_file
  cp $template_file $destination_file
  update_http_servers
  update_pg_servers
  update_ldap_servers

  copy_file_to_container "$destination_file" "/usr/local/etc/haproxy/haproxy.cfg" "$haproxy_pod_name"
  kubectl exec $haproxy_pod_name /start.sh
}

# Appends Conjur HTTP server info in HAProxy format to haproxy.cfg.
update_http_servers() {
  cat <<CONFIG >> $destination_file

# HTTP backend info 
# Generated by $0 in $(pwd)
backend b_conjur_master_http
	mode tcp
	balance static-rr
	option external-check
	default-server inter 5s fall 3 rise 2
	external-check path "/usr/bin:/usr/local/bin"
	external-check command "/root/conjur-health-check.sh"
CONFIG

  pod_list=$(kubectl get pods -l app=conjur-node --no-headers | awk '{print $1}')
  
  for pname in $pod_list; do
    pod_ip=$(kubectl describe pod $pname | grep "IP:" | awk '{print $2}')
    echo -e '\t' server $pname $pod_ip:443 check >> $destination_file
  done
}

# Appends Conjur PostgreSQL server info in HAProxy format to haproxy.cfg.
update_pg_servers() {
  cat <<CONFIG >> $destination_file

# PG backend info
# Generated by $0 in $(pwd)
backend b_conjur_master_pg
	mode tcp
	balance static-rr
	option external-check
	default-server inter 5s fall 3 rise 2
	external-check path "/usr/bin:/usr/local/bin"
	external-check command "/root/conjur-health-check.sh"
CONFIG

  pod_list=$(kubectl get pods -l app=conjur-node --no-headers | awk '{print $1}')
  
  for pname in $pod_list; do
    pod_ip=$(kubectl describe pod $pname | grep "IP:" | awk '{print $2}')
    echo -e '\t' server $pname $pod_ip:5432 check >> $destination_file
  done
}

# Appends Conjur LDAP server info in HAProxy format to haproxy.cfg.
update_ldap_servers() {
  cat <<CONFIG >> $destination_file

# LDAP backend info 
# Generated by $0 in $(pwd)
backend b_conjur_master_ldap
	mode tcp
	balance static-rr
	option external-check
	default-server inter 30s fall 3 rise 2
	external-check path "/usr/bin:/usr/local/bin"
	external-check command "/root/conjur-health-check.sh"
CONFIG

  pod_list=$(kubectl get pods -l app=conjur-node --no-headers | awk '{print $1}')
  
  for pname in $pod_list; do
    pod_ip=$(kubectl describe pod $pname | grep "IP:" | awk '{print $2}')
    echo -e '\t' server $pname $pod_ip:636 check >> $destination_file
  done
}

main "$@"
