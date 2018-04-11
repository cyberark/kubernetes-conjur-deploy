# kubernetes-conjur-demo

This repo demonstrates an app retrieving secrets from a Conjur cluster using the
[Kubernetes authenticator](https://github.com/conjurinc/authn-k8s). The numbered
scripts perform the same setps that a user will have to go through when setting
up their own applications.

# Setup

### Deploying Conjur

Before running this demo you will need to [set up a Conjur cluster](https://github.com/conjurinc/kubernetes-conjur-deploy)
in your kubernetes environment. It is recommended that you **set up a separate
Conjur cluster** purely for the purpose of running this demo as it loads Conjur
policy that you would not want to be present in your production environment.

### Script Configuration

You will need to provide a name for the kubernetes project in which your test app
will be deployed:

```
export TEST_APP_PROJECT_NAME=test-app
```

You will also need to set several environment variables to match the values used
when configuring your Conjur deployment. Note that if you may already have these 
variables set if you're using the same shell to run the demo:

```
export CONJUR_PROJECT_NAME=<conjur-project-name>
export DOCKER_REGISTRY_PATH=docker-registry-<registry-namespace>.<routing-domain>
export CONJUR_ACCOUNT=<account-name>
export CONJUR_ADMIN_PASSWORD=<admin-password>
export AUTHENTICATOR_SERVICE_ID=<service-id>
```

# Usage

Run `./start` to execute the numbered scripts, which will step through the
process of configuring Conjur and deploying a test app. The test app uses the
Conjur Ruby API, configured with the access token provided by the authenticator
sidecar, to retrieve a secret value from Conjur.

You can run the `./rotate` script to rotate the secret value and then run the
final numbered script again to retrieve and print the new value.