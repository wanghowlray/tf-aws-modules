data "aws_vpc" "main" {
  dynamic "filter" {
    for_each = var.vpc_filter
    content {
      name   = filter.key
      values = filter.value
    }
  }
}

data "aws_subnet_ids" "bastion_subnets" {
  vpc_id = data.aws_vpc.main.id

  dynamic "filter" {
    for_each = var.bastion_subnets_filter
    content {
      name   = filter.key
      values = filter.value
    }
  }
}

module "sg" {
  source      = "../sg"
  name_prefix = "bastion"
  description = "Allow 22 from source ipv4."
  rules = merge(var.custom_sg_rules, length(var.custom_sg_rules) > 0 ? {} : {
    "allow ssh" : {
      to_port     = var.ssh_port
      cidr_blocks = var.cidr_sources
    }
  })
}

data "aws_ec2_instance_type" "instance_type" {
  instance_type = var.instance_type
}

data "aws_ami" "amazon_linux2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-gp2"]
  }

  filter {
    name   = "architecture"
    values = data.aws_ec2_instance_type.instance_type.supported_architectures
  }
}

resource "random_shuffle" "bastion_az" {
  input        = data.aws_subnet_ids.bastion_subnets.ids
  result_count = 1

  keepers = {
    bastion_subnets_tag_name = jsonencode(var.bastion_subnets_filter)
  }
}

resource "aws_instance" "bastion" {
  count                       = var.spot == null ? 1 : 0
  ami                         = coalesce(var.bastion_ami, data.aws_ami.amazon_linux2.image_id)
  key_name                    = var.key_name
  associate_public_ip_address = true
  instance_type               = var.instance_type
  vpc_security_group_ids      = [module.sg.sg.id]
  subnet_id                   = random_shuffle.bastion_az.result[0]
  user_data                   = coalesce(var.user_data, filebase64("${path.module}/userdata_bastion.cloud-init"))

  tags = merge({
    Name = "bastion"
  }, var.tags)
}

resource "aws_spot_instance_request" "bastion" {
  count                          = var.spot == null ? 0 : 1
  ami                            = coalesce(var.bastion_ami, data.aws_ami.amazon_linux2.image_id)
  key_name                       = var.key_name
  associate_public_ip_address    = true
  instance_type                  = var.instance_type
  vpc_security_group_ids         = [module.sg.sg.id]
  subnet_id                      = random_shuffle.bastion_az.result[0]
  user_data                      = coalesce(var.user_data, filebase64("${path.module}/userdata_bastion.cloud-init"))
  spot_price                     = lookup(var.spot, "spot_price", null)
  wait_for_fulfillment           = lookup(var.spot, "wait_for_fulfillment", null)
  spot_type                      = lookup(var.spot, "spot_type", null)
  launch_group                   = lookup(var.spot, "launch_group", null)
  block_duration_minutes         = lookup(var.spot, "block_duration_minutes", null)
  instance_interruption_behavior = lookup(var.spot, "instance_interruption_behavior", null)
  valid_until                    = lookup(var.spot, "valid_until", null)
  valid_from                     = lookup(var.spot, "valid_from", null)

  # Tags only apply to spot request but not the instance. The aws provider just not support.
  tags = merge({
    Name = "bastion"
  }, var.tags)
}
