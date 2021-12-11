variable "vpc_cidr" {
  type    = string
  default = "192.168.144.0/20"
}

variable "vpc_tags" {
  type = map(string)
  default = {
    Name = "main"
  }
}

variable "subnets_cidrs" {
  description = "Azs by groups, each group must span the same size of azs."
  type        = list(list(string))
  default = [
    ["192.168.144.0/23", "192.168.146.0/23", "192.168.148.0/23"],
    ["192.168.152.0/23", "192.168.154.0/23", "192.168.156.0/23"]
  ]
  validation {
    condition     = length(var.subnets_cidrs) > 0 && alltrue([for cidr_group in var.subnets_cidrs : length(flatten(var.subnets_cidrs)) == length(var.subnets_cidrs) * length(cidr_group)])
    error_message = "Should be list of list of cidr string."
  }
}

variable "subnets_name_prefix" {
  description = <<-EOT
    Prefix to subnet's tag:Name. Will suffix with az name, so tag:Name will be pub-us-east-1a.
    If the tag:Name pattern is not desired, override it by setting var.subnets_tags.
  EOT
  type        = list(string)
  default     = ["pub", "priv"]
}

variable "subnets_tags" {
  description = "Tags to subnets, 2d list map to subets."
  type        = list(list(map(string)))
  default     = null
}

variable "subnets_public" {
  description = "False to be private."
  type        = list(bool)
  default     = [true, false]
  validation {
    condition     = anytrue(var.subnets_public)
    error_message = "Not all subnets be private."
  }
}

variable "only_one_nat" {
  description = "Whether to use only 1 nat. If False, create mutiple nat on each az."
  type        = bool
  default     = true
}

variable "subnets_az" {
  description = "By default, choose az alphabetically. This var designates which az to use."
  type        = list(string)
  default     = null
  # default     = [us-east-1d, us-east-1c, us-east-f]
}
