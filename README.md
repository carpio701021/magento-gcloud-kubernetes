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

gcloud compute networks subnets create frontend-magento \
    --network=$GCLOUD_PROJ_NAME-vpc \
    --range=10.0.0.0/24 \
    --region=us-west2

gcloud compute networks subnets create backend-magento \
    --network=$GCLOUD_PROJ_NAME-vpc \
    --range=10.1.0.0/24 \
    --region=us-west2

# Create firewall rule to have access to the servers
gcloud compute firewall-rules create ssh-rule --description="allow ssh" --direction=INGRESS --priority=1000 --network=$GCLOUD_PROJ_NAME-vpc --action=ALLOW --rules=tcp:22,tcp:80,tcp:443 --source-ranges=0.0.0.0/0

# Create RabbitMQ machine
gcloud compute --project=sartorial-platform instances create $GCLOUD_PROJ_NAME-messaging --zone=us-west2-a --machine-type=n1-standard-1 --subnet=backend-magento --network-tier=PREMIUM --maintenance-policy=MIGRATE --service-account=611338512743-compute@developer.gserviceaccount.com --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append --image=ubuntu-1804-bionic-v20190212a --image-project=ubuntu-os-cloud --boot-disk-size=10GB --boot-disk-type=pd-standard --boot-disk-device-name=$GCLOUD_PROJ_NAME-messaging

# Create Elastic Search machine
gcloud compute --project=sartorial-platform instances create $GCLOUD_PROJ_NAME-search --zone=us-west2-a --machine-type=n1-standard-1 --subnet=backend-magento --network-tier=PREMIUM --maintenance-policy=MIGRATE --service-account=611338512743-compute@developer.gserviceaccount.com --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append --image=ubuntu-1804-bionic-v20190212a --image-project=ubuntu-os-cloud --boot-disk-size=10GB --boot-disk-type=pd-standard --boot-disk-device-name=$GCLOUD_PROJ_NAME-search

# Create Kubernetes Cluster
gcloud beta container --project "sartorial-platform" clusters create "$GCLOUD_PROJ_NAME-k8" --zone "us-west2-a" --username "admin" --cluster-version "1.11.7-gke.4" --machine-type "n1-standard-1" --image-type "COS" --disk-type "pd-standard" --disk-size "100" --scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" --num-nodes "3" --no-enable-cloud-logging --no-enable-cloud-monitoring --no-enable-ip-alias --network "projects/sartorial-platform/global/networks/sartorial0301-vpc" --subnetwork "projects/sartorial-platform/regions/us-west2/subnetworks/backend-magento" --addons HorizontalPodAutoscaling,HttpLoadBalancing --enable-autoupgrade --enable-autorepair

# Firewall rule for Rabbit
gcloud compute firewall-rules create $GCLOUD_PROJ_NAME-rabbit-kubernetes --description="Connectivity between Kubernetes cluster and RabbitMQ instance of $GCLOUD_PROJ_NAME." --direction=INGRESS --priority=1000 --network=$GCLOUD_PROJ_NAME-vpc --action=ALLOW --rules=tcp:5672 --source-ranges=10.0.0.0/8


# Firewall rule for Elastic Search
gcloud compute firewall-rules create $GCLOUD_PROJ_NAME-elasticsearch-kubernetes --description="Connectivity between Kubernetes cluster and Elastic Search instance of $GCLOUD_PROJ_NAME." --direction=INGRESS --priority=1000 --network=$GCLOUD_PROJ_NAME-vpc --action=ALLOW --rules=tcp:9200 --source-ranges=10.0.0.0/8


```

- Connect to Messaging server created and install RabbitMQ as described [here](https://devdocs.magento.com/guides/v2.3/install-gde/prereq/install-rabbitmq.html
).

```bash
gcloud compute ssh sartorial0301-messaging
```

- In the same server add the user and password:

```bash
# Command to create the user
rabbitmqctl add_user username password
# Command to set permissions for the user
rabbitmqctl set_permissions -p / username ".*" ".*" ".*"
```

- Connect to Search server created and install Elastic Search as described [here](https://devdocs.magento.com/guides/v2.3/config-guide/elasticsearch/es-overview.html).

```bash
gcloud compute ssh sartorial0301-search
```

- Configure Kubernetes to use the GC Kubernetes installation
- Run Kubernetes files and wait
- Once your Magento is running, login on the admin console and configure Elastic Search as described [here](https://devdocs.magento.com/guides/v2.3/config-guide/elasticsearch/es-config-nginx.html)







**** Pending topics ****

- Configure the Magento Key as described [here](https://devdocs.magento.com/guides/v2.3/install-gde/prereq/connect-auth.html) on file `src/auth.json`
