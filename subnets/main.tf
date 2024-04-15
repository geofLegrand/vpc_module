
# |################################################################|
# |#           This module allow you to generate                  #|
# |#                the differents subnets                       #|
# |#               ### copy rigth  Kossi ###                      #|
# |################################################################|

### generate the differents subnets (private and public)
locals {
   a = slice(split(".",var.vpc_cidr),0,2)
  
   _public_subnet_blocks = var.nbr_pub_sub_blocks == 2 ? [
    "${join(".",local.a)}.100.0/24","${join(".",local.a)}.200.0/24"] : var.nbr_pub_sub_blocks == 1 ? ["${join(".",local.a)}.100.0/24"]:[]
   
   _private_subnet_blocks = [
      for i in range(var.nbr_prv_sub_blocks): 
      "${join(".",local.a)}.${i+1}.0/24"
    ]
}
### get availability zones
locals {
   r = ["a", "b", "c", "d", "e", "f"]
   availability_zones = [for i in range(var.nbr_azs):"${var.region}${local.r[i]}"]
}
### get the public subnets per az
locals {
   pub_subnets = var.nbr_azs == 1 ? [
        for p in local._public_subnet_blocks:{
            az = local.availability_zones[0]
            cidr = p
        }
   ]:var.nbr_azs == 2 && var.nbr_pub_sub_blocks == 1 ? [
    { az = local.availability_zones[0], cidr = local._public_subnet_blocks[0]}
   ]:var.nbr_azs == 2 && var.nbr_pub_sub_blocks == 2 ? [
     for i in range(var.nbr_azs): {
      az = local.availability_zones[i], 
      cidr = local._public_subnet_blocks[i]
     }
   ]:[]
    
}
### get the private subnets per az
locals {
    prv_sunbets =  var.nbr_azs == 1 ? [
        for p in local._private_subnet_blocks:{
            az = local.availability_zones[0]
            cidr = p
        }
   ]:var.nbr_azs == 2 && (var.nbr_prv_sub_blocks == 4 || var.nbr_prv_sub_blocks == 3) ? [
     for i in range(var.nbr_prv_sub_blocks):{
          az = i == 0 || i == 1 ? local.availability_zones[0] : local.availability_zones[1]
          cidr = local._private_subnet_blocks[i]
     }
   ]:var.nbr_azs == 2 && var.nbr_prv_sub_blocks == 2 ? [
     for i in range(var.nbr_prv_sub_blocks):{
          az = i == 0 ? local.availability_zones[0] : local.availability_zones[1]
          cidr = local._private_subnet_blocks[i]
     }
   ]:var.nbr_azs == 2 && var.nbr_prv_sub_blocks == 1 ? [
    { az = local.availability_zones[0], cidr = local._private_subnet_blocks[0]}
   ]:[]
}



output "availability_zones" {
   value = local.availability_zones 
}
output "pub_subnets" {
   value = local.pub_subnets 
}
output "priv_subnets_az1" {
   value = [for e in local.prv_sunbets : e  if e.az =="${var.region}a" ] 
}
output "priv_subnets_az2" {
   value = [for e in local.prv_sunbets : e  if e.az =="${var.region}b" ] 
}
output "vpc_cidr" {
  value = var.vpc_cidr
}