#!/bin/bash 

oc project conjur

printf "\n\nLoad balancer config:\n----------------\n"
oc exec haproxy-conjur-master cat /usr/local/etc/haproxy/haproxy.cfg

printf "\n\nRunning containers:\n----------------\n"
oc get pods -n conjur

printf "\n\nStateful node info:\n----------------\n"
cont_list=$(oc get pods -l app=conjur-node --no-headers | awk '{print $1}')
for cname in $cont_list; do
	crole=$(oc exec $cname -- sh -c "evoke role")
	cip=$(oc describe pod $cname | awk '/^IP:/ {print $2}')
	printf "%s, %s, %s\n" $cname $crole $cip
done
printf "\n\n"
