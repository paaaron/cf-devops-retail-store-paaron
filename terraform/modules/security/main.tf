# Security group for the EC2 instance
resource "aws_security_group" "monitoring_sg" {
  name        = "monitoring-sg"
  description = "Security group for monitoring services"
  vpc_id      = var.vpc_id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Consider restricting to your IP for better security
  }

  # HTTP access for all the services
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all the monitoring service ports
  dynamic "ingress" {
    for_each = local.service_ports
    content {
      from_port   = ingress.value.from
      to_port     = ingress.value.to
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "monitoring-sg"
  }
}

# Local variable for service ports
locals {
  service_ports = [
    { from = 3100, to = 3100 },   # Loki
    { from = 9095, to = 9095 },   # Loki
    { from = 7946, to = 7946 },   # Loki
    { from = 4317, to = 4317 },   # Jaeger gRPC
    { from = 9411, to = 9412 },   # Zipkin
    { from = 16686, to = 16686 }, # Jaeger UI
    { from = 9090, to = 9090 },   # Prometheus UI
    { from = 8081, to = 8081 },   # Grafana UI
    { from = 3200, to = 3200 },   # Tempo
    { from = 4327, to = 4328 },   # Tempo
    { from = 9110, to = 9110 },   # Node exporter
    { from = 9093, to = 9093 },   # Alert manager
    { from = 13133, to = 13133 }, # OpenTelemetry health check
    { from = 8888, to = 8889 }    # Prometheus exporter
  ]
}

# Create a key pair for SSH access
resource "aws_key_pair" "monitoring_key" {
  key_name   = "monitoring-key"
  public_key = file(var.ssh_public_key)
}

# IAM role and instance profile for the EC2 instance
resource "aws_iam_role" "ec2_role" {
  name = "ec2_monitoring_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "monitoring_profile" {
  name = "monitoring_profile"
  role = aws_iam_role.ec2_role.name
}