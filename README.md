# Kubernetes Kops with Terraform

This repository accelerates a Kubernetes kops installation with the help of Terraform.

It installs the latest Kubernetes version available to `kops` and you can customize several aspects, see below.

## Prerequisites

- [AWS account](https://aws.amazon.com/account/)
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [Terraform CLI](https://developer.hashicorp.com/terraform/downloads)
- [kops CLI](https://kops.sigs.k8s.io/getting_started/install/)
- A domain name and a CLI/API/GUI to define its nameserver entries

## Usage

### 1. Define Domain, Sub-Domain, and AWS Region

Customize the following environment variables for your purpose:

```bash
export TF_VAR_kops_domain=example.com
export TF_VAR_kops_sub_domain=k8s.example.com
export TF_VAR_kops_aws_region=eu-central-1
```

### 2a. AWS Resource Creation with Custom IAM User

It’s recommended to use a non-admin user for creating the kops specific AWS resources like S3 buckets, DNS zones and the EC2 instances.

Therefore, first call terraform with your admin user account to create an IAM user specific for kops.

```bash
export AWS_ACCESS_KEY=$AWS_ACCESS_KEY_ADMIN_USER
export AWS_SECRET_KEY=$AWS_SECRET_KEY_ADMIN_USER

terraform init
terraform apply -target=aws_iam_access_key.kops
```

Then, use the IAM user to create all other resources:

```bash
export AWS_ACCESS_KEY_KOPS_USER=${$(terraform output kops_iam_key)//\"/}
export AWS_SECRET_KEY_KOPS_USER=${$(terraform output kops_iam_secret)//\"/}

terraform apply
```

### 2b. AWS Resource Creation with AWS root User

Not recommended, but you can create all AWS resources with your default AWS root user:

```bash
export AWS_ACCESS_KEY=$AWS_ACCESS_KEY_ADMIN_USER
export AWS_SECRET_KEY=$AWS_SECRET_KEY_ADMIN_USER

terraform init
terraform apply
```

### 3. Nameserver Registration

Get the nameserver information and enter them at your registrar:

```bash
terraform output kops_name_servers
```

### 4. Initialize the kops Cluster

One-shot installation without any customization:

```bash
export KOPS_CLUSTER_NAME=$TF_VAR_kops_sub_domain
export KOPS_BUCKET_NAME=${$(terraform output kops_bucket_name)//\"/}
export KOPS_STATE_STORE=s3://${KOPS_BUCKET_NAME}

kops create cluster \
  --name=${KOPS_CLUSTER_NAME} \
  --cloud=aws \
  --ssh-public-key=.ssh/id_rsa.pub \
  --zones=${TF_VAR_kops_aws_region}a \
  --discovery-store=${KOPS_STATE_STORE}/${KOPS_CLUSTER_NAME}/discovery
  --yes
```

Or you separate the initialization, customization and building steps:

```bash
export KOPS_CLUSTER_NAME=$TF_VAR_kops_sub_domain
export KOPS_BUCKET_NAME=${$(terraform output kops_bucket_name)//\"/}
export KOPS_STATE_STORE=s3://${KOPS_BUCKET_NAME}

kops create cluster \
  --name=${KOPS_CLUSTER_NAME} \
  --cloud=aws \
  --ssh-public-key=.ssh/id_rsa.pub \
  --zones=${TF_VAR_kops_aws_region}a \
  --discovery-store=${KOPS_STATE_STORE}/${KOPS_CLUSTER_NAME}/discovery

kops edit cluster \
  --name=${KOPS_CLUSTER_NAME}

kops update cluster \
  --name ${NAME} \
  --yes \
```

### 5. Access the kops Cluster

Use `kops` to get the `kubeconfig` file

```bash
kops validate cluster --wait 10m && kops export kubeconfig --admin
```

Or access the master node via SSH:

```bash
ssh -i .ssh/id_rsa.key ubuntu@api.${KOPS_CLUSTER_NAME}
```

## Customization

The configuration of a `kops` Kubernetes cluster is contained om a YAML file.  You can configure the Kubernetes version and many otther aspects of your cluster, check the [kops documentation](https://kops.sigs.k8s.io/cluster_spec/).

Run this command...

```bash
kops edit cluster --name ${KOPS_CLUSTER_NAME}
````

... and update the cluster:

```bash
kops update cluster --name ${KOPS_CLUSTER_NAME} --yes
```

## Delete the Cluster

Destroy everything:

```bash
# this can take a couple of minutes
kops delete cluster --name ${KOPS_CLUSTER_NAME} --yes

export AWS_ACCESS_KEY=$AWS_ACCESS_KEY_ADMIN_USER
export AWS_SECRET_KEY=$AWS_SECRET_KEY_ADMIN_USER
terraform destroy -auto-approve
```

## Known Bugs

- When installing Kubernetes Version `>1.25.1`, there is a pending `ebs-csi-controller` deployment. On the master node, run `kubectl scale deploy ebs-csi-controller --replicas=1 -n kube-system` to fix it and you cluster should work
