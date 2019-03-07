# Magento 2.3 CE on Gcloud and Kubernetes

This repository describes the installation process to set up Magento 2.3 CE in Google Cloud Platform and Kubernets as described [here](https://cloud.google.com/solutions/architecture/magento-deployment#deploying_magento_using_kubernetes_engine). This project was forked from [markshust/docker-magento](https://github.com/markshust/docker-magento).

## Prerrequisites

- [Install gcloud and authenticate](https://cloud.google.com/sdk/docs/downloads-interactive)
- [Have Magento authentication keys](https://devdocs.magento.com/guides/v2.3/install-gde/prereq/connect-auth.html)

## Setting up

For all of following steps you need to run the commands in a linux command line (bash) with GC installed and configured with your default project for your magento installation.

- Clone repository:

```bash
git clone https://github.com/carpio701021/magento-gcloud-kubernetes.git
cd magento-gcloud-kubernetes
```

- Set project name (as prefix on gcloud resources). If you open a new command line run it again.

```bash
export GCLOUD_PROJ_NAME=sartorial-platform
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
gcloud compute firewall-rules create ssh-rule \
--description="Ssh rule" \
--direction=INGRESS --priority=1000 \
--network=$GCLOUD_PROJ_NAME-vpc \
--action=ALLOW \
--rules=tcp:22,tcp:80,tcp:443 \
--source-ranges=0.0.0.0/0

# Create Rabbitmq machine
gcloud compute --project=$GCLOUD_PROJ_NAME instances create $GCLOUD_PROJ_NAME-messaging \
--zone=us-west2-a --machine-type=n1-standard-1 --subnet=backend-magento \
--network-tier=PREMIUM --maintenance-policy=MIGRATE \
--service-account=611338512743-compute@developer.gserviceaccount.com \
--scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append \
--image=ubuntu-1804-bionic-v20190212a --image-project=ubuntu-os-cloud \
--boot-disk-size=10GB --boot-disk-type=pd-standard \
--boot-disk-device-name=$GCLOUD_PROJ_NAME-messaging

# Create Elastic Search machine
gcloud compute --project=$GCLOUD_PROJ_NAME instances create $GCLOUD_PROJ_NAME-search \
--zone=us-west2-a --machine-type=n1-standard-1 --subnet=backend-magento \
--network-tier=PREMIUM --maintenance-policy=MIGRATE \
--service-account=611338512743-compute@developer.gserviceaccount.com \
--scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append \
--image=ubuntu-1804-bionic-v20190212a --image-project=ubuntu-os-cloud \
--boot-disk-size=10GB --boot-disk-type=pd-standard \
--boot-disk-device-name=$GCLOUD_PROJ_NAME-search

# Create Kubernetes Cluster
gcloud beta container --project "$GCLOUD_PROJ_NAME" clusters create "$GCLOUD_PROJ_NAME-k8" \
--zone "us-west2-a" --username "admin" --cluster-version "1.11.7-gke.4" \
--machine-type "n1-standard-1" --image-type "COS" --disk-type "pd-standard" \
--disk-size "100" \
--scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" \
--num-nodes "3" --no-enable-cloud-logging \
--no-enable-cloud-monitoring --no-enable-ip-alias \
--network "projects/$GCLOUD_PROJ_NAME/global/networks/$GCLOUD_PROJ_NAME-vpc" \
--subnetwork "projects/$GCLOUD_PROJ_NAME/regions/us-west2/subnetworks/backend-magento" \
--addons HorizontalPodAutoscaling,HttpLoadBalancing \
--enable-autoupgrade --enable-autorepair

# Firewall rule for Rabbit and Kubernetes
gcloud compute firewall-rules create $GCLOUD_PROJ_NAME-rabbit-kubernetes \
--description="Connectivity between Kubernetes cluster and Rabbitmq instance of $GCLOUD_PROJ_NAME." \
--direction=INGRESS \
--priority=1000 \
--network=$GCLOUD_PROJ_NAME-vpc --action=ALLOW \
--rules=tcp:5672 \
--source-ranges=10.0.0.0/8


# Firewall rule for Elastic Search and Kubernetes
gcloud compute firewall-rules create $GCLOUD_PROJ_NAME-elasticsearch-kubernetes \
--description="Connectivity between Kubernetes cluster and Elastic Search instance of $GCLOUD_PROJ_NAME." \
--direction=INGRESS --priority=1000 \
--network=$GCLOUD_PROJ_NAME-vpc --action=ALLOW \
--rules=tcp:9200 --source-ranges=10.0.0.0/8


```

- Connect to Messaging server created and install Rabbitmq as described [here](https://devdocs.magento.com/guides/v2.3/install-gde/prereq/install-rabbitmq.html
).

```bash
gcloud compute ssh $GCLOUD_PROJ_NAME-messaging
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
gcloud compute ssh $GCLOUD_PROJ_NAME-search
```

- Create a MySQL database on Google SQL as described [here](https://cloud.google.com/sql/docs/mysql/create-manage-databases). Save the address and details.

- Create schema and user with privileges into the database. Save the details.

- Enable the 'Private IP' option of your database on the Gcloud console and choose your VPC.

- Configure Kubernetes to use the GC Kubernetes installation as described [here](https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-access-for-kubectl).

- Configure the environment variables on kubernetes files:
    - On `kubernetes/02_rabbit-service.yaml` file, configure the Rabbit address
    - On `kubernetes/03_elasticsearch-service.yaml` file, configure the Elastic search address
    - On `kubernetes/07_phpfpm-deployment.yaml` file, configure the environment values (`env` section) with the desired values (and values obtained on previous steps from servers and database instance). 

- Run Kubernetes files one by one. Wait after each service/deployment/volume is ready to run the next. You can verify with the command `kubectl get all` to show if it is running.

```bash
kubectl create -f kubernetes/01_appdata-persistentvolumeclaim.yaml
kubectl create -f kubernetes/02_rabbit-service.yaml
kubectl create -f kubernetes/03_elasticsearch-service.yaml
kubectl create -f kubernetes/04_redis-deployment.yaml
kubectl create -f kubernetes/05_redis-service.yaml
kubectl create -f kubernetes/06_magento-service.yaml
kubectl create -f kubernetes/07_phpfpm-deployment.yaml
kubectl create -f kubernetes/08_phpfpm-service.yaml
kubectl create -f kubernetes/09_nginx-deployment.yaml
kubectl create -f kubernetes/10_nginx-service.yaml
```

- Once your Magento is running, login on the admin console and configure Elastic Search as described [here](https://devdocs.magento.com/guides/v2.3/config-guide/elasticsearch/es-config-nginx.html)

- Installation completed.


## Rebuil your own docker images

- Configure Magento Authentication keys copying `auth.json.sample` into `auth.json` and modifying the values for `<public-key>` and `<private-key>`.

- Magento PHP-FPM

```bash
docker build  -t magento2.3-phpfpm -f ./images/magento2.3-phpfpm/Dockerfile .
docker tag magento2.3-phpfpm <your dockerhub username>/magento2.3-phpfpm
docker push <your dockerhub username>/magento2.3-phpfpm
```

- Magento Nginx servre

```bash
docker build  -t magento2.3-nginx -f ./images/magento2.3-nginx/Dockerfile .
docker tag magento2.3-nginx <your dockerhub username>/magento2.3-nginx
docker push <your dockerhub username>/magento2.3-nginx
```

- Modify the Kubernetes files: `kubernetes/06_phpfpm-deployment.yaml`, `kubernetes/08_nginx-deployment.yaml` with the new images.


