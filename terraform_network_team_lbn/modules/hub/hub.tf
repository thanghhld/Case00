# locals {
#     prefix-hub         = "hub"
#     hub-location       = "eastus"
#     hub-resource-group = "hub-vnet-rg"
#     shared-key         = "4-v3ry-53cr37-1p53c-5h4r3d-k3y"
# }

resource "azurerm_virtual_network" "hub-vnet" {
    name                = "${var.hub_name}-vnet"
    location            = var.location
    resource_group_name = var.resource_group_name
    address_space       = ["10.0.0.0/16"]

    tags = {
        environment = var.environment
    }
}

resource "azurerm_subnet" "hub-gateway-subnet" {
    name                 = "${var.hub_name}-gateway-subnet"
    resource_group_name  = var.resource_group_name
    virtual_network_name = azurerm_virtual_network.hub-vnet.name
    address_prefixes     = ["10.0.255.224/27"]
}

resource "azurerm_subnet" "hub-mgmt-subnet" {
    name                 = "${var.hub_name}-gateway-subnet"
    resource_group_name  = var.resource_group_name
    virtual_network_name = azurerm_virtual_network.hub-vnet.name
    address_prefixes       = ["10.0.0.64/27"]
}
/*
resource "azurerm_subnet" "hub-dmz" {
    name                 = "dmz"
    resource_group_name  = azurerm_resource_group.hub-vnet-rg.name
    virtual_network_name = azurerm_virtual_network.hub-vnet.name
    address_prefixes       = ["10.0.0.32/27"]
}
*/
resource "azurerm_network_interface" "hub-nic" {
    name                 = "${var.hub_name}-nic"
    location             = var.location
    resource_group_name  = var.resource_group_name
    enable_ip_forwarding = true

    ip_configuration {
        name                          = var.hub_name
        subnet_id                     = azurerm_subnet.hub-mgmt-subnet.id
        private_ip_address_allocation = "Dynamic"
    }

    tags = {
        environment = var.environment
    }
}

#Virtual Machine
# resource "azurerm_virtual_machine" "hub-vm" {
#     name                  = "${var.hubname}-vm"
#     location              = var.location
#     resource_group_name   = var.resource_group_name
#     network_interface_ids = [azurerm_network_interface.hub-nic.id]
#     vm_size               = var.vmsize

#     storage_image_reference {
#         publisher = "Canonical"
#         offer     = "UbuntuServer"
#         sku       = "16.04-LTS"
#         version   = "latest"
#     }

#     storage_os_disk {
#         name              = "myosdisk1"
#         caching           = "ReadWrite"
#         create_option     = "FromImage"
#         managed_disk_type = "Standard_LRS"
#     }

#     os_profile {
#         computer_name  = "${local.prefix-hub}-vm"
#         admin_username = var.username
#         admin_password = var.password
#     }

#     os_profile_linux_config {
#         disable_password_authentication = false
#     }

#     tags = {
#         environment = local.prefix-hub
#     }
# }

# Virtual Network Gateway
resource "azurerm_public_ip" "hub-vpn-gateway-pip" {
    name                = "${var.hub_name}-vpn-gateway-pip"
    location            = var.location
    resource_group_name = var.resource_group_name

    allocation_method = "Dynamic"
}

resource "azurerm_virtual_network_gateway" "hub-vnet-gateway" {
    name                = "${var.hub_name}-vpn-gateway"
    location            = var.location
    resource_group_name = var.resource_group_name
    type     = "Vpn"
    vpn_type = "RouteBased"

    active_active = false
    enable_bgp    = false
    sku           = "VpnGw1"

    ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.hub-vpn-gateway-pip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.hub-gateway-subnet.id
    }
    depends_on = [azurerm_public_ip.hub-vpn-gateway-pip]
}

# resource "azurerm_virtual_network_gateway_connection" "hub-onprem-conn" {
#     name                = "hub-onprem-conn"
#     location            = var.location
#     resource_group_name = var.resource_group_name

#     type           = "Vnet2Vnet"
#     routing_weight = 1

#     virtual_network_gateway_id      = azurerm_virtual_network_gateway.hub-vnet-gateway.id
#     peer_virtual_network_gateway_id = var.onprem-vpn-gateway-id

#     shared_key = local.shared-key
# }

# resource "azurerm_virtual_network_gateway_connection" "onprem-hub-conn" {
#     name                = "onprem-hub-conn"
#     location            = var.location
#     resource_group_name = var.resource_group_name
#     type                            = "Vnet2Vnet"
#     routing_weight = 1
#     virtual_network_gateway_id      = var.onprem-vpn-gateway-id
#     peer_virtual_network_gateway_id = azurerm_virtual_network_gateway.hub-vnet-gateway.id
#     shared_key = local.shared-key
# }