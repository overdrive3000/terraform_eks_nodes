locals {
  name_prefix = "${var.cluster_name}-${var.node_name}"

  eks-node-userdata = <<EOF
#!/bin/bash
# join node on cluster ${var.cluster_endpoint}
set -o xtrace
/etc/eks/bootstrap.sh ${var.cluster_name} --kubelet-extra-args '${var.kubelet_extra_args}'
EOF
}

resource "aws_key_pair" "eks-key" {
  key_name   = "${local.name_prefix}-key"
  public_key = "${var.pub_key_pair}"
}

resource "aws_security_group" "eks-node" {
  name        = "${local.name_prefix}-node"
  description = "Security group for all nodes in the cluster"
  vpc_id      = "${var.vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${
    map(
     "Name", "${local.name_prefix}-node",
     "kubernetes.io/cluster/${var.cluster_name}", "owned",
    )
  }"
}

resource "aws_security_group_rule" "eks-node-self-ingress" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = "${aws_security_group.eks-node.id}"
  source_security_group_id = "${aws_security_group.eks-node.id}"
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "eks-node-to-control-plane-ingress" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.eks-node.id}"
  source_security_group_id = "${var.control_plane_sg}"
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "eks-node-to-control-plane-ingress-istio-sidecar" {
  description              = "Allow worker Kubelets and pods to receive access on port 443 for istio sidecar requirements"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.eks-node.id}"
  source_security_group_id = "${var.control_plane_sg}"
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_security_group_rule" "control-plane-sg-ingress" {
  description              = "Allow pods to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = "${var.control_plane_sg}"
  source_security_group_id = "${aws_security_group.eks-node.id}"
  to_port                  = 443
  type                     = "ingress"
}

data "aws_ami" "eks-node" {
  filter {
    name   = "name"
    values = ["amazon-eks-*"]
  }

  most_recent = true
  owners      = ["602401143452"]
}

resource "aws_launch_configuration" "eks-node" {
  associate_public_ip_address = true
  iam_instance_profile        = "${var.instance_profile}"
  image_id                    = "${data.aws_ami.eks-node.id}"
  instance_type               = "${var.instance_type}"
  name_prefix                 = "${local.name_prefix}"
  security_groups             = ["${aws_security_group.eks-node.id}"]
  user_data_base64            = "${base64encode(local.eks-node-userdata)}"
  key_name                    = "${aws_key_pair.eks-key.id}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "eks-node" {
  desired_capacity     = "${var.desired}"
  launch_configuration = "${aws_launch_configuration.eks-node.id}"
  max_size             = "${var.max}"
  min_size             = "${var.min}"
  name                 = "${local.name_prefix}"
  vpc_zone_identifier  = ["${var.subnets}"]

  tag {
    key = "auto-delete"
    value = "no"
    propagate_at_launch = true
  }

  tag {
    key = "auto-stop"
    value = "no"
    propagate_at_launch = true
  }

  tag {
    key                 = "Name"
    value               = "${local.name_prefix}"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.cluster_name}"
    value               = "owned"
    propagate_at_launch = true
  }
}
