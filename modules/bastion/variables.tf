variable "vpc_filter" {
  description = "The vpc to be filter, feed to the filter block."
  type        = map(list(string))
  default = {
    "tag:Name" = ["main"]
  }
}

variable "bastion_subnets_filter" {
  description = "Subnets for this bastion be filter. If many matchs, randomly select one result."
  type        = map(list(string))
  default = {
    "tag:Name" = ["pub*"]
  }
}

variable "bastion_ami" {
  description = "Lookup for amazon linux 2 if not provided."
  type        = string
  default     = null
}

variable "user_data" {
  description = "Will use predefined template if left null."
  type        = string
  default     = null
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "key_name" {
  description = "AWS managed key pairs."
  type        = string
  default     = null
}

variable "cidr_sources" {
  description = "Ingress ip to be in whitelist."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "ssh_port" {
  type    = number
  default = 22
}

variable "custom_sg_rules" {
  description = "Rules pass to module sg to generate sg. Override the default allow ssh sg."
  default     = {}
}

variable "tags" {
  description = "Tags to bastion instance."
  type        = map(string)
  default     = {}
}

variable "spot" {
  description = "Spot request parameters. Will implicitly use spot for providing any none null value, otherwise will use regular ec2."
  type        = map(any)
  default     = null
  # default = {
  #   spot_price                     = null        # default to be on-demand price
  #   wait_for_fulfillment           = true        # If set, Terraform will wait for the Spot Request to be fulfilled, and will throw an error if the timeout of 10m is reached.
  #   spot_type                      = "one-time"  # or persistent 
  #   launch_group                   = null        # A launch group is a group of spot instances that launch together and terminate together. If left empty instances are launched and terminated individually.
  #   block_duration_minutes         = 60          # must be int value of 60 * [1~6]
  #   instance_interruption_behavior = "terminate" # or hibernate, stop
  #   valid_until                    = null        # default +7 days, YYYY-MM-DDTHH:MM:SSZ
  #   valid_from                     = null        # default now 
  # }
}
