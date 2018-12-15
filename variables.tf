variable "cluster_name" {}
variable "cluster_endpoint" {}
variable "vpc_id" {}
variable "control_plane_sg" {}
variable "pub_key_pair" {}

variable "node_name" {
  default = "worker"
  type    = "string"
}

variable "subnets" {
  default = []
}

variable "k8sversion" {
  default = "1.11"
}

variable "kubelet_extra_args" {
  default = ""
}

variable "instance_type" {
  default = "t2.small"
  type    = "string"
}

variable "desired" {
  default = 2
}

variable "min" {
  default = 1
}

variable "max" {
  default = 2
}

variable "instance_profile" {}
