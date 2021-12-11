This module simplify arguments needed to set up a security group. Here is a simple example,

```
module "sg" {
  source      = "./modules/sg"
  rules = {
    "http_public": {
      to_port     = 80
      cidr_blocks = "0.0.0.0/0"
    }
  }
}
```