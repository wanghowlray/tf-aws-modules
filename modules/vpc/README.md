Create a VPC. Subnets are aligned into a 2-d arrar, by az and functionality.

For example, you need 2 public subnets and 2 private subnets, then such variables may be required,

- *vpc_cidr* = "192.168.100.0/24"
- *subnets_name_prefix* = ["pub", "priv"]
- *subnets_public* = [true, false]
- *subnets_cidrs* = [["192.168.100.0/26","192.168.100.64/26"],["192.168.100.128/26","192.168.100.192/26"]]

By such setup, 

- "192.168.100.0/26" will be public subnet in AZ-a
- "192.168.100.64/26" will be public subnet in AZ-b
- "192.168.100.128/26" will be private subnet in AZ-a
- "192.168.100.192/26" will be private subnet in AZ-b