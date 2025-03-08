variable "subnet_id" {
  description = "ID of the subnet"
  type        = string
}

variable "security_group_id" {
  description = "ID of the security group"
  type        = string
}

variable "key_name" {
  description = "Name of the key pair"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "instance_profile" {
  description = "Name of the instance profile"
  type        = string
}

variable "volume_size" {
  description = "Root volume size in GB"
  type        = number
}