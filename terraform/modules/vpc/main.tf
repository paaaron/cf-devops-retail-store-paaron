resource "aws_vpc" "monitoring_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  
  tags = {
    Name = "monitoring-vpc"
  }
}

resource "aws_subnet" "monitoring_subnet" {
  vpc_id                  = aws_vpc.monitoring_vpc.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = var.availability_zone
  
  tags = {
    Name = "monitoring-subnet"
  }
}

resource "aws_internet_gateway" "monitoring_gateway" {
  vpc_id = aws_vpc.monitoring_vpc.id
  
  tags = {
    Name = "monitoring-gateway"
  }
}

resource "aws_route_table" "monitoring_route_table" {
  vpc_id = aws_vpc.monitoring_vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.monitoring_gateway.id
  }
  
  tags = {
    Name = "monitoring-route-table"
  }
}

resource "aws_route_table_association" "monitoring_route_assoc" {
  subnet_id      = aws_subnet.monitoring_subnet.id
  route_table_id = aws_route_table.monitoring_route_table.id
}