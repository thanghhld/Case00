module "resource_group" {
  source = "./modules/rg"
  resource_group_name = "test-ryan-v01"
  location = var.location
}

# module "onprem" {

# }

module "hub" {
  source = "./modules/hub"
  hub_name = "ryan-hub"
  resource_group_name = module.resource_group.resource_group_name
  location = var.location
  environment = "dev"

}

module "spoke" {
  source = "./modules/spoke"
  spoke_name = "spoke_01"
  resource_group_name = module.resource_group.resource_group_name
  location = var.location
  environment = "dev"
  hub_vnet_name = module.hub.hub_vnet_name
  hub_vnet_id = module.hub.hub_vnet_id
  hub_vnet_gateway_name = module.hub.hub_vnet_gateway_name
}


