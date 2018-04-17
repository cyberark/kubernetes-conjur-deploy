# kubernetes-conjur-deploy

This repository contains scripts for deploying a Conjur v4 cluster to a
Kubernetes environment.

# Setup

The Conjur deployment scripts pick up configuration details from local
environment variables. The setup instructions below walk you through the
necessary steps for configuring your Kubernetes environment and show you which
variables need to be set before deploying.

### Docker

[Install Docker](https://www.docker.com/get-docker) on your local machine if you
do not already have it.

You need access to a Docker registry to which you are able to push. Provide the
URL and full path you wish to use for this registry:

```
export DOCKER_REGISTRY_URL=<registry-domain>
export DOCKER_REGISTRY_PATH=<registry-domain>/<additional-pathing>
```

Please login to the registry before running the deploy scripts.

### Kubernetes

Before deploying Conjur, you must first use `kubectl` to connect to your
Kubernetes environment with a user that has the `cluster-admin` role. The user
must be able to create namespaces and cluster roles.

#### Conjur Namespace

First, create a namespace in which to deploy your Conjur cluster:

```
kubectl create namespace <my-namespace>
```

Provide this namespace to the deploy scripts as follows:

```
export CONJUR_NAMESPACE_NAME=<my-namespace>
```

#### Image Pull Secret

Create an image pull secret called `conjurregcred` in your Conjur namespace to
allow the deploy scripts to retrieve the Conjur image from your Docker registry:

```
kubectl create secret docker-registry conjurregcred \
  --docker-server=$DOCKER_REGISTRY_URL \
  --docker-username=<my-username> \
  --docker-password=<my-password> \
  --docker-email=<my-email>
```

#### The `conjur-authenticator` Cluster Role

Conjur's Kubernetes authenticator requires the following privileges:

- [`"get"`, `"list"`] on `"pods"` for confirming a pod's namespace membership
- [`"create"`, `"get"`] on "pods/exec" for injecting a certificate into a pod

The deploy scripts include a manifest that defines the `conjur-authenticator`
cluster role, which grants these privileges. Create the role now (note that
your user will need to have the `cluster-admin` role to do so):

```
kubectl create -f ./manifests/conjur-authenticator-role.yaml
```

### Conjur

#### Appliance Image

You need to obtain a Docker image of the Conjur v4 appliance and push it to your
Docker registry with the tag:

```
$DOCKER_REGISTRY_PATH/conjur-appliance:$CONJUR_NAMESPACE_NAME
```

#### Appliance Configuration

When setting up a new Conjur installation, you must provide an account name and
a password for the admin account:

```
export CONJUR_ACCOUNT=<my_account_name>
export CONJUR_ADMIN_PASSWORD=<my_admin_password>
```

Conjur uses [declarative policy](https://developer.conjur.net/policy) to control
access to secrets. After deploying Conjur, you need to load a policy that
defines a `webservice` to represent the Kubernetes authenticator:

```
- !policy
id: conjur/authn-k8s/{{ SERVICE_ID }}
```

The `SERVICE_ID` should describe the Kubernetes cluster in which your Conjur
deployment resides. For example, it might be something like `kubernetes/prod`.
For Conjur configuration purposes, you need to provide this value to the Conjur
deploy scripts like so:

```
export AUTHENTICATOR_SERVICE_ID=<service_id>
```

This `service_id` can be anything you like, but it's important to make sure
that it matches the value that you intend to use in Conjur Policy.

# Usage

Run `./start` to deploy Conjur. This executes the numbered scripts in sequence
to create and configure a Conjur cluster comprised of one Master, two Standbys,
and two read-only Followers.

Please note that the deploy scripts grant the `anyuid` SCC to the `default`
service account in the namespace that contains Conjur as configuring standbys and
followers requires root access.

When the deploy scripts finish, they will print out the URL and credentials that
you need to access Conjur from outside the Kubernetes environment. You can access
the Conjur UI by visiting this URL in a browser or use it to interact with Conjur
through the [Conjur CLI](https://developer.conjur.net/cli).

# Test App Demo

The [kubernetes-conjur-demo repo](https://github.com/conjurdemos/kubernetes-conjur-demo)
can be used to set up a test application that retrieves secrets from Conjur
using our Ruby API. It can be used as a reference when setting up your own
applications to integrate with Conjur.
