locals {
  system-node-userdata = <<USERDATA
${local.worker-node-userdata}
/etc/eks/bootstrap.sh --kubelet-extra-args --node-labels=nodetype=stateful,appgroup=system,node-ip=$NODE_IP --apiserver-endpoint '${data.aws_eks_cluster.eks-cluster.endpoint}' --b64-cluster-ca '${data.aws_eks_cluster.eks-cluster.certificate_authority.0.data}' '${var.cluster-name}'
USERDATA


  public-node-userdata = <<USERDATA
${local.worker-node-userdata}
/etc/eks/bootstrap.sh --kubelet-extra-args --node-labels=nodetype=stateful,nodegroup=public-apps,node-ip=$NODE_IP --apiserver-endpoint '${data.aws_eks_cluster.eks-cluster.endpoint}' --b64-cluster-ca '${data.aws_eks_cluster.eks-cluster.certificate_authority.0.data}' '${var.cluster-name}'
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


