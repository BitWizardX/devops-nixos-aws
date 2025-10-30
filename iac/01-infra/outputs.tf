output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "control_node_id" {
  value = aws_instance.control_node.id
}

output "how_to_connect_to_control_node" {
  description = "Instructions on how to connect to the Control Node"
  value       = "Go to AWS Console -> Systems Manager -> Session Manager, select the instance and click 'Start session'. Or use AWS CLI: aws ssm start-session --target ${aws_instance.control_node.id}"
}
