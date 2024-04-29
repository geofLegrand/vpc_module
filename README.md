# My vpc module

this module will allow you to create vpcs up to Three-tier

## Usage

```hcl
module "my_vpc_module" {
  source = "github.com/geofLegrand/vpc_module"

  vpc_cidr             = "172.120.0.0/16"
  internet_gw          = true
  enable_dns_hostnames = true
  enable_dns_support   = true
  nbr_azs              = 2
  nbr_prv_sub_blocks   = 2
  nbr_pub_sub_blocks   = 2
  tag_environment      = "dev"
  tag_vpc_name         = "dev-vpc"
  type_nat_gateway     = "1 per AZ"
  region               = "us-east-1"

}
```

Note that in the example we allocate 2 availability zone because we will be provisioning 2 NAT Gateways (due to `type_nat_gateway = "1 per AZ"` and having 2 publics subnets).

## NAT Gateway Scenarios

This module supports two scenarios for creating NAT gateways. Each will be explained in further detail in the corresponding sections.

- One NAT Gateway per subnet (default behavior)
  - `type_nat_gateway = "1 per AZ"`
- Single NAT Gateway
  - `type_nat_gateway = "1 in AZ"`

## Number of availability zone

- The availability zones must be less than 3. It's mean that the number can be `1` to `3`.
    - `nbr_azs = 2`

## Number of subnets

  The subnets are divided into two. The public subnets `nbr_pub_sub_blocks` and the private subnets `nbr_prv_sub_blocks`.
- The Number of private subnets.Your private subnets must be in `1` and `xxxxx`
- The Number of public subnets.Your public subnets must be in `1` and `3`
