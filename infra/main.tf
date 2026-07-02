# diogo is using the default vpc for convenience (for speed)
data "aws_vpc" "default" {
  default = true
}

# aws_instance
data "aws_ami" "al2023" {
  most_recent = true
  owners      = var.ami_owners

  filter {
    name   = var.ami_filter_name_key
    values = [var.ami_name_pattern]
  }

  filter {
    name   = var.ami_filter_arch_key
    values = [var.ami_architecture]
  }
}

resource "aws_instance" "main" {
  ami           = data.aws_ami.al2023.id
  instance_type = var.instance_type

  count = 3

  tags = {
    Name = "${var.instance_name_tag}-${count.index}"
  }

  key_name = aws_key_pair.diogo_key.key_name

  vpc_security_group_ids = [aws_security_group.allow_http_ssh.id] # was: security_groups
}

# aws_security_group
resource "aws_security_group" "allow_http_ssh" {
  name        = var.security_group_name
  description = var.security_group_description
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = var.security_group_name
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_ipv4" {
  security_group_id = aws_security_group.allow_http_ssh.id
  cidr_ipv4         = var.allowed_cidr_ipv4
  from_port         = var.http_port
  ip_protocol       = var.ingress_protocol
  to_port           = var.http_port
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4" {
  security_group_id = aws_security_group.allow_http_ssh.id
  cidr_ipv4         = var.allowed_cidr_ipv4
  from_port         = var.ssh_port
  ip_protocol       = var.ingress_protocol
  to_port           = var.ssh_port
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_http_ssh.id
  cidr_ipv4         = var.allowed_cidr_ipv4
  ip_protocol       = var.egress_ip_protocol # semantically equivalent to all ports
}

# Generates a secure private key
resource "tls_private_key" "ed25519" {
  algorithm = "ED25519"
}

# Registers the public key with AWS
resource "aws_key_pair" "diogo_key" {
  key_name   = "diogo-ssh-key"
  public_key = tls_private_key.ed25519.public_key_openssh
}

# Saves the private key locally as a .pem file
resource "local_file" "private_key" {
  content         = tls_private_key.ed25519.private_key_openssh
  filename        = "${path.module}/diogo-ssh-key.pem"
  file_permission = "0400" # Sets read-only permissions required by SSH
}