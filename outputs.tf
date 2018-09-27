output "node_asg" {
  description = "EKS Node Auto Scaling Group"
  value       = "${aws_autoscaling_group.eks-node.arn}"
}

output "node_security_group" {
  description = "EKS Node Security Group"
  value       = "${aws_security_group.eks-node.id}"
}
