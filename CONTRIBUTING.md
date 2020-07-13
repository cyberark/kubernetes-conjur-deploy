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

## Deploying Conjur Master and Followers (*Test and Demo Only*)

### Master Cluster configuration

*Please note that running master cluster in OpenShift and Kubernetes environments
is not recommended and should be only done for test and demo setups.*


As mentioned before if you are using these scripts to deploy a full cluster, you will need to set
in `dev-bootstrap.env`:

```
export DEPLOY_MASTER_CLUSTER=true
```

You will also need to set a few environment variable that are only used when
configuring the Conjur master. If you are working with Conjur that is not v5,
```
export CONJUR_VERSION=<conjur_version>
```
along with any other changes you might want.

Otherwise, this variable will default to `5`.

_Note: If you are using Conjur v4, please use [v4_support](https://github.com/cyberark/kubernetes-conjur-deploy/tree/v4_support)
branch of this repo!_

You must also provide an account name and password for the Conjur admin account:

```
export CONJUR_ACCOUNT=<my_account_name>
export CONJUR_ADMIN_PASSWORD=<my_admin_password>
```

Finally, run `./start` to execute the scripts necessary for deploying Conjur.

### Data persistence

The Conjur master and standbys are deployed as a
[Stateful Set](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/) on supported target platforms (Kubernetes 1.5+ / OpenShift 3.5+).
Database and configuration data is symlinked and mounted to
[persistent volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/).
These manifests assume a default [Storage Class](https://kubernetes.io/docs/concepts/storage/storage-classes/)
is set up for the cluster so persistent volume claims will be fulfilled.

Volumes:
- `/opt/conjur/dbdata` - 2GB, database persistence
- `/opt/conjur/data` - 1GB, seed file persistence

### Setup

To configure the Conjur master to persist data, run these commands in the Conjur master container before running `evoke configure master ...`.

```sh-session
# mv /var/lib/postgresql/9.3 /opt/conjur/dbdata/
# ln -sf /opt/conjur/dbdata/9.3 /var/lib/postgresql/9.3

# evoke seed standby > /opt/conjur/data/standby-seed.tar
```

Note that setup is done as part of script [`6_configure_master.sh`](6_configure_master.sh).

### Restore

If the Conjur master pod is rescheduled the persistent volumes will be reattached.
Once the pod is running again, run these commands to restore the master.

```
# rm -rf /var/lib/postgresql/9.3
# ln -sf /opt/conjur/dbdata/9.3 /var/lib/postgresql/9.3

# cp /opt/conjur/data/standby-seed.tar /opt/conjur/data/standby-seed.tar-bkup
# evoke unpack seed /opt/conjur/data/standby-seed.tar
# cp /opt/conjur/data/standby-seed.tar-bkup /opt/conjur/data/standby-seed.tar
# rm /etc/chef/solo.json

# evoke configure master ...  # using the same arguments as the first launch
```

Standbys must also be reconfigured since the Conjur master pod IP changes.

Run [`relaunch_master.sh`](relaunch_master.sh) to try this out in your cluster, after running the deploy.
Our plan is to automate this process with a Kubernetes operator.

### Conjur CLI

The deploy scripts include a manifest for creating a Conjur CLI container within
the Kubernetes environment that can then be used to interact with Conjur. Deploy
the CLI pod and SSH into it:

```
# Kubernetes
kubectl create -f ./kubernetes/conjur-cli.yaml
kubectl exec -it [cli-pod-name] bash

# OpenShift
oc create -f ./openshift/conjur-cli.yaml
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

## Deploying Conjur Master and Followers (*Local Dev Environment*)

You can now deploy a local development environment for Kubernetes using [Docker Desktop](https://www.docker.com/products/docker-desktop).
Docker Desktop provides a convenient way to deploy and develop on Conjur from your local machine. To enable this, perform the following:

1. In `dev-bootstrap.env` uncomment the "LOCAL DEV CONFIG" section and adjust the configurations in `dev-bootstrap.env` as needed

1. Run `source dev-bootstrap.env`

1. Run `./script.sh`

### Helpful hints

By default, 2.0 Gib of memory is allocated to Docker. To successfully deploy a DAP Cluster (Master + Followers + Standbys), 
you will need to increase this to 4 Gib of memory. 

1. Navigate to Docker preferences

1. Click on "Advanced" and slide the "Memory" bar to 4

Before deploying locally using Docker Desktop, ensure you are in the proper `docker-desktop` context. 
Otherwise, the deployment will not run successfully.

To switch contexts: `kubectl config use-context docker-desktop`

---
