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
  name          = "env-bosh-sg"
  description   = "Inbound & outbound INTERNAL traffic for BOSH & Deployments"
  vpc_id        = var.vpc_id
  # MVP Subnets
  ingress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = var.env_cidrs
  }
  egress {
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
  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
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
  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = var.private_cidrs
  }
  # AWS S3
  ingress {
    from_port   = 443
    protocol    = "TCP"
    to_port     = 443
    cidr_blocks = var.aws_s3_cidrs
  }
  egress {
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
  egress {
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


resource "aws_security_group" "cf_tcp_lb_security_group" {
  name        = "cf-tcp-lb-security-group"
  description = "CF TCP"
  vpc_id      = var.vpc_id

  ingress {
    cidr_blocks = var.private_cidrs
    protocol    = "tcp"
    from_port   = 40000
    to_port     = 40100
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.private_cidrs
  }

  tags = merge({Name = "cf-tcp-lb-security-group"}, var.resource_tags)

  lifecycle {
    ignore_changes = [name]
  }
}



resource "aws_security_group" "cf_tcp_lb_internal_security_group" {
  name        = "cf-tcp-lb-internal-security-group"
  description = "CF TCP Internal"
  vpc_id      = var.vpc_id

  ingress {
    security_groups = ["${aws_security_group.cf_tcp_lb_security_group.id}"]
    protocol        = "tcp"
    from_port       = 40000
    to_port         = 40100
  }

  ingress {
    security_groups = ["${aws_security_group.cf_tcp_lb_security_group.id}"]
    protocol        = "tcp"
    from_port       = 80
    to_port         = 80
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.private_cidrs
  }

  tags = merge({Name = "cf-tcp-lb-internal-security-group"}, var.resource_tags)


  lifecycle {
    ignore_changes = [name]
  }
}


#output "cf_tcp_lb_internal_security_group" { value = aws_security_group.cf_tcp_lb_internal_security_group.id }
output "cf_tcp_lb_security_group"          { value = aws_security_group.cf_tcp_lb_security_group.id }
}