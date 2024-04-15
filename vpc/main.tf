module "my_subnets" {
  source             = "../subnets"
  vpc_cidr           = var.vpc_cidr
  nbr_azs            = var.nbr_azs
  nbr_prv_sub_blocks = var.nbr_prv_sub_blocks
  nbr_pub_sub_blocks = var.nbr_pub_sub_blocks
  region             = var.region
}

locals {
  count_rtb = length(module.my_subnets.priv_subnets_az1)>=1 && length(module.my_subnets.priv_subnets_az2)>=1 ? 2 : 1 
}

locals {
  count_nat = var.type_nat_gateway == "1 in AZ" ? 1 : local.count_rtb < 2 ? 1 : 2 
}

// create a new vpc
resource "aws_vpc" "my_aws_vpc" {

  cidr_block           = module.my_subnets.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = {
    Name : var.tag_vpc_name
    env : var.tag_environment

  }

}

// create internet gateway here and attach it to the vpc
resource "aws_internet_gateway" "my_igw" {
  count  = var.internet_gw == true ? 1 : 0
  vpc_id = aws_vpc.my_aws_vpc.id
  tags = {
    Name : "${var.tag_vpc_name}-igw" //var.internet_gw_name
  }
}

// public route table
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.my_aws_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw[0].id
  }
  tags = {
    Name = "${var.tag_vpc_name}-pub-rtb"
  }
  depends_on = [aws_internet_gateway.my_igw]
}


// private route table
resource "aws_route_table" "route_table_az" {
  count  = local.count_rtb  //max(tonumber(var.nbr_azs),length(module.my_subnets.pub_subnets))
  vpc_id = aws_vpc.my_aws_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.type_nat_gateway == "1 in AZ" && count.index > 0 ? aws_nat_gateway.nat_gateway_pub_az[0].id : aws_nat_gateway.nat_gateway_pub_az[count.index].id
  }
  tags = {
    Name = "${var.tag_vpc_name}-prv-rtb${count.index + 1}"
  }
}


############################# FOR AZ1 AZ2 ...... AZn #################################################

// Public nat Gateway
resource "aws_nat_gateway" "nat_gateway_pub_az" {

  count = local.count_nat //var.type_nat_gateway == "1 in AZ" ? 1 : length(module.my_subnets.pub_subnets) < 2 ? 1 : 2 
  subnet_id = aws_subnet.public_subnets_az[count.index].id

  allocation_id = aws_eip.eip[count.index].id

  depends_on = [aws_eip.eip]

  tags = {
    Name : "${var.tag_vpc_name}-nat-${count.index + 1}"
  }

}

// Elastic ip address
resource "aws_eip" "eip" {
  count = length(module.my_subnets.pub_subnets) //(var.public_subnet_blocks)

  depends_on = [aws_internet_gateway.my_igw]
  tags = {
    Name : "${var.tag_vpc_name}-eip-${count.index + 1}"
  }
}

// Public subnets
resource "aws_subnet" "public_subnets_az" {
  count                   = length(module.my_subnets.pub_subnets)
  cidr_block              = module.my_subnets.pub_subnets[count.index].cidr
  availability_zone       = module.my_subnets.pub_subnets[count.index].az
  vpc_id                  = aws_vpc.my_aws_vpc.id
  map_public_ip_on_launch = true
  tags = {
    Name : "${var.tag_vpc_name}-pub-sub-${count.index + 1}"
  }
  depends_on = [module.my_subnets]
}

// Private subnets 1
resource "aws_subnet" "private_subnets_az1" {
  count             = length(module.my_subnets.priv_subnets_az1)
  cidr_block        = module.my_subnets.priv_subnets_az1[count.index].cidr
  availability_zone = module.my_subnets.priv_subnets_az1[count.index].az
  vpc_id            = aws_vpc.my_aws_vpc.id

  tags = {
    Name : "${var.tag_vpc_name}-prv-sub-${count.index + 1}"
  }
  
}
// Private subnets 2
resource "aws_subnet" "private_subnets_az2" {
  count             = length(module.my_subnets.priv_subnets_az2)
  cidr_block        = module.my_subnets.priv_subnets_az2[count.index].cidr
  availability_zone = module.my_subnets.priv_subnets_az2[count.index].az
  vpc_id            = aws_vpc.my_aws_vpc.id

  tags = {
    Name : "${var.tag_vpc_name}-prv-sub-${count.index + 1}"
  }
 
}
// associate my publics subnets to principal route table
resource "aws_route_table_association" "ass_sb_pub_az" {
  count          = length(module.my_subnets.pub_subnets)
  subnet_id      = aws_subnet.public_subnets_az[count.index].id
  route_table_id = aws_route_table.public_route_table.id
  depends_on     = [aws_subnet.public_subnets_az]
}

// associate my private subnet to route table
resource "aws_route_table_association" "priv_rt_az" {
  count          = length(module.my_subnets.priv_subnets_az1)
  subnet_id      = aws_subnet.private_subnets_az1[count.index].id
  route_table_id = aws_route_table.route_table_az[0].id
  depends_on     = [aws_subnet.private_subnets_az1]
}

// associate my private subnet to route table
resource "aws_route_table_association" "priv_rt_az2" {
  count          = length(module.my_subnets.priv_subnets_az2)
  subnet_id      = aws_subnet.private_subnets_az2[count.index].id
  route_table_id = aws_route_table.route_table_az[1].id
  depends_on     = [aws_subnet.private_subnets_az2]
}

output "vpc_id" {
   value = aws_vpc.my_aws_vpc.id
}
output "pub_subnets" {
  value = module.my_subnets.pub_subnets
}
output "priv_subnets_az1" {
  value = module.my_subnets.priv_subnets_az1
}
output "priv_subnets_az2" {
  value = module.my_subnets.priv_subnets_az2
}











