
# Running Kubernetes in Minikube

## Dependencies:

You will need to install VirtualBox, and the minishift and kubectl executables:
 * VirtualBox download: https://www.virtualbox.org/wiki/Downloads
 * Minikube download: https://github.com/kubernetes/minikube/releases
 * Kubectl download: https://kubernetes.io/docs/tasks/tools/install-kubectl/

## Startup procedure

In this directory:

1) edit _minikube-boot.env to set environment variables
2) source _minikube-boot.env - to setup Kubernetes version & VM RAM
3) run _minikube-start.sh
4) source _minikube-boot.env - to reference Kubernetes environment.
5) check docker images - you should see Kubernetes images only.
7) run "kubectl get pods" - confirm all pods are Running or Completed
8) cd to parent directory (cd ..)

In parent directory:

9) edit bootstrap.env to set path to tarfile for Conjur appliance image
10) run _load_conjur_tarfile.sh to load & tag conjur-appliance image

IMPORTANT: The installation scripts will look for the value $CONJUR_APPLIANCE_IMAGE. Make sure the Conjur appliance image is tagged correctly. Fix manually if necessary.

Your Kubernetes environment is ready for Conjur cluster installation and configuration. Run the ./start script to run the numbered scripts in sequence. 
