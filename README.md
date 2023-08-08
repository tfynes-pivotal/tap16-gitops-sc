# Tanzu App Platform - GitOps Demo Creator
![image](https://github.com/tfynes-pivotal/tap-gitops-sc/assets/6810491/cb6e38ad-57a7-4b4a-badb-03ed9d62818a)

This archive automates the deployment & configuration of an opinionated TAP cluster along with additional service operators and demonstration workloads.

Once deployed it will automatically reconcile any declared changes made to (your fork of this) gitOps repo.



It can be deployed to any kubernetes cluster on any cloud / infrastructure

## QUICK START / SETUP

### Installation Phases
  * Fork this repo
    * Update (search&replace any internal references to original repo location) (details below)
  * Download required cli tools (age, sops, ytt, git, kubectl, k9s)
  * Prepare sensitive configuration for TAP
    * Create encryption key (/clusters/taplab/sensitive-file-structures/sensitive-file-creators/1_create_age_secret.sh)
    * Create sops encrypted TAP configuration
  * Prepare non-sensitive configuration for TAP
    * Set DNS wildcard domain for cluster
    * Update any internal references in this repo to point to your fork

## Additional Implementation Details
* It uses the carvel toolchain ([tanzu cluster essentials](https://network.pivotal.io/products/tanzu-cluster-essentials)) to configure continuous reconciliation from this archive after initial deployment and configuration.
* The same configuration is used to monitor for application workload and service deployments allowing for the state of the target cluster to be driven off this repo for application deployment, lifecycle-management, upgrade, etc... as well as platform level configuration.
* Uses CertManager HTTP Solver to establish TLS based ingress platform-wide.
* Includes Tanzu Postgres Operator, allowing for declarative in-cluster postgres database provisioning for apps.
* Includes Spring Cloud Gateway Operator, allowing for declarative in-cluster micro-gateway
  * Spring Cloud Gateway routes configured to fascade demonstration applications, showing URL rewriting and API-Key based authentication support
* Tanzu Spring API-Portal enabled to provide;
  * auto-instrumentation of SpringCloudGateway routes via the operator's openapi doc endpoint
  * self-service API-Key management
* Hashicorp Vault explicitly helm deployed to provide an in-cluster backend for API-Key storage


## Prerequisites
* Compliant kubernetes cluster (GKE, AKE, EKS, TKG....)
* Image Registry (e.g. Dockerhub)
* Source Repository (e.g. Github)
* Wildcard DNS Domain (e.g. dyn.com)
* TanzuNet Credentials
* [optional] OIDC provider with account (e.g. okta developer account)

  * CLI Tooling
    * kubectl
    * k9s (optional but recommended)
    * git cli
    * ytt cli
    * yq cli
    * [age cli](https://github.com/FiloSottile/age#installation)
    * [sops cli](https://github.com/mozilla/sops/releases)
    * tanzu cli



## Installation HowTo

### Initial Setup
1. Secrets Encryption (cluster-config/sensitive-file-structures/sensitive-file-creators)
  * Create secrets encryption key "1_create_age_secret.sh"
  * Set your dockerhub & github account details into enviroment variables
  * Populate and encrypt tap-sensitive-values.yaml "2_populate_and_encrypt_tap_sensitive_values.sh"

cluster-config/sensitive-file-structures/sensitive-file-creators contains scripts to create tap-sensitive-values.sops.yaml from a template, taking secrets from env vars.

sensitive-file-structures/create_user-registry-dockerconfig-secret.sh creates sops encrypted user-registry-dockerconfig secret - needs to be copied over existing one in cluster-config/config

- need to remove/replace existing sops.yaml files as they use my age key and thus won't work in your cluster


### Creating Sensitive-Values Configuration Files
  



* Update all configuration files to refer to your wildcard DNS domain (global search/replace)

* Create target K8s Cluster

* Deploy Tanzu Cluster Essentials

* Deploy TAP 'sync' kApp

* Update wildcard DNS entry for global ingress to cluster (based on public IP provided by cluster to Contour)
  * Monitor for IP/CNAME as follows

```
kubectl -n tanzu-system-ingress get svc -w
```


## Notes

* Installation used SOPS-encrypted (sealed-secrets) allowing for safe use of a public gitops source repository






For detailed documentation, refer to [VMware Tanzu Application Platform Product Documentation](https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.5/tap/install-gitops-intro.html).

Secrets Encryption containing references to; [TAP Docs Reference](https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.5/tap/install-gitops-sops.html)

## Problems being worked on
* looking for dockerhub alternatives as rate-limits could bite and hurt your install (e.g bad-creds auth attempts)
* lots of copies of dockerhub creds stored in tap-sensitive-values and user-registry-dockerconfig secret 

* lots of 'self-references' in the repo, so global search and replace for the repo FQDN or subPaths as you modify them via your clone/fork

* rate limits for LetsEncrypt http-solver.. i think it's something like 6 cluster recreates for a given domain per week.. then you have a 60hour cool-off period.. so i go from *.akslab1.... to *.akslab2... when necessary.. and you can adjust the domain after install if your http-solvers fail and gitOps magic will remediate the issue with your cluster certs. (Did I mention how awesome the gitOps installation/operations model is?)


## My akslab / ekslab / gkelab create scripts (from my .bashrc)


create-akslab-cluster()

```
function create-akslab-cluster() {
  export AKS_CLUSTER_NAME="akslab"
  az login
  az group create --location $AKS_REGION --name $1
  az extension add --name aks-preview
  az feature register --name PodSecurityPolicyPreview --namespace Microsoft.ContainerService
  az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/PodSecurityPolicyPreview')].{Name:name,State:properties.state}"
  az provider register --namespace Microsoft.ContainerService
  az aks create --resource-group ${AKS_RESOURCE_GROUP} --name ${AKS_CLUSTER_NAME} --enable-oidc-issuer  --node-count 4 --enable-addons monitoring --node-vm-size Standard_DS3_v2 --node-osdisk-size 150  --kubernetes-version ${AKS_CLUSTER_VERSION}
  az aks get-credentials --resource-group ${AKS_RESOURCE_GROUP} --name ${AKS_CLUSTER_NAME}
  kubectl create clusterrolebinding tap-psp-rolebinding --group=system:authenticated --clusterrole=psp:privileged
}
```

create-ekslab-cluster() (yeah messy.. needs cleanup.. but works for me...) 
```
create-ekslab-cluster() {
  export EKS_CLUSTER_REGION=us-east-2
  export EKS_CLUSTER_NAME=ekslab
# use this line first time - to create durable cluster service role we can reuse when recreating our ekslab cluster
# export EKS_CLUSTER_SERVICE_ROLE=$(aws iam create-role --role-name "${EKS_CLUSTER_NAME}-eks-role" --assume-role-policy-document='{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"eks.amazonaws.com"},"Action": "sts:AssumeRole"}]}' --output text --query 'Role.Arn')

  export EKS_CLUSTER_SERVICE_ROLE=$(aws iam list-roles | grep ekslab | grep -m 1 "Arn" | awk -F'"' {'print $4'})
  echo EKS_CLUSTER_SERVICE_ROLE=$EKS_CLUSTER_SERVICE_ROLE
  aws iam attach-role-policy --role-name "${EKS_CLUSTER_NAME}-eks-role" --policy-arn arn:aws:iam::aws:policy/AmazonEKSServicePolicy
  aws iam attach-role-policy --role-name "${EKS_CLUSTER_NAME}-eks-role" --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy

# use this line first time - to create durable worker service role we can reuse when recreating our ekslab cluster
# export EKS_WORKER_SERVICE_ROLE=$(aws iam create-role --role-name "${CLUSTER_NAME}-eks-role" --assume-role-policy-document='{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"eks.amazonaws.com"},"Action": "sts:AssumeRole"}]}' --output text --query 'Role.Arn')

  export  EKS_WORKER_SERVICE_ROLE=$(aws iam list-roles | grep ekslab | grep worker | grep Arn | awk -F'"' {'print $4'})
  echo EKS_WORKER_SERVICE_ROLE=$EKS_WORKER_SERVICE_ROLE
  aws iam attach-role-policy --role-name "${EKS_CLUSTER_NAME}-eks-worker-role" --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy
  aws iam attach-role-policy --role-name "${EKS_CLUSTER_NAME}-eks-worker-role" --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy
  aws iam attach-role-policy --role-name "${EKS_CLUSTER_NAME}-eks-worker-role" --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly


# use this line first time - to create durable vpc
# export EKS_STACK_ID=$(aws cloudformation create-stack --stack-name ${EKS_CLUSTER_NAME} --template-url https://amazon-eks.s3.us-west-2.amazonaws.com/cloudformation/2020-10-29/amazon-eks-vpc-private-subnets.yaml --output text --query 'StackId')
 
  export EKS_STACK_ID=$(aws cloudformation list-stacks --output json | jq -r ".StackSummaries[] | select (.StackName == \"${EKS_CLUSTER_NAME}\").StackId")
  echo EKS_STACK_ID=$EKS_STACK_ID
  export EKS_SECURITY_GROUP=$(aws cloudformation describe-stacks --stack-name ${EKS_CLUSTER_NAME} --query "Stacks[0].Outputs[?OutputKey=='SecurityGroups'].OutputValue" --output text)
  echo EKS_SECURITY_GROUP=$EKS_SECURITY_GROUP
  export EKS_SUBNET_IDS=$(aws cloudformation describe-stacks --stack-name ${EKS_CLUSTER_NAME} --query "Stacks[0].Outputs[?OutputKey=='SubnetIds'].OutputValue" --output text)
  echo EKS_SUBNET_IDS=$EKS_SUBNET_IDS

# Create EKS cluster
aws eks create-cluster --name ${EKS_CLUSTER_NAME} --kubernetes-version 1.25 --role-arn "${EKS_CLUSTER_SERVICE_ROLE}" --resources-vpc-config subnetIds="${EKS_SUBNET_IDS}",securityGroupIds="${EKS_SECURITY_GROUP}"
aws eks wait cluster-active --name ${EKS_CLUSTER_NAME}


# Create EKS worker nodes
aws eks create-nodegroup --cluster-name ${EKS_CLUSTER_NAME} --kubernetes-version 1.25 --nodegroup-name "${EKS_CLUSTER_NAME}-node-group" --disk-size 100 --scaling-config minSize=3,maxSize=3,desiredSize=3 --subnets $(echo $EKS_SUBNET_IDS | sed 's/,/ /g') --instance-types t3a.2xlarge --node-role ${EKS_WORKER_SERVICE_ROLE}
aws eks wait nodegroup-active --cluster-name ${EKS_CLUSTER_NAME} --nodegroup-name ${EKS_CLUSTER_NAME}-node-group

aws eks update-kubeconfig --name ${EKS_CLUSTER_NAME}

# FIXES FOR PV'S TO WORK
sleep 10

#brew tap weaveworks/tap
#brew install weaveworks/tap/eksctl
eksctl utils associate-iam-oidc-provider  --region=${EKS_CLUSTER_REGION} --cluster=${EKS_CLUSTER_NAME} --approve
eksctl delete iamserviceaccount --name ebs-csi-controller-sa --namespace kube-system --cluster ${EKS_CLUSTER_NAME}
sleep 10
eksctl create iamserviceaccount --name ebs-csi-controller-sa --namespace kube-system --cluster ${EKS_CLUSTER_NAME} --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy  --approve   --role-name AmazonEKS_EBS_CSI_DriverRole
eksctl delete addon --name aws-ebs-csi-driver --cluster ${EKS_CLUSTER_NAME} --region ${EKS_CLUSTER_REGION}
sleep 10
eksctl create addon --name aws-ebs-csi-driver --cluster ${EKS_CLUSTER_NAME} --service-account-role-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/AmazonEKS_EBS_CSI_DriverRole --force
}
```


create-gkelab-cluster()
```
function create-gkelab-cluster() {
  export GKE_CLUSTER_NAME=gkelab
  export GKE_REGION=us-east1
  export GKE_CLUSTER_ZONE="$GKE_REGION-d"
  export USE_GKE_GCLOUD_AUTH_PLUGIN=True
  export GKE_CLUSTER_VERSION=$(gcloud container get-server-config --format="yaml(defaultClusterVersion)" --region $GKE_REGION | awk '/defaultClusterVersion:/ {print $2}')
  gcloud container clusters create $GKE_CLUSTER_NAME --region $GKE_REGION --cluster-version $GKE_CLUSTER_VERSION --machine-type "e2-standard-8" --num-nodes "3" --node-locations us-east1-c,us-east1-d
  gcloud container clusters get-credentials $GKE_CLUSTER_NAME --region $GKE_REGION
  kubectl create clusterrolebinding tap-psp-rolebinding --group=system:authenticated --clusterrole=gce:podsecuritypolicy:privileged
}
```