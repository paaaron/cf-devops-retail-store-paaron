output "instance_id" {
  description = "ID of the created EC2 instance"
  value       = module.ec2.instance_id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = module.ec2.instance_public_ip
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ${var.ssh_public_key} ec2-user@${module.ec2.instance_public_ip}"
}