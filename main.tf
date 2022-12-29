## Variables

variable resource_tags {} # AWS tags to apply to resources               (required)
variable vpc_id        {} # Pass in the AWS VPC Id                       (required)
variable aws_s3_cidrs  {} # CIDR ranges of s3 ipv4 addresses             (required)
variable env_cidrs     {} # CIDR ranges for the subnets in THIS vpc      (required)
variable private_cidrs {} # CIDR ranges of all non-public ipv4 addresses (required)


################################################################################
# OCFP BOSH Security Group
################################################################################
resource "aws_security_group" "ocfp_env_bosh_sg" {
  name          = "ocf-bosh-sg"
  description   = "Inbound & outbound INTERNAL traffic for BOSH & Deployments"
  vpc_id        = var.vpc_id
  # Env Subnets
  ingress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = var.env_cidrs
  }
  # Private Subnets HTTPS
  ingress {
    from_port   = 443
    protocol    = "TCP"
    to_port     = 443
    cidr_blocks = var.private_cidrs
  }
  # Private Subnets CF SSH 
  # # TODO: 2222 should be it's own SG applied to CF Scheduler Instance Group
  ingress {
    from_port   = 2222
    protocol    = "TCP"
    to_port     = 2222
    cidr_blocks = var.private_cidrs
  }
  # TCP Routing
  ingress {
    from_port   = 40000
    protocol    = "TCP"
    to_port     = 40099
    cidr_blocks = var.private_cidrs
  }

  # AWS S3
  ingress {
    from_port   = 443
    protocol    = "TCP"
    to_port     = 443
    cidr_blocks = var.aws_s3_cidrs
  }

  # Needed for cross account support
  ingress {
    from_port   = 8080
    protocol    = "TCP"
    to_port     = 8080
    cidr_blocks = var.private_cidrs
  }

  tags          = merge({Name = "env-bosh-sg"}, var.resource_tags )
}

output "ocfp_env_bosh_sg_id" {
    value = "${aws_security_group.ocfp_env_bosh_sg.id}"
}


resource "aws_security_group" "ocf_tcp_lb_security_group" {
  name        = "ocf-tcp-lb-security-group"
  description = "CF TCP"
  vpc_id      = var.vpc_id

  ingress {
    cidr_blocks = var.private_cidrs
    protocol    = "tcp"
    from_port   = 40000
    to_port     = 40099
  }


  tags = merge({Name = "ocf-tcp-lb-security-group"}, var.resource_tags)

  lifecycle {
    ignore_changes = [name]
  }
}



resource "aws_security_group" "ocf_tcp_lb_internal_security_group" {
  name        = "ocf-tcp-lb-internal-security-group"
  description = "CF TCP Internal"
  vpc_id      = var.vpc_id

  ingress {
    security_groups = ["${aws_security_group.ocf_tcp_lb_security_group.id}"]
    protocol        = "tcp"
    from_port       = 40000
    to_port         = 40099
  }

  ingress {
    security_groups = ["${aws_security_group.ocf_tcp_lb_security_group.id}"]
    protocol        = "tcp"
    from_port       = 80
    to_port         = 80
  }


  tags = merge({Name = "ocf-tcp-lb-internal-security-group"}, var.resource_tags)


  lifecycle {
    ignore_changes = [name]
  }
}

output "ocf_tcp_lb_security_group"          { value = aws_security_group.ocf_tcp_lb_security_group.id }
