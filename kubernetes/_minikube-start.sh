#!/bin/bash
rm -rf ~/.kube ~/.minikube
if [[ "$KUBERNETES_VERSION" == "" ]]; then
	echo "source _minikube-boot.env first before running this script."
	echo "Ignore errors re: not getting Kubernetes host (cuz Kubernetes is not running yet, right?)"
	exit -1
fi
minikube config set memory $MINIKUBE_VM_MEMORY
minikube start --memory $MINIKUBE_VM_MEMORY --vm-driver virtualbox --kubernetes-version $KUBERNETES_VERSION
kubectl taint nodes minikube node-role.kubernetes.io/master:NoSchedule- node/minikube untainted
echo ""
echo "IMPORTANT!  IMPORTANT!  IMPORTANT!  IMPORTANT!"
echo "You need to source _minikube-boot.env again to reference docker daemon in Minikube..."
echo ""
