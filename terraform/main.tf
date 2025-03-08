provider "aws" {
  region = var.region
}

module "vpc" {
  source = "./modules/vpc"
  
  vpc_cidr        = var.vpc_cidr
  subnet_cidr     = var.subnet_cidr
  availability_zone = "${var.region}a"
}

module "security" {
  source = "./modules/security"
  
  vpc_id          = module.vpc.vpc_id
  ssh_public_key  = var.ssh_public_key
}

module "ec2" {
  source = "./modules/ec2"
  
  subnet_id       = module.vpc.subnet_id
  security_group_id = module.security.security_group_id
  key_name        = module.security.key_name
  instance_type   = var.instance_type
  instance_profile = module.security.instance_profile_name
  volume_size     = var.volume_size
}

# Output the instance public IP
output "instance_public_ip" {
  value = module.ec2.instance_public_ip
}