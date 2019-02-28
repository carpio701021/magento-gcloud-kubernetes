# Magento 2.3 CE on Gcloud and Kubernetes

This repository describes the installation process to set up Magento 2.3 CE in Google Cloud Platform and Kubernets as described [here](https://cloud.google.com/solutions/architecture/magento-deployment#deploying_magento_using_kubernetes_engine). This project was forked from [markshust/docker-magento](https://github.com/markshust/docker-magento).

## Prerrequisites

- [Install gcloud](https://cloud.google.com/sdk/docs/downloads-interactive)


## Setting up

- Clone repository:

```bash
git clone https://github.com/carpio701021/magento-gcloud-kubernetes.git
```

- Set project name (as prefix on gcloud resources):

```bash
export GCLOUD_PROJ_NAME=sartorial0301
```

- Create the resources on gcloud:

```bash
# Create the VPC
gcloud compute networks create $GCLOUD_PROJ_NAME-vpc \
    --subnet-mode=custom \
    --bgp-routing-mode=regional

# Create the subnets

gcloud compute networks subnets create frontend_magento \
    --network=$GCLOUD_PROJ_NAME-vpc \
    --range=10.0.0.0/24 \
    --region=us-west2

gcloud compute networks subnets create backend_magento \
    --network=$GCLOUD_PROJ_NAME-vpc \
    --range=10.1.0.0/24 \
    --region=us-west2


# Create RabbitMQ machine
gcloud compute --project=sartorial-platform instances create $GCLOUD_PROJ_NAME-messaging \
--zone=us-east1-b --machine-type=n1-standard-1 --subnet=default --network-tier=PREMIUM \
--maintenance-policy=MIGRATE --service-account=611338512743-compute@developer.gserviceaccount.com \
--scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append \
--tags=http-server,https-server --image=ubuntu-1804-bionic-v20190212a --image-project=ubuntu-os-cloud \
--boot-disk-size=10GB --boot-disk-type=pd-standard --boot-disk-device-name=$GCLOUD_PROJ_NAME-messaging

# Create Elastic Search machine
gcloud compute --project=sartorial-platform instances create $GCLOUD_PROJ_NAME-search \
--zone=us-east1-b --machine-type=n1-standard-1 --subnet=default --network-tier=PREMIUM \
--maintenance-policy=MIGRATE --service-account=611338512743-compute@developer.gserviceaccount.com \
--scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append \
--tags=http-server,https-server --image=ubuntu-1804-bionic-v20190212a --image-project=ubuntu-os-cloud \
--boot-disk-size=10GB --boot-disk-type=pd-standard --boot-disk-device-name=$GCLOUD_PROJ_NAME-search

# Create Kubernetes Cluster
gcloud beta container --project "sartorial-platform" clusters create "$GCLOUD_PROJ_NAME-k8s-cluster" --zone "us-central1-a" --username "admin" --cluster-version "1.11.7-gke.4" --machine-type "n1-standard-1" --image-type "COS" --disk-type "pd-standard" --disk-size "100" --scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" --num-nodes "3" --enable-cloud-logging --enable-cloud-monitoring --no-enable-ip-alias --network "projects/sartorial-platform/global/networks/default" --subnetwork "projects/sartorial-platform/regions/us-central1/subnetworks/default" --addons HorizontalPodAutoscaling,HttpLoadBalancing --enable-autoupgrade --enable-autorepair


```

- Connect to Messaging server created and install RabbitMQ as described [here](https://devdocs.magento.com/guides/v2.3/install-gde/prereq/install-rabbitmq.html
).
- Connect to Search server created and install Elastic Search as described [here](https://devdocs.magento.com/guides/v2.3/config-guide/elasticsearch/es-overview.html).

- Configure the Magento Key as described [here](https://devdocs.magento.com/guides/v2.3/install-gde/prereq/connect-auth.html) on file `src/auth.json`
- []()



- Configure on the local env
echo "Your system password has been requested to add an entry to /etc/hosts..."
echo "127.0.0.1 $DOMAIN" | sudo tee -a /etc/hosts

bin/setup $DOMAIN