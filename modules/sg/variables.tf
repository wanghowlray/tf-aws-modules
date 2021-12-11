variable "vpc_filter" {
  description = "The vpc to be filtered, feed to the filter block."
  type        = map(list(string))
  default = {
    "tag:Name" = ["main"]
    # "vpc-id" = ["vpc-XXXXXXXXX"] # point it directly
  }
}

variable "name" {
  type    = string
  default = null
}

variable "name_prefix" {
  type    = string
  default = null
}

variable "description" {
  type    = string
  default = null
}

variable "tags" {
  type    = map(string)
  default = null
}

variable "egress_all" {
  description = "True to set an egress allow all rule."
  type        = bool
  default     = true
}

variable "rules" {
  description = "Rules to this sg. Check below for usage hint."
  # tf does not permit object field to be nullable, setting the schema will make this module unwieldy
  # type = map(object({
  #   type                     = string,
  #   from_port                = number,
  #   to_port                  = number,
  #   protocol                 = string,
  #   description              = string,
  #   self                     = bool,
  #   source_security_group_id = string,
  #   cidr_blocks              = list(string),
  #   ipv6_cidr_blocks         = list(string),
  #   prefix_list_ids          = list(string)
  # })) 
  default = {
    "rule1" = {
      type        = "ingress"        # ingress/egress, left null default ingress
      to_port     = 80               # or ICMP type number if protocol is "icmp" or "icmpv6", 
      from_port   = 80               # optional, will set to to_port if left null
      protocol    = "tcp"            # icmp, icmpv6, tcp, udp, or all. Or protocol number, https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml
      description = "allow http any" # will use map key ("rule1" in this sample) if left null
      # self/source_security_group_id/cidr_blocks&&ipv6_cidr_blocks are mutually exclusive, must use one of them
      self                     = null # true/false
      source_security_group_id = null # "sg-123456"
      cidr_blocks              = ["0.0.0.0/0"]
      ipv6_cidr_blocks         = [] # [aws_vpc.example.ipv6_cidr_block]
      prefix_list_ids          = [] # [aws_vpc_endpoint.my_endpoint.prefix_list_id]
    },
    "rule2" = {
      to_port     = -1
      protocol    = "icmp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  validation {
    condition = alltrue([for rule in var.rules :
      (lookup(rule, "self", null) != null && lookup(rule, "source_security_group_id", null) == null && lookup(rule, "cidr_blocks", null) == null && lookup(rule, "ipv6_cidr_blocks", null) == null) ||
      (lookup(rule, "self", null) == null && lookup(rule, "source_security_group_id", null) != null && lookup(rule, "cidr_blocks", null) == null && lookup(rule, "ipv6_cidr_blocks", null) == null) ||
      (lookup(rule, "self", null) == null && lookup(rule, "source_security_group_id", null) == null && (lookup(rule, "cidr_blocks", null) != null || lookup(rule, "ipv6_cidr_blocks", null) != null))
    ])
    error_message = "Bad rules, self/source_security_group_id/cidr_blocks&&ipv6_cidr_blocks are mutually exclusive, and must use either one of them."
  }
}
