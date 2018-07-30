#!/bin/bash 
if [[ ("$CONJUR_APPLIANCE_TARFILE" == "") 
      || ("$CONJUR_APPLIANCE_IMAGE" == "") ]]; then
	echo "source bootstrap.env to set all environment variables."
	exit -1
fi
docker load -i $CONJUR_APPLIANCE_TARFILE
IMAGE_ID=$(docker images | grep conjur-appliance | awk '{print $3}')
docker tag $IMAGE_ID $CONJUR_APPLIANCE_IMAGE
