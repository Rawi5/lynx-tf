locals {
  ondemand-apps-node-userdata = <<USERDATA
${local.worker-node-userdata}
/etc/eks/bootstrap.sh --kubelet-extra-args --node-labels=nodetype=stateful,nodegroup=apps,node-ip=$NODE_IP --apiserver-endpoint '${data.aws_eks_cluster.eks-cluster.endpoint}' --b64-cluster-ca '${data.aws_eks_cluster.eks-cluster.certificate_authority.0.data}' '${var.cluster-name}'
USERDATA
}

resource "aws_launch_configuration" "eks-launch-config-apps-ondemand" {
  associate_public_ip_address = false
  iam_instance_profile        = "${data.aws_iam_instance_profile.eks-node-profile.name}"
  image_id                    = "${data.aws_ami.eks-worker.id}"
  instance_type               = "m5.large"
  security_groups             = ["${data.aws_security_group.eks-node-private.id}"]
  user_data                   = "${base64encode(local.ondemand-apps-node-userdata )}"
  key_name                    = "${var.cluster-name}-kp"
  name                        = "${var.cluster-name}-ondemand-apps"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "eks-scaling-group-ondemand-apps" {
  desired_capacity     = 3
  launch_configuration = "${aws_launch_configuration.eks-launch-config-apps-ondemand.id}"
  max_size             = 5
  min_size             = 3
  name                 = "${var.cluster-name}-ondemand-apps"
  vpc_zone_identifier  = ["${data.aws_subnet.eks-subnet-private.id}"]

  tags = [
    {
      key                 = "Name"
      value               = "${var.cluster-name}-eks-ondemand-apps-${count.index}"
      propagate_at_launch = true
    },
    {
      key                 = "kubernetes.io/cluster/${var.cluster-name}"
      value               = "shared"
      propagate_at_launch = true
    },
    {
      key                 = "lifecycle"
      value               = "ondemand"
      propagate_at_launch = true
    },
    {
      key                 = "NodeEnv"
      value               = "stateful"
      propagate_at_launch = true
    },
  ]
}
