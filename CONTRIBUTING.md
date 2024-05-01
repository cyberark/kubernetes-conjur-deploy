# Contributing

For general contribution and community guidelines, please see the [community repo](https://github.com/cyberark/community).

## Contributing

1. [Fork the project](https://help.github.com/en/github/getting-started-with-github/fork-a-repo)
2. [Clone your fork](https://help.github.com/en/github/creating-cloning-and-archiving-repositories/cloning-a-repository)
3. Make local changes to your fork by editing files
3. [Commit your changes](https://help.github.com/en/github/managing-files-in-a-repository/adding-a-file-to-a-repository-using-the-command-line)
4. [Push your local changes to the remote server](https://help.github.com/en/github/using-git/pushing-commits-to-a-remote-repository)
5. [Create new Pull Request](https://help.github.com/en/github/collaborating-with-issues-and-pull-requests/creating-a-pull-request-from-a-fork)

From here your pull request will be reviewed and once you've responded to all
feedback it will be merged into the project. Congratulations, you're a
contributor!

## Deploying Secrets Manager, Self-Hosted Leaders and Followers (*Test and Demo Only*)

### Leader Cluster configuration

*Please note that running leader cluster in OpenShift and Kubernetes environments
is not recommended and should be only done for test and demo setups.*


As mentioned before if you are using these scripts to deploy a full cluster, you will need to set
in `dev-bootstrap.env`:

```
export DEPLOY_MASTER_CLUSTER=true
```

You will also need to set a few environment variable that are only used when
configuring the Secrets Manager leader. You must provide an account name and password
for the Secrets Manager admin account:

```
export CONJUR_ACCOUNT=<my_account_name>
export CONJUR_ADMIN_PASSWORD=<my_admin_password>
```

Finally, run `./start` to execute the scripts necessary for deploying Secrets Manager.

### Data persistence

The Secrets Manager leader and standbys are deployed as a
[Stateful Set](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/) on supported target platforms (Kubernetes 1.5+ / OpenShift 3.5+).
Database and configuration data is symlinked and mounted to
[persistent volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/).
These manifests assume a default [Storage Class](https://kubernetes.io/docs/concepts/storage/storage-classes/)
is set up for the cluster so persistent volume claims will be fulfilled.

Volumes:
- `/opt/conjur/dbdata` - 2GB, database persistence
- `/opt/conjur/data` - 1GB, seed file persistence

### Setup

To configure the Secrets Manager leader to persist data, run these commands in the Secrets Manager leader container before running `evoke configure leader ...`.

```sh-session
# mv /var/lib/postgresql/9.3 /opt/conjur/dbdata/
# ln -sf /opt/conjur/dbdata/9.3 /var/lib/postgresql/9.3

# evoke seed standby > /opt/conjur/data/standby-seed.tar
```

Note that setup is done as part of script [`6_configure_master.sh`](6_configure_master.sh).

### Restore

If the Secrets Manager leader pod is rescheduled the persistent volumes will be reattached.
Once the pod is running again, run these commands to restore the leader.

```
# rm -rf /var/lib/postgresql/9.3
# ln -sf /opt/conjur/dbdata/9.3 /var/lib/postgresql/9.3

# cp /opt/conjur/data/standby-seed.tar /opt/conjur/data/standby-seed.tar-bkup
# evoke unpack seed /opt/conjur/data/standby-seed.tar
# cp /opt/conjur/data/standby-seed.tar-bkup /opt/conjur/data/standby-seed.tar
# rm /etc/chef/solo.json

# evoke configure leader ...  # using the same arguments as the first launch
```

Standbys must also be reconfigured since the Secrets Manager leader pod IP changes.

Run [`relaunch_master.sh`](relaunch_master.sh) to try this out in your cluster, after running the deploy.
Our plan is to automate this process with a Kubernetes operator.

### Secrets Manager CLI

The deploy scripts include a manifest for creating a Secrets Manager CLI container within
the Kubernetes environment that can then be used to interact with Secrets Manager. Deploy
the CLI pod and SSH into it:

```
# Kubernetes
kubectl create -f ./kubernetes/conjur-cli.yaml
kubectl exec -it [cli-pod-name] -- sh

# OpenShift
oc create -f ./openshift/conjur-cli.yaml
oc exec -it <cli-pod-name> -- sh
```

Once inside the CLI container, use the admin credentials to connect to Secrets Manager:

```
conjur init -h conjur-master
```

Follow our [CLI usage instructions](https://docs.cyberark.com/conjur-enterprise/latest/en/content/developer/cli/cli-setup.htm?tocpath=Developer%7CConjur%20CLI%7C_____1)
to get started with the Secrets Manager CLI.

### Secrets Manager UI

Visit the Secrets Manager UI URL in your browser and login with the admin credentials to
access the Secrets Manager UI.

## Deploying Secrets Manager Leader and Followers (*Local Environment*)

You can now deploy a local development environment for Kubernetes using [Docker Desktop](https://www.docker.com/products/docker-desktop).
Docker Desktop provides a convenient way to deploy and develop from your machine against a locally deployed cluster.

### Prerequisites

1. [Docker Desktop](https://www.docker.com/products/docker-desktop) installed

1. Kubernetes enabled in Docker Desktop

    1. Navigate to Docker Preferences

    1. Click on the Kubernetes tab and "Enable Kubernetes"

1. By default, 2.0 Gib of memory is allocated to Docker on your computer. 

   To successfully deploy a Secrets Manager, Self-Hosted cluster (Leader + Followers + Standbys), you will need to increase the memory limit to 6 Gib. To do so, perform the following:
   
   1. Navigate to Docker preferences
   
   1. Click on "Advanced" under "Resources" and slide the "Memory" bar to 6
   
### Deploy

To deploy locally, perform the following:

1. (Docker Desktop only!) Ensure you are in the proper local context. Otherwise, the deployment will not run successfully
   
   Run `kubectl config current-context` to verify which context you are currently in so if needed, you can switch back to it easily
   
   Run `kubectl config use-context docker-desktop` to switch to a local context. This is the context you will need to run locally

1. In `dev-bootstrap.env` uncomment the `LOCAL DEV CONFIG` section and adjust the configurations in `dev-bootstrap.env` as needed

1. Run `source dev-bootstrap.env`

1. Run `./start` appending `--oss` or `--dap` according to the environment that needs to be deployed (the default is dap)

### Clean-up

To remove K8s resources from your local environment perform the following:

Run `kubectl get all --all-namespaces` to list all resources across all namespaces in your cluster

Run `kubectl delete <resource-type> <name-of-resource> --namespace <namespace>` 

or `kubectl delete all --all -n <namespace>` to delete the whole namespace.

Note that for Deployments, you must first delete the Deployment and then the Pod. Otherwise the Pod will terminate and another will start it its place.

---
