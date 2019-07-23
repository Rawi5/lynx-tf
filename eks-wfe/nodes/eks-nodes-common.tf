# Variables
variable "cluster-name" {}

variable "instance_types" {
  default = {
    primary   = "m5.large"
    secondary = "r4.large"
  }
}

variable "notify_webhook" {
  default = ""
}

variable "spot_prices" {
  default = {
    main      = "0.1"
    primary   = "0.05"
    secondary = "0.06"
  }
}

data "aws_availability_zones" "az" {}

data "aws_iam_instance_profile" "eks-node-profile" {
  name = "${var.cluster-name}-node"
}

data "aws_ami" "eks-worker" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-1.11*"]
  }

  most_recent = true
  owners      = ["602401143452"] # Amazon Account ID
}

data "aws_eks_cluster" "eks-cluster" {
  name = "${var.cluster-name}"
}

data "aws_vpc" "eks-vpc" {
  tags = "${
    map(
     "Name", "${var.cluster-name}",
     "kubernetes.io/cluster/${var.cluster-name}", "shared",
    )
  }"
}

data "aws_subnet" "eks-subnet-private" {
  vpc_id = "${data.aws_vpc.eks-vpc.id}"

  tags = "${
    map(
     "Name", "${var.cluster-name}-private",
     "kubernetes.io/cluster/${var.cluster-name}", "shared",
    )
  }"
}

data "aws_subnet" "eks-subnet-public-a" {
  vpc_id = "${data.aws_vpc.eks-vpc.id}"

  tags = "${
    map(
     "Name", "${var.cluster-name}-public-a",
     "kubernetes.io/cluster/${var.cluster-name}", "shared",
    )
  }"
}

data "aws_security_group" "eks-node-private" {
  name = "${var.cluster-name}-node-private"
}

data "aws_security_group" "eks-node-secure" {
  name = "${var.cluster-name}-node-secure"
}

data "aws_security_group" "eks-node-corporate" {
  name = "${var.cluster-name}-corporate"
}

locals {
  worker-node-userdata = <<USERDATA
#!/bin/bash
set -o xtrace
yum update -y
STATUS=$(curl -s -o /dev/null -w '%\{http_code\}' http://169.254.169.254/latest/meta-data/public-ipv4)

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
}

