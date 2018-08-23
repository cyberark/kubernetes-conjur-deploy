#!/bin/bash
if [[ "$OPENSHIFT_VERSION" == "" ]]; then
	echo "source _minishift-boot.env first before running this script."
	exit -1
fi
if [[ $1 == reinstall ]]; then
  minishift delete -f
  rm -rf ~/.kube ~/.minishift
fi
minishift start --memory $MINISHIFT_VM_MEMORY --vm-driver virtualbox --show-libmachine-logs --openshift-version $OPENSHIFT_VERSION
echo ""
echo "IMPORTANT!  IMPORTANT!  IMPORTANT!  IMPORTANT!"
echo "You need to source _minishift-boot.env again to reference docker daemon in Minishift..."
echo ""
