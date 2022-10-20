# Kubernetes Kops with Terraform

This repository simplifies a Kubernetes Kops installation with the help of Terraform.

## Prerequisites

## Usage

### Create kops IAM user

Its recommended to use a non-admin user for creating the kops specific AWS resources like S3 buckets, DNS zones and the AMI.

Therfore, first call terraform with your admin user account to create an IAM user specific for kops.

```js
export AWS_ACCESS_KEY=$AWS_ACCESS_KEY_ADMIN_USER
export AWS_SECRET_KEY=$AWS_SECRET_KEY_ADMIN_USER
export TF_VAR_kops_domain=example.com
export TF_VAR_kops_sub_domain=k8s.example.com

terraform apply -target=aws_iam_access_key.kops

var.kops_domain
  Enter a value: example.com

var.kops_sub_domain
  Enter a value: k8s.example.com
```


### Create the Kops resources

When you created the kops IAM user, run this to use his secrets:

```js
export AWS_ACCESS_KEY_KOPS_USER=${$(terraform output kops_iam_key)//\"/}
export AWS_SECRET_KEY_KOPS_USER=${$(terraform output kops_iam_secret)//\"/}
```

Then, define the used domain in an env var, and create the kops resources:

```js
export TF_VAR_kops_domain=example.com
export TF_VAR_kops_sub_domain=k8s.example.com

terraform apply
```

Finally, grab the nameserver information from the output variable, and enter this at your registrars:

```js
terraform output kops_name_servers
```

### Create the kops Cluster

When all AWS resources are ready:

```js
export KOPS_CLUSTER_NAME=$TF_VAR_kops_sub_domain
export KOPS_BUCKET_NAME=${$(terraform output kops_bucket_name)//\"/}
export KOPS_STATE_STORE=s3://${KOPS_BUCKET_NAME}

kops create cluster \
  --name=${KOPS_CLUSTER_NAME} \
  --cloud=aws \
  --ssh-public-key=.ssh/id_rsa.pub \
  --zones=eu-central-1a \
  --discovery-store=${KOPS_STATE_STORE}/${KOPS_CLUSTER_NAME}/discovery
```

Edit your cluster, then create it:

```js
kops edit cluster --name ${KOPS_CLUSTER_NAME}

kops update cluster --name ${KOPS_CLUSTER_NAME} --yes
```

Finally, access you cluster via kubeconfig...

```bash
kops export kubeconfig --admin
```

... or SSH into the master node:

```bash
ssh -i .ssh/id_rsa.key ubuntu@api.k8s.example.com
```

### Delete the Cluster

Destroy all AWS resources with the following command:

```bash
export AWS_ACCESS_KEY=$AWS_ACCESS_KEY_ADMIN_USER
export AWS_SECRET_KEY=$AWS_SECRET_KEY_ADMIN_USER

terraform destroy
```