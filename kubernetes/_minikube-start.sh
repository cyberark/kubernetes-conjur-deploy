#!/bin/bash
if [[ "$KUBERNETES_VERSION" == "" ]]; then
	echo "source _minikube-boot.env first before running this script."
	exit -1
fi
if [[ $1 == reinstall ]]; then
  minikube delete
  rm -rf ~/.kube ~/.minikube
fi
minikube config set memory $MINIKUBE_VM_MEMORY
minikube start --memory $MINIKUBE_VM_MEMORY --vm-driver virtualbox --kubernetes-version $KUBERNETES_VERSION 
#remove all taints from the minikube node so that pods will get scheduled
sleep 5
kubectl patch node minikube -p '{"spec":{"taints":[]}}'
echo ""
echo "IMPORTANT!  IMPORTANT!  IMPORTANT!  IMPORTANT!"
echo "You need to source _minikube-boot.env again to reference docker daemon in Minikube..."
echo ""
