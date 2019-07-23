variable "cluster-name" {}

variable "corporate_cidr_list" {
  type = "list"

  default = []
}

variable "vpcnet_prefix" {
  default = "10.10"
}

variable "notify_webhook" {
  default = ""
}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {}

data "aws_ami" "eks-worker" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-1.11*"]
  }

  most_recent = true
  owners      = ["602401143452"] # Amazon Account ID
}

data "aws_ami" "gateway" {
  filter {
    name   = "name"
    values = ["amzn-ami-vpc-nat-hvm-2018.*"]
  }

  most_recent = true
  owners      = ["amazon"] # Amazon Account ID
}

resource "aws_vpc" "eks-vpc" {
  cidr_block           = "${var.vpcnet_prefix}.0.0/16"
  enable_dns_hostnames = true

  tags = "${
    map(
     "Name", "${var.cluster-name}",
     "kubernetes.io/cluster/${var.cluster-name}", "shared",
    )
  }"
}

resource "aws_subnet" "eks-public-a" {
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
  cidr_block        = "${var.vpcnet_prefix}.1.0/24"
  vpc_id            = "${aws_vpc.eks-vpc.id}"

  tags = "${
    map(
     "Name", "${var.cluster-name}-public-a",
     "kubernetes.io/cluster/${var.cluster-name}", "shared",
    )
  }"
}

resource "aws_subnet" "eks-public-b" {
  availability_zone = "${data.aws_availability_zones.available.names[1]}"
  cidr_block        = "${var.vpcnet_prefix}.2.0/24"
  vpc_id            = "${aws_vpc.eks-vpc.id}"

  tags = "${
    map(
     "Name", "${var.cluster-name}-public-b",
     "kubernetes.io/cluster/${var.cluster-name}", "shared",
    )
  }"
}

resource "aws_subnet" "eks-subnet-private" {
  cidr_block        = "${var.vpcnet_prefix}.5.0/24"
  vpc_id            = "${aws_vpc.eks-vpc.id}"
  availability_zone = "${data.aws_availability_zones.available.names[0]}"

  tags = "${
    map(
     "Name", "${var.cluster-name}-private",
     "kubernetes.io/cluster/${var.cluster-name}", "shared",
    )
  }"
}

resource "aws_subnet" "eks-subnet-private-b" {
  cidr_block        = "${var.vpcnet_prefix}.6.0/24"
  vpc_id            = "${aws_vpc.eks-vpc.id}"
  availability_zone = "${data.aws_availability_zones.available.names[1]}"

  tags = "${
    map(
     "Name", "${var.cluster-name}-private-b",
     "kubernetes.io/cluster/${var.cluster-name}", "shared",
    )
  }"
}

resource "aws_internet_gateway" "eks-igw" {
  vpc_id = "${aws_vpc.eks-vpc.id}"

  tags {
    Name = "${var.cluster-name}"
  }
}

resource "aws_route_table" "eks-rt" {
  vpc_id = "${aws_vpc.eks-vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.eks-igw.id}"
  }

  tags {
    Name = "${var.cluster-name}-rt-public"
  }
}

resource "aws_route_table" "eks-rt-private" {
  vpc_id = "${aws_vpc.eks-vpc.id}"

  route {
    cidr_block  = "0.0.0.0/0"
    instance_id = "${aws_instance.system-gateway.id}"
  }

  tags {
    Name = "${var.cluster-name}-rt-private"
  }
}

resource "aws_route_table_association" "eks-rta-b" {
  subnet_id      = "${aws_subnet.eks-public-a.id}"
  route_table_id = "${aws_route_table.eks-rt.id}"
}

resource "aws_route_table_association" "eks-rta-a" {
  subnet_id      = "${aws_subnet.eks-public-b.id}"
  route_table_id = "${aws_route_table.eks-rt.id}"
}

resource "aws_route_table_association" "eks-rta-private" {
  subnet_id      = "${aws_subnet.eks-subnet-private.id}"
  route_table_id = "${aws_route_table.eks-rt-private.id}"
}

resource "aws_route_table_association" "eks-rta-private-b" {
  subnet_id      = "${aws_subnet.eks-subnet-private-b.id}"
  route_table_id = "${aws_route_table.eks-rt-private.id}"
}

resource "aws_iam_role" "eks-master-role" {
  name = "${var.cluster-name}-master"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "master-cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = "${aws_iam_role.eks-master-role.name}"
}

resource "aws_iam_role_policy_attachment" "master-cluster-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = "${aws_iam_role.eks-master-role.name}"
}

resource "aws_iam_role_policy_attachment" "eks-node-EC2ReadOnly-master" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
  role       = "${aws_iam_role.eks-master-role.name}"
}

resource "aws_eks_cluster" "eks-cluster" {
  name     = "${var.cluster-name}"
  role_arn = "${aws_iam_role.eks-master-role.arn}"

  vpc_config {
    security_group_ids = ["${aws_security_group.eks-cluster-master.id}"]
    subnet_ids         = ["${aws_subnet.eks-public-a.id}", "${aws_subnet.eks-public-b.id}"]
  }

  depends_on = [
    "aws_iam_role_policy_attachment.master-cluster-AmazonEKSClusterPolicy",
    "aws_iam_role_policy_attachment.master-cluster-AmazonEKSServicePolicy",
  ]
}

resource "aws_iam_role" "eks-node" {
  name = "${var.cluster-name}-node"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "eks-node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = "${aws_iam_role.eks-node.name}"
}

resource "aws_iam_role_policy_attachment" "eks-node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = "${aws_iam_role.eks-node.name}"
}

resource "aws_iam_role_policy_attachment" "eks-node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = "${aws_iam_role.eks-node.name}"
}

resource "aws_iam_role_policy_attachment" "eks-node-EC2ReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
  role       = "${aws_iam_role.eks-node.name}"
}

resource "aws_iam_role_policy_attachment" "eks-node-EC2LoadBalancing" {
  policy_arn = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
  role       = "${aws_iam_role.eks-node.name}"
}

resource "aws_iam_role_policy_attachment" "eks-node-AWSCertificateManagerReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AWSCertificateManagerReadOnly"
  role       = "${aws_iam_role.eks-node.name}"
}

resource "aws_iam_instance_profile" "eks-node-profile" {
  name = "${var.cluster-name}-node"
  role = "${aws_iam_role.eks-node.name}"
}

resource "aws_security_group" "eks-cluster-master" {
  name        = "${var.cluster-name}-master"
  description = "Cluster communication with worker nodes"
  vpc_id      = "${aws_vpc.eks-vpc.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "self"
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${aws_vpc.eks-vpc.cidr_block}"]
    description = "ingress from cluster vpc"
  }

  tags {
    Name = "${var.cluster-name}-master"
  }
}

resource "aws_security_group" "eks-transit" {
  name        = "${var.cluster-name}-transit"
  description = "Transit SG"
  vpc_id      = "${aws_vpc.eks-vpc.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "self"
  }

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = ["${aws_security_group.eks-corporate.id}"]
  }

  tags {
    Name = "${var.cluster-name}-transit"
  }
}

resource "aws_security_group" "eks-node" {
  name        = "${var.cluster-name}-node"
  description = "Security group for all nodes in the cluster"
  vpc_id      = "${aws_vpc.eks-vpc.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
    description = "self"
  }

  ingress {
    from_port       = 1025
    to_port         = 65535
    protocol        = "tcp"
    security_groups = ["${aws_security_group.eks-cluster-master.id}"]
  }

  ingress {
    from_port       = 30000
    to_port         = 35000
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = ["${aws_security_group.eks-cluster-master.id}"]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = ["${aws_security_group.gateway.id}"]
  }

  tags = "${
    map(
    "Name", "${var.cluster-name}-nodes",
     "kubernetes.io/cluster/${var.cluster-name}", "owned",
    )
  }"
}

resource "aws_security_group" "eks-node-private" {
  name        = "${var.cluster-name}-node-private"
  description = "Security group for all private nodes in the cluster"
  vpc_id      = "${aws_vpc.eks-vpc.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
    description = "self"
  }

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = ["${aws_security_group.eks-corporate.id}"]
    description     = "eks-corporate"
  }

  ingress {
    from_port       = 1025
    to_port         = 65535
    protocol        = "tcp"
    security_groups = ["${aws_security_group.eks-cluster-master.id}"]
    description     = "eks-cluster-master"
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = ["${aws_security_group.eks-cluster-master.id}"]
    description     = "eks-cluster-master"
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = ["${aws_security_group.gateway.id}"]
    description     = "gateway"
  }

  tags = "${
    map(
    "Name", "${var.cluster-name}-nodes-private",
     "kubernetes.io/cluster/${var.cluster-name}", "owned",
    )
  }"
}

resource "aws_security_group" "eks-node-secure" {
  name        = "${var.cluster-name}-node-secure"
  description = "Security group for all secure nodes in the cluster"
  vpc_id      = "${aws_vpc.eks-vpc.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
    description = "self"
  }

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = ["${aws_security_group.eks-node-private.id}"]
    description     = "eks-node-private"
  }

  ingress {
    from_port       = 1025
    to_port         = 65535
    protocol        = "tcp"
    security_groups = ["${aws_security_group.eks-cluster-master.id}"]
    description     = "eks-cluster-master "
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = ["${aws_security_group.eks-cluster-master.id}"]
    description     = "eks-cluster-master"
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = ["${aws_security_group.gateway.id}"]
    description     = "gateway"
  }

  tags = "${
    map(
    "Name", "${var.cluster-name}-nodes-secure",
     "kubernetes.io/cluster/${var.cluster-name}", "owned",
    )
  }"
}

resource "aws_security_group" "eks-public-web" {
  name        = "${var.cluster-name}-public-web"
  description = "Security group for public web ports"
  vpc_id      = "${aws_vpc.eks-vpc.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
    description = "self"
  }

 

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${
    map(
    "Name", "${var.cluster-name}-public-web",
     "kubernetes.io/cluster/${var.cluster-name}", "owned",
    )
  }"
}
resource "aws_security_group" "eks-corporate" {
  name        = "${var.cluster-name}-corporate"
  description = "Security group for all coporate communications"
  vpc_id      = "${aws_vpc.eks-vpc.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
    description = "self"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["${aws_vpc.eks-vpc.cidr_block}"]
    description = "cluster VPC"
  }

  ingress {
    from_port       = 1025
    to_port         = 65535
    protocol        = "tcp"
    security_groups = ["${aws_security_group.eks-cluster-master.id}"]
    description     = "eks-cluster-master"
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = ["${aws_security_group.eks-cluster-master.id}"]
    description     = "eks-cluster-master"
  }

  tags = "${
    map(
    "Name", "${var.cluster-name}-corp",
     "kubernetes.io/cluster/${var.cluster-name}", "owned",
    )
  }"
}

resource "aws_security_group" "gateway" {
  name        = "${var.cluster-name}-gateway"
  description = "Security group for all nodes in the cluster"
  vpc_id      = "${aws_vpc.eks-vpc.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "public ssh"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["${aws_vpc.eks-vpc.cidr_block}"]
    description = "Cluster VPC"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${aws_vpc.eks-vpc.cidr_block}"]
    description = "Cluster VPC"
  }

  tags {
    Name = "${var.cluster-name}-gateway"
  }
}

resource "aws_security_group_rule" "eks-node-ingress-corporate" {
  count             = 1
  cidr_blocks       = ["${var.corporate_cidr_list[count.index]}"]
  description       = "Allow corporate networks to communicate with nodes"
  from_port         = 0
  protocol          = "tcp"
  security_group_id = "${aws_security_group.eks-corporate.id}"
  to_port           = 65535
  type              = "ingress"
}

resource "aws_security_group_rule" "master-cluster-ingress-trusted" {
  count             = 1
  cidr_blocks       = ["${var.corporate_cidr_list[count.index]}"]
  description       = "Allow corporate networks to communicate with nodes"
  from_port         = 0
  protocol          = "tcp"
  security_group_id = "${aws_security_group.eks-cluster-master.id}"
  to_port           = 65535
  type              = "ingress"
}

locals {
  kubeconfig = <<KUBECONFIG


apiVersion: v1
clusters:
- cluster:
    server: ${aws_eks_cluster.eks-cluster.endpoint}
    certificate-authority-data: ${aws_eks_cluster.eks-cluster.certificate_authority.0.data}
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: aws
  name: aws
current-context: aws
kind: Config
preferences: {}
users:
- name: aws
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      command: /usr/local/bin/heptio-authenticator-aws
      args:
        - "token"
        - "-i"
        - "${var.cluster-name}"
KUBECONFIG

  config-map-aws-auth = <<CONFIGMAPAWSAUTH


apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: ${aws_iam_role.eks-node.arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
CONFIGMAPAWSAUTH

  config-role-binding = <<CONFIGROLEBINDING


apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: eks-admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: eks-admin
  namespace: kube-system
CONFIGROLEBINDING

tiller-rbac = <<TILLERROLEBINDING


apiVersion: v1
kind: ServiceAccount
metadata:
  name: tiller
  namespace: kube-system
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: tiller-clusterrolebinding
subjects:
- kind: ServiceAccount
  name: tiller
  namespace: kube-system
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: ""
TILLERROLEBINDING

  config-service-account = <<CONFIGSERVICEACCOUNT

apiVersion: v1
kind: ServiceAccount
metadata:
  name: eks-admin
  namespace: kube-system
CONFIGSERVICEACCOUNT

  ebs-storage = <<STORAGEYAML
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: standard
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp2
reclaimPolicy: Retain
mountOptions:
  - debug  
---
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: standard-a
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp2
  zone: ${data.aws_availability_zones.available.names[0]}
reclaimPolicy: Retain
mountOptions:
  - debug
---
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: standard-b
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp2
  zone: ${data.aws_availability_zones.available.names[1]}
reclaimPolicy: Retain
mountOptions:
  - debug
---
STORAGEYAML

  letsencrypt_policy = <<LETSENCRYPT_POLICY
apiVersion: certmanager.k8s.io/v1alpha1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: 'devops@stacklynx.com'
    privateKeySecretRef:
      name: letsencrypt-staging
    http01: {}
---
apiVersion: certmanager.k8s.io/v1alpha1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: 'devops@stacklynx.com'
    privateKeySecretRef:
      name: letsencrypt-prod
    http01: {}

LETSENCRYPT_POLICY


}

resource "local_file" "kube_cfg" {
  content  = "${local.kubeconfig}"
  filename = "${path.module}/output/${var.cluster-name}-cfg.yaml"
}

resource "local_file" "kube_auth" {
  content  = "${local.config-map-aws-auth}"
  filename = "${path.module}/output/${var.cluster-name}-aws-auth.yaml"
}

resource "local_file" "kube_service_account" {
  content  = "${local.config-service-account}"
  filename = "${path.module}/output/${var.cluster-name}-service-account.yaml"
}

resource "local_file" "kube_role_binding" {
  content  = "${local.config-role-binding}"
  filename = "${path.module}/output/${var.cluster-name}-role-binding.yaml"
}

resource "local_file" "tiller_rbac" {
  content  = "${local.tiller-rbac}"
  filename = "${path.module}/output/${var.cluster-name}-tiller-rbac.yaml"
}

resource "local_file" "eks-storage-file" {
  content  = "${local.ebs-storage}"
  filename = "${path.module}/output/${var.cluster-name}-storage.yaml"
}

resource "local_file" "letsencrypt_policy_file" {
  content  = "${local.letsencrypt_policy}"
  filename = "${path.module}/output/${var.cluster-name}-letsencryptpolicy.yaml"
}

locals {
  eks-run-script = <<RUNSCRIPT

export AWS_ACCESS_KEY_ID=${var.aws_access_key}
export AWS_SECRET_ACCESS_KEY=${var.aws_secret_key}
sleep 30
export KUBECONFIG=${local_file.kube_cfg.filename}
kubectl apply -f ${local_file.kube_auth.filename}
kubectl get componentstatus 
kubectl get nodes
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/recommended/kubernetes-dashboard.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/influxdb/heapster.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/influxdb/influxdb.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/rbac/heapster-rbac.yaml

#kubectl apply -f ${local_file.tiller_rbac.filename}
#helm init --node-selectors "appgroup"="system" --tiller-namespace kube-system --tiller-service-account tiller

# Create service accounts
kubectl apply -f ${local_file.kube_service_account.filename}
kubectl apply -f ${local_file.kube_role_binding.filename}

#create storage class and volumes
kubectl apply -f ${local_file.eks-storage-file.filename}


#setup helm for the cluster
kubectl create serviceaccount --namespace kube-system tiller
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
helm init --service-account tiller
sleep 30

helm install --name nginx-ingress stable/nginx-ingress --set rbac.create=true --namespace ingress-nginx

helm install stable/cert-manager \
    --namespace ingress-nginx  \
    --set ingressShim.defaultIssuerName=letsencrypt-prod \
    --set ingressShim.defaultIssuerKind=ClusterIssuer \
    --version v0.5.2

kubectl apply -f ${local_file.letsencrypt_policy_file.filename} -n ingress-nginx


APISERVER=$(kubectl config view | grep server | cut -f 2- -d ":" | tr -d " ")
TOKEN=$(kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep eks-admin | cut -f1 -d ' ') | grep -E '^token' | cut -f2 -d':' | tr -d '\t')

echo TOKEN:$TOKEN
echo APISERVER:$APISERVER
echo $TOKEN > ${path.module}/output/${var.cluster-name}.token

RUNSCRIPT

  eks-auth-keys = <<RUNSCRIPT

export AWS_ACCESS_KEY_ID=${var.aws_access_key}
export AWS_SECRET_ACCESS_KEY=${var.aws_secret_key}
export KUBECONFIG=${local_file.kube_cfg.filename}

RUNSCRIPT
}

resource "local_file" "eks-auth-keys-file" {
  content  = "${local.eks-auth-keys }"
  filename = "${path.module}/output/${var.cluster-name}-auth-keys.sh"

  provisioner "local-exec" {
    command = "chmod +x ${local_file.eks-auth-keys-file.filename}"
  }
}

resource "local_file" "eks-run-script" {
  content  = "${local.eks-run-script}"
  filename = "${path.module}/output/${var.cluster-name}.sh"

  provisioner "local-exec" {
    command = "chmod +x ${local_file.eks-run-script.filename}"
  }

  provisioner "local-exec" {
    command = "${local_file.eks-run-script.filename}"
  }
}

locals {
  worker-node-userdata = <<USERDATA
#!/bin/bash
set -o xtrace
yum update -y
STATUS=$(curl -s -o /dev/null -w '%{http_code}' http://169.254.169.254/latest/meta-data/public-ipv4)

if [ $STATUS -eq 200 ]; then
 NODE_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
else
 NODE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
fi

MEMORY=$(free -m | awk 'NR==2{printf "Memory: %s/%sMB (%.2f%%)\n", $3,$2,$3*100/$2 }')
DISK=$(df -h | awk '$NF=="/"{printf "Disk: %d/%dGB (%s)\n", $3,$2,$5}')
CPU=$(cat /proc/cpuinfo | grep processor | wc -l)

NOTIFY_WEBHOOK=${var.notify_webhook}
HOSTNAME=`hostname`
CURR_DATE=`date`

if [ -z "$NOTIFY_WEBHOOK" ]; then
  CHAT_MSG="{\"username\":\"eks-cluster:  ${var.cluster-name}\",    \"text\": \"Hostname:  $HOSTNAME NODE-IP:$NODE_IP  started at  $CURR_DATE\", \"attachments\": [ {\"title\": \"System Stats\", \"text\": \"$MEMORY  $DISK CPU Count:$CPU\"}]}"
  curl -d "$CHAT_MSG" -H "Content-Type: application/json" -X POST $NOTIFY_WEBHOOK
fi

USERDATA

  system-node-userdata = <<USERDATA
${local.worker-node-userdata}
/etc/eks/bootstrap.sh --kubelet-extra-args --node-labels=nodetype=stateful,appgroup=system,node-ip=$NODE_IP --apiserver-endpoint '${aws_eks_cluster.eks-cluster.endpoint}' --b64-cluster-ca '${aws_eks_cluster.eks-cluster.certificate_authority.0.data}' '${var.cluster-name}'
USERDATA
}

resource "aws_instance" "system-node" {
  count                  = 2
  ami                    = "${data.aws_ami.eks-worker.id}"
  instance_type          = "t3.small"
  key_name               = "${var.cluster-name}-kp"
  vpc_security_group_ids = ["${aws_security_group.eks-node-secure.id}"]
  user_data_base64       = "${base64encode(local.system-node-userdata)}"
  subnet_id              = "${aws_subnet.eks-subnet-private.id}"
  iam_instance_profile   = "${aws_iam_instance_profile.eks-node-profile.name}"

  associate_public_ip_address = false
  source_dest_check           = false

  root_block_device = {
    delete_on_termination = true
    volume_size           = 20
  }

  tags = "${
    map(
     "Name", "${var.cluster-name}-eks-system-node-${count.index}",
     "kubernetes.io/cluster/${var.cluster-name}", "shared",
    )
  }"
}

resource "aws_instance" "system-gateway" {
  ami                    = "${data.aws_ami.gateway.id}"
  instance_type          = "t2.micro"
  key_name               = "${var.cluster-name}-kp"
  vpc_security_group_ids = ["${aws_security_group.gateway.id}"]
  subnet_id              = "${aws_subnet.eks-public-a.id}"
  user_data_base64       = "${base64encode(local.worker-node-userdata)}"

  associate_public_ip_address = true
  source_dest_check           = false

  root_block_device = {
    delete_on_termination = true
    volume_size           = 8
  }

  tags = "${
    map(
     "Name", "${var.cluster-name}-eks-system-gateway"
    )
  }"
}

resource "tls_private_key" "stack_ssh-kp" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "stack-kp" {
  key_name   = "${var.cluster-name}-kp"
  public_key = "${tls_private_key.stack_ssh-kp.public_key_openssh}"
}

resource "local_file" "stack-kp-key" {
  content  = "${tls_private_key.stack_ssh-kp.private_key_pem}"
  filename = "${path.module}/output/${var.cluster-name}-key.pem"

  provisioner "local-exec" {
    command = "chmod 600 ${local_file.stack-kp-key.filename}"
  }
}
