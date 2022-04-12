data  "azurerm_virtual_network" "hub-vnet" {
    name                = "${var.hub_vnet_name}"
    resource_group_name = var.resource_group_name
}

data "azurerm_virtual_network_gateway" "hub-vnet-gateway" {
    name                = "${var.hub_vnet_gateway_name}"
    resource_group_name = var.resource_group_name
}

resource "azurerm_virtual_network" "spoke-vnet" {
    name                = "${var.spoke_name}-vnet"
    location            = var.location
    resource_group_name = var.resource_group_name
    address_space       = ["10.1.0.0/16"]

    tags = {
        environment = var.environment
    }
}

resource "azurerm_subnet" "spoke-mgmt-subnet" {
    name                 = "${var.spoke_name}-mgmt-subnet"
    resource_group_name  = var.resource_group_name
    virtual_network_name = azurerm_virtual_network.spoke-vnet.name
    address_prefixes     = ["10.1.0.64/27"]
}

# resource "azurerm_subnet" "spoke-workload" {
#     name                 = "${var.spoke_name}-workload"
#     resource_group_name  = var.resource_group_name
#     virtual_network_name = azurerm_virtual_network.spoke-vnet.name
#     address_prefixes     = ["10.1.1.0/24"]
# }

resource "azurerm_virtual_network_peering" "spoke-hub-peer" {
    name                      ="${var.spoke_name}-hub-peer"
    resource_group_name       = var.resource_group_name
    virtual_network_name      = azurerm_virtual_network.spoke-vnet.name
    remote_virtual_network_id = var.hub_vnet_id

    allow_virtual_network_access = true
    allow_forwarded_traffic = true
    allow_gateway_transit   = false
    use_remote_gateways     = true
    depends_on = [azurerm_virtual_network.spoke-vnet, data.azurerm_virtual_network.hub-vnet , data.azurerm_virtual_network_gateway.hub-vnet-gateway]
}

resource "azurerm_network_interface" "spoke-nic" {
    name                 = "${var.spoke_name}-nic"
    location             = var.location
    resource_group_name  = var.resource_group_name
    enable_ip_forwarding = true

    ip_configuration {
        name                          = var.spoke_name
        subnet_id                     = azurerm_subnet.spoke-mgmt-subnet.id
        private_ip_address_allocation = "Dynamic"
    }
}

resource "azurerm_virtual_network_peering" "hub-spoke-peer" {
    name                      = "hub-${var.spoke_name}-peer"
    resource_group_name       = var.resource_group_name
    virtual_network_name      = var.hub_vnet_name
    remote_virtual_network_id = var.hub_vnet_id
    allow_virtual_network_access = true
    allow_forwarded_traffic   = true
    allow_gateway_transit     = true
    use_remote_gateways       = false
    depends_on = [azurerm_virtual_network.spoke-vnet, data.azurerm_virtual_network.hub-vnet, data.azurerm_virtual_network_gateway.hub-vnet-gateway]
}
