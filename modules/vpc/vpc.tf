data "aws_availability_zones" "azs" {
  state = "available"
}

locals {
  az_count     = length(var.subnets_cidrs[0])
  subnets_az   = coalesce(var.subnets_az, slice(data.aws_availability_zones.azs.names, 0, local.az_count))
  subnets_tags = coalesce(var.subnets_tags, [for group in var.subnets_cidrs : [for member in group : {}]])
}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags       = var.vpc_tags
}

resource "aws_subnet" "all" {
  count                   = length(flatten(var.subnets_cidrs))
  vpc_id                  = aws_vpc.main.id
  cidr_block              = flatten(var.subnets_cidrs)[count.index]
  map_public_ip_on_launch = var.subnets_public[floor(count.index / local.az_count)]
  availability_zone       = local.subnets_az[count.index % local.az_count]

  tags = merge({
    "Name" = "${var.subnets_name_prefix[floor(count.index / local.az_count)]}-${local.subnets_az[count.index % local.az_count]}"
  }, flatten(local.subnets_tags)[count.index])
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_eip" "nat" {
  count = alltrue(var.subnets_public) ? 0 : (var.only_one_nat ? 1 : local.az_count)
  vpc   = true
}


# To ensure proper ordering, it is recommended to add an explicit dependency on the Internet Gateway for the VPC.
resource "aws_nat_gateway" "ngw" {
  count         = length(aws_eip.nat)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.all[index(var.subnets_public, true) * local.az_count + count.index].id
  depends_on    = [aws_internet_gateway.gw]
}

resource "aws_route_table" "pub" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "priv" {
  count  = length(aws_eip.nat)
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "pub" {
  route_table_id         = aws_route_table.pub.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

resource "aws_route" "priv" {
  count                  = length(aws_eip.nat)
  route_table_id         = aws_route_table.priv[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.ngw[count.index].id
}

resource "aws_route_table_association" "all" {
  count          = length(aws_subnet.all)
  subnet_id      = aws_subnet.all[count.index].id
  route_table_id = var.subnets_public[floor(count.index / local.az_count)] ? aws_route_table.pub.id : aws_route_table.priv[var.only_one_nat ? 0 : count.index % local.az_count].id
}
