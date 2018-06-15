# kubernetes-conjur-deploy

This repository contains scripts for deploying a Conjur v4 cluster to a
Kubernetes environment.

# Setup

The Conjur deployment scripts pick up configuration details from local
environment variables. The setup instructions below will walk you through the
necessary steps for configuring your Kubernetes environment and show you which
variables need to be set before deploying.

### Kubernetes

To deploy Conjur, you will first need access to a Kubernetes
deployment and must be conneceted to it using `kubectl`,
with a user that has sufficient privileges to create Kubernetes namespaces:

```
oc login https://<your-routing-domain>:<port> -u <privileged-user>
```

Finally, you must specify a name for the Kubernetes namespace in which you'd like
to deploy the Conjur cluster:

```
export CONJUR_NAMESPACE_NAME=conjur
```

### Docker

You will need to [install Docker](https://www.docker.com/get-docker) on your
local machine if you do not already have it.

### Conjur

#### Appliance Image

You will need to obtain a Docker image of the Conjur v4 appliance and tag it in
your local registry as `conjur-appliance:4.9-stable`. The deploy scripts will
look for this tag when pushing the applance image to your Kubernetes Docker
registry.

#### Appliance Configuration

When setting up a new Conjur installation, you must provide an account name and
a password for the admin account:

```
export CONJUR_ACCOUNT=<my_account_name>
export CONJUR_ADMIN_PASSWORD=<my_admin_password>
```

Conjur uses [declarative policy](https://developer.conjur.net/policy) to control
access to secrets. After deploying Conjur, you will need to load a policy that
defines a `webservice` to represent the Kubernetes authenticator:

```
- !policy
id: conjur/authn-k8s/{{ SERVICE_ID }}
```

The `SERVICE_ID` should describe the Kubernetes node in which your Conjur cluster
resides. For example, it might be something like `kubernetes/prod`. For Conjur
configuration purposes, you will need to provide this value to the Conjur deploy
scripts like so:

```
export AUTHENTICATOR_SERVICE_ID=<service_id>
```

This `service_id` can be anything you like, but it's important to make sure
that it matches the value that you intend to use in Conjur Policy.

# Usage

Run `./start` to deploy Conjur. This will execute the numbered scripts in
sequence to create and configure a Conjur cluster comprised of one Master, two
Standbys, and two read-only Followers.

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
