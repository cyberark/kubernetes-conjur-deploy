#!/bin/bash
rm -rf ~/.kube
if [[ "$OPENSHIFT_VERSION" == "" ]]; then
	echo "source _minishift-boot.env first before running this script."
	echo "Ignore errors re: not finding Openshift binary (cuz Openshift is not running yet, right?)"
	exit -1
fi
minishift start --memory $MINISHIFT_VM_MEMORY --vm-driver virtualbox --show-libmachine-logs --openshift-version $OPENSHIFT_VERSION
echo ""
echo "IMPORTANT!  IMPORTANT!  IMPORTANT!  IMPORTANT!"
echo "You need to source _minishift-boot.env again to reference docker daemon in Minishift..."
echo ""
