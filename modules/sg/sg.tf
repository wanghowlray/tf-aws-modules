data "aws_vpc" "main" {
  dynamic "filter" {
    for_each = var.vpc_filter
    content {
      name   = filter.key
      values = filter.value
    }
  }
}

resource "aws_security_group" "sg" {
  vpc_id      = data.aws_vpc.main.id
  name        = var.name
  name_prefix = var.name_prefix
  description = var.description
  tags        = var.tags
}

resource "aws_security_group_rule" "rules" {
  for_each = var.rules

  security_group_id        = aws_security_group.sg.id
  to_port                  = each.value.to_port
  type                     = lookup(each.value, "type", "ingress")
  from_port                = lookup(each.value, "from_port", each.value.to_port)
  protocol                 = lookup(each.value, "protocol", "tcp")
  description              = lookup(each.value, "description", each.key)
  cidr_blocks              = lookup(each.value, "cidr_blocks", null)
  ipv6_cidr_blocks         = lookup(each.value, "ipv6_cidr_blocks", null)
  source_security_group_id = lookup(each.value, "source_security_group_id", null)
  self                     = lookup(each.value, "self", null)
  prefix_list_ids          = lookup(each.value, "prefix_list_ids", null)
}

resource "aws_security_group_rule" "egress_all" {
  count = var.egress_all ? 1 : 0

  type              = "egress"
  security_group_id = aws_security_group.sg.id
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  protocol          = "all"
}
