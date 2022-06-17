# terraform-module-env-sg
All the security groups needed to create an Env BOSH

This module will spin up the security groups needed for the environment BOSH & it's deployments.

Inputs - Required:

 - `resource_tags` - AWS tags to apply to resources
 - `vpc_id` - AWS VPC Id
 - `aws_s3_cidrs` - CIDR ranges of s3 ipv4 addresses 
 - `env_cidrs` - CIDR ranges for the subnets in THIS vpc
 - `private_cidrs` - CIDR ranges of all non-public ipv4 addresses

Inputs - Optional: 

 - None

Outputs:

 - `ocfp_env_bosh_sg_id` - security group id for bosh & deployments
 - `cf_tcp_lb_security_group` - security group id for tcp routing lb