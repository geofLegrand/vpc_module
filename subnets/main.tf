
# |################################################################|
# |#           This module allow you to generate                  #|
# |#                the differents subnets                       #|
# |#               ### copy rigth  Kossi ###                      #|
# |################################################################|

### generate the differents subnets (private and public)
locals {
   a = slice(split(".",var.vpc_cidr),0,2)

   _public_subnet_blocks =  [
      for i in range(var.nbr_pub_sub_blocks):
      "${join(".",local.a)}.${i+1}1.0/24"      
    ]

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
   pub_subnets =  [
     for i in range(var.nbr_pub_sub_blocks):{
          az = local.availability_zones[  tonumber(i) % var.nbr_azs == 0 ? 0 :
                         tonumber("${tonumber(i)-1}") % var.nbr_azs == 0 ? 1 : 
                         tonumber("${tonumber(i)-2}") % var.nbr_azs == 0 ? 2 : 
                         tonumber("${tonumber(i)-3}") % var.nbr_azs == 0 ? 3 : -1
           ]
          cidr = local._public_subnet_blocks[i]
     }
   ]

    
}
### get the private subnets per az
locals {
  
   prv_sunbets = [
     for i in range(var.nbr_prv_sub_blocks):{
          az = local.availability_zones[  tonumber(i) % var.nbr_azs == 0 ? 0 :
                         tonumber("${tonumber(i)-1}") % var.nbr_azs == 0 ? 1 : 
                         tonumber("${tonumber(i)-2}") % var.nbr_azs == 0 ? 2 : 
                         tonumber("${tonumber(i)-3}") % var.nbr_azs == 0 ? 3 : -1
           ]
          cidr = local._private_subnet_blocks[i]
     }
   ]

}

locals {
   _r1 = [for e in local.prv_sunbets : e  if e.az =="${var.region}a" ]
   _r2 = [for e in local.prv_sunbets : e  if e.az =="${var.region}b" ]
   _r3 = [for e in local.prv_sunbets : e  if e.az =="${var.region}c" ]
   _r4 = [for e in local.prv_sunbets : e  if e.az =="${var.region}d" ]
   nb_route_tbl =(length(local._r1)>0 ? 1 : 0) + (length(local._r2)>0 ? 1 : 0) + (length(local._r3)>0 ? 1 : 0) + (length(local._r4)>0 ? 1 : 0)

}


output "availability_zones" {
   value = local.availability_zones 
}
output "pub_subnets" {
   value = local.pub_subnets 
}
# output "priv_subnets" {
#    value =local.prv_sunbets
# }
output "priv_subnets_az1" {
   
   value = local._r1
}
output "priv_subnets_az2" {
   value = local._r2
}
output "priv_subnets_az3" {
   value = local._r3
}
output "priv_subnets_az4" {
   value = local._r4
}
output "prv_rtb" {
  value = local.nb_route_tbl
}
output "vpc_cidr" {
  value = var.vpc_cidr
}