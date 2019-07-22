locals {
  system-node-userdata = <<USERDATA
${local.worker-node-userdata}
/etc/eks/bootstrap.sh --kubelet-extra-args --node-labels=nodetype=stateful,appgroup=system,node-ip=$NODE_IP --apiserver-endpoint '${data.aws_eks_cluster.eks-cluster.endpoint}' --b64-cluster-ca '${data.aws_eks_cluster.eks-cluster.certificate_authority.0.data}' '${var.cluster-name}'
USERDATA

  datanodes-node-userdata = <<USERDATA
${local.worker-node-userdata}
/etc/eks/bootstrap.sh --kubelet-extra-args --node-labels=nodetype=stateful,appgroup=datanodes,node-ip=$NODE_IP --apiserver-endpoint '${data.aws_eks_cluster.eks-cluster.endpoint}' --b64-cluster-ca '${data.aws_eks_cluster.eks-cluster.certificate_authority.0.data}' '${var.cluster-name}'
USERDATA

  secure-node-userdata = <<USERDATA
${local.worker-node-userdata}
/etc/eks/bootstrap.sh --kubelet-extra-args --node-labels=nodetype=stateful,appgroup=secure,node-ip=$NODE_IP --apiserver-endpoint '${data.aws_eks_cluster.eks-cluster.endpoint}' --b64-cluster-ca '${data.aws_eks_cluster.eks-cluster.certificate_authority.0.data}' '${var.cluster-name}'
USERDATA

  public-node-userdata = <<USERDATA
${local.worker-node-userdata}
/etc/eks/bootstrap.sh --kubelet-extra-args --node-labels=nodetype=stateful,appgroup=corp-apps,node-ip=$NODE_IP --apiserver-endpoint '${data.aws_eks_cluster.eks-cluster.endpoint}' --b64-cluster-ca '${data.aws_eks_cluster.eks-cluster.certificate_authority.0.data}' '${var.cluster-name}'
USERDATA
}

resource "aws_instance" "public-node" {
  count                  = 1
  ami                    = "${data.aws_ami.eks-worker.id}"
  instance_type          = "t3.small"
  key_name               = "${var.cluster-name}-kp"
  vpc_security_group_ids = ["${data.aws_security_group.eks-node-private.id}","${data.aws_security_group.eks-node-corporate.id}"]
  user_data_base64       = "${base64encode(local.public-node-userdata )}"
  subnet_id              = "${data.aws_subnet.eks-subnet-public-a.id}"
  iam_instance_profile   = "${data.aws_iam_instance_profile.eks-node-profile.name}"

  associate_public_ip_address = true
  source_dest_check           = false

  root_block_device = {
    delete_on_termination = true
    volume_size           = 20
    volume_type           = "gp2"
  }

  tags = "${
    map(
     "Name", "${var.cluster-name}-eks-public-node-${count.index}",
     "kubernetes.io/cluster/${var.cluster-name}", "shared",
    )
  }"
}

resource "aws_instance" "system-nodes" {
  count                  = 2
  ami                    = "${data.aws_ami.eks-worker.id}"
  instance_type          = "t3.medium"
  key_name               = "${var.cluster-name}-kp"
  vpc_security_group_ids = ["${data.aws_security_group.eks-node-secure.id}"]
  user_data_base64       = "${base64encode(local.system-node-userdata )}"
  subnet_id              = "${data.aws_subnet.eks-subnet-private.id}"
  iam_instance_profile   = "${data.aws_iam_instance_profile.eks-node-profile.name}"

  associate_public_ip_address = false
  source_dest_check           = false

  root_block_device = {
    delete_on_termination = true
    volume_size           = 20
    volume_type           = "gp2"
  }

  tags = "${
    map(
     "Name", "${var.cluster-name}-eks-repo-node-${count.index}",
     "kubernetes.io/cluster/${var.cluster-name}", "shared",
    )
  }"
}

resource "aws_instance" "data-nodes" {
  count                  = 2
  ami                    = "${data.aws_ami.eks-worker.id}"
  instance_type          = "t3.medium"
  key_name               = "${var.cluster-name}-kp"
  vpc_security_group_ids = ["${data.aws_security_group.eks-node-private.id}"]
  user_data_base64       = "${base64encode(local.datanodes-node-userdata )}"
  subnet_id              = "${data.aws_subnet.eks-subnet-private.id}"
  iam_instance_profile   = "${data.aws_iam_instance_profile.eks-node-profile.name}"

  associate_public_ip_address = false
  source_dest_check           = false

  root_block_device = {
    delete_on_termination = true
    volume_size           = 20
    volume_type           = "gp2"
  }

  tags = "${
    map(
     "Name", "${var.cluster-name}-eks-data-node-${count.index}",
     "kubernetes.io/cluster/${var.cluster-name}", "shared",
    )
  }"
}


