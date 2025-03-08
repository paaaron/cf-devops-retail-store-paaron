output "instance_id" {
  description = "ID of the created EC2 instance"
  value       = aws_instance.monitoring_instance.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_eip.monitoring_eip.public_ip
}