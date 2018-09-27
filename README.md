# EKS Nodes

This terraform module creates an Auto Scaling group that will launch nodes that can be joined to an EKS cluster, the Auto Scaling group will be configured to use the latest EKS Optimized AMI.

The EKS nodes module requires:

* An EKS Cluster, preferably created using the [EKS Cluster Module](https://github.com/overdrive3000/terraform_eks_cluster).
* An IAM instance profile with at least these managed policies attached to it AmazonEKSWorkerNodePolicy and AmazonEC2ContainerRegistryReadOnly. The [EKS Cluster Module](https://github.com/overdrive3000/terraform_eks_cluster) already creates an Instance Role that can be used in this module.
* Public SSH Key Pair.

## Features

This terraform module creates the following resources:

* AWS Key Pair
* AWS Security Group for the EKS Nodes
* AWS Auto Scaling Group


## Usage

To use the module, include something like the following in your terraform configuration:

```
module "eks_nodes" {
  source = "github.com/overdrive3000/terraform_eks_nodes"

  cluster_name       = "mycluster"
  cluster_endpoint   = "EKS ENDPOINT"
  node_name          = "workers"
  vpc_id             = "vpc-00000000"
  control_plane_sg   = "sg-00000000"
  pub_key_pair       = "SSH PUBLIC KEY"
  subnets            = ["subnet-0000, subnet-1111"]
  instance_profile   = "arn:aws:iam::000000000000:instance-profile/eks-nodes"
  instance_type      = "t3.medium"
  desired            = "2"
  min                = "1"
  max                = "4"
  kubelet_extra_args = "--node-labels=my_own_label=yes --register-with-taints=mytaint=true:NoSchedule"
}
```

## Inputs

| Name               | Description                                               | Default   | Required   |
|--------------------|-----------------------------------------------------------|:---------:|:----------:|
| cluster_name       | EKS Cluster name                                          | -         | yes        |
| cluster_endpoint   | EKS Cluster API Server Endpoint                           | -         | yes        |
| vpc_id             | VPC Id in which EKS nodes will be launched                | -         | yes        |
| control_plane_sg   | Security Group for EKS Cluster and EKS Node communication | -         | yes        |
| pub_key_pair       | SSH Public Key to be added to the EKS Nodes               | -         | yes        |
| node_name          | Descriptive name for the EKS Nodes                        | worker    | no         |
| subnets            | List of subnet ids in which worker nodes will be placed   | -         | yes        |
| kubelet_extra_args | Extra arguments for kubelet configuration                 | -         | no         |
| instance_type      | EC2 Instance Type                                         | t2.small  | no         |
| desired            | Desired number of EKS nodes to be launched                | 2         | no         |
| min                | Minumum number of EKS nodes to be launched                | 1         | no         |
| max                | Maximum number of EKS nodes to be launched                | 4         | no         |
| instance_profile   | IAM Instance Profile to be attached to the EKS Nod        | -         | yes        |


## Output

| Name                | Description                                 |
|---------------------|---------------------------------------------|
| node_asg            | Auto Scaling Group Name                     |
| node_security_group | EKS Node Security Group Id                  |
