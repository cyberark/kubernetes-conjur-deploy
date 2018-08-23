
# Running OpenShift in Minishift 

## Dependencies:

You will need to install VirtualBox and the minishift executable.
 * VirtualBox download: https://www.virtualbox.org/wiki/Downloads
 * Minishift download: https://github.com/minishift/minishift/releases

## Startup procedure

In this directory:

1) edit _minishift-boot.env to set environment variables
2) source _minishift-boot.env - to setup OpenShift version & VM RAM
3) run _minishift-start.sh
4) source _minishift-boot.env - to reference OpenShift environment
5) check docker images - you should see openshift images only.
6) login as cluster admin (oc login -u system:admin)
7) run "oc get pods --namespace=default" - confirm all pods are Running or Completed
8) cd to parent directory (cd ..)

In parent directory:

9) edit bootstrap.env to set path to tarfile for Conjur appliance image
10) run _load_conjur_tarfile.sh to load & tag conjur-appliance image

IMPORTANT: The installation scripts will look for the value $CONJUR_APPLIANCE_IMAGE. Make sure the Conjur appliance image is tagged correctly. Fix manually if necessary.

Your OpenShift environment is ready for Conjur cluster installation and configuration. Run the ./start script to run the numbered scripts in sequence. Note that the installation scripts may hang in a couple of places:
 * 3_deploy_conjur_cluster.sh - one or more cluster pods stuck in ContainerCreating state
 * 5_configure_master.sh - hangs at initial runit step

If it seems the scripts are hanging, ctrl-C out of them, run ./delete_deployments.sh, then run ./start again.

