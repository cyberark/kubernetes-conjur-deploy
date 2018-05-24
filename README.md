# kubernetes-conjur-deploy

This repository contains scripts for deploying a Conjur v4 cluster to a
Kubernetes or OpenShift environment.

# Setup

The Conjur deployment scripts pick up configuration details from local
environment variables. The setup instructions below walk you through the
necessary steps for configuring your environment and show you which variables
need to be set before deploying.

### Platform

If you are working with OpenShift, you will need to begin by setting:

```
export PLATFORM=openshift
```

Otherwise, this variable will default to `kubernetes`.

### Docker Configuration

[Install Docker](https://www.docker.com/get-docker) on your local machine if you
do not already have it.

#### Kubernetes

You will need to provide the domain and any additional pathing for the Docker
registry from which your Kubernetes cluster pulls images: 

```
export DOCKER_REGISTRY_URL=<registry-domain>
export DOCKER_REGISTRY_PATH=<registry-domain>/<additional-pathing>
```

Note that the deploy scripts will be pushing images to this registry so you will
need to have push access.

If you are using a private registry, you will also need to provide login 
credentials that are used by the deployment scripts to create a [secret for
pulling images](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/#create-a-secret-in-the-cluster-that-holds-your-authorization-token):

```
export DOCKER_USERNAME=<your-username>
export DOCKER_PASSWORD=<your-password>
export DOCKER_EMAIL=<your-email>
```

Please make sure that you are logged in to the registry before deploying.

#### OpenShift

OpenShift users should make sure the [integrated Docker registry](https://docs.openshift.com/container-platform/3.3/install_config/registry/deploy_registry_existing_clusters.html)
in your OpenShift environment is available and that you've added it as an
[insecure registry](https://docs.docker.com/registry/insecure/) in your local
Docker engine. You must then specify the path to the OpenShift registry like so:

```
export DOCKER_REGISTRY_PATH=docker-registry-<registry-namespace>.<routing-domain>
```

Please make sure that you are logged in to the registry before deploying.

### Kubernetes / OpenShift Configuration

Before deploying Conjur, you must first make sure that you are connected to your
chosen platform with a user that has the `cluster-admin` role. The user must be
able to create namespaces and cluster roles.

#### Conjur Namespace

Provide the name of a namespace in which to deploy Conjur:

```
export CONJUR_NAMESPACE_NAME=<my-namespace>
```

#### The `conjur-authenticator` Cluster Role

Conjur's Kubernetes authenticator requires the following privileges:

- [`"get"`, `"list"`] on `"pods"` for confirming a pod's namespace membership
- [`"create"`, `"get"`] on "pods/exec" for injecting a certificate into a pod

The deploy scripts include a manifest that defines the `conjur-authenticator`
cluster role, which grants these privileges. Create the role now (note that
your user will need to have the `cluster-admin` role to do so):

```
# Kubernetes
kubectl create -f ./manifests/conjur-authenticator-role.yaml

# OpenShift
oc create -f ./manifests/conjur-authenticator-role.yaml
```

### Conjur Configuration

#### Appliance Image

You need to obtain a Docker image of the Conjur v4 appliance and push it to an
accessible Docker registry. Provide the image and tag like so:

```
export CONJUR_APPLIANCE_IMAGE=<tagged-docker-appliance-image>
```

#### Appliance Configuration

When setting up a new Conjur installation, you must provide an account name and
a password for the admin account:

```
export CONJUR_ACCOUNT=<my_account_name>
export CONJUR_ADMIN_PASSWORD=<my_admin_password>
```

You will also need to provide an ID for the Conjur authenticator that will later
be used in [Conjur policy](https://developer.conjur.net/policy) to provide your
apps with access to secrets through Conjur:

```
export AUTHENTICATOR_ID=<authenticator-id>
```

This ID should describe the cluster in which Conjur resides. For example, if
you're hosting your dev environment on GKE you might use `gke/dev`.

# Usage

### Deploying Conjur

Run `./start` to deploy Conjur. This executes the numbered scripts in sequence
to create and configure a Conjur cluster comprised of one Master, two Standbys,
and two read-only Followers. The final step will print out the necessary info
for interacting with Conjur through the CLI or UI.

### Conjur CLI

The deploy scripts include a manifest for creating a Conjur CLI container within
the Kubernetes environment that can then be used to interact with Conjur. Deploy
the CLI pod and SSH into it:

```
# Kubernetes
kubectl create -f ./manifests/conjur-cli.yaml
kubectl exec -it [cli-pod-name] bash

# OpenShift
oc create -f ./manifests/conjur-cli.yaml
oc exec -it <cli-pod-name> bash
```

Once inside the CLI container, use the admin credentials to connect to Conjur:

```
conjur init -h conjur-master
```

Follow our [CLI usage instructions](https://developer.conjur.net/cli#quickstart)
to get started with the Conjur CLI.

### Conjur UI

Visit the Conjur UI URL in your browser and login with the admin credentials to
access the Conjur UI.

# Test App Demo

The [kubernetes-conjur-demo repo](https://github.com/conjurdemos/kubernetes-conjur-demo)
deploys test applications that retrieve secrets from Conjur and serves as a
useful reference when setting up your own applications to integrate with Conjur.
