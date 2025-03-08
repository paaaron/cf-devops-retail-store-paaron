output "security_group_id" {
  description = "ID of the created security group"
  value       = aws_security_group.monitoring_sg.id
}

output "key_name" {
  description = "Name of the created key pair"
  value       = aws_key_pair.monitoring_key.key_name
}

output "instance_profile_name" {
  description = "Name of the created instance profile"
  value       = aws_iam_instance_profile.monitoring_profile.name
}