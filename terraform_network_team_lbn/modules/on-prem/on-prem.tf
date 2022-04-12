# locals {
#     onprem-location       = "eastus"
#     onprem-resource-group = "onprem-vnet-rg"
#     prefix-onprem         = "onprem"
# }

# resource "azurerm_resource_group" "onprem-vnet-rg" {
#     name     = local.onprem-resource-group
#     location = local.onprem-location
# }

resource "azurerm_virtual_network" "onprem-vnet" {
    name                = "${var.onprem_name}-vnet"
    location            = var.location
    resource_group_name = var.resource_group_name
    address_space       = ["192.168.0.0/16"]

    tags = {
    environment = var.environment
    }
}

resource "azurerm_subnet" "onprem-gateway-subnet" {
    name                 = "${var.onprem_name}-gateway-subnet"
    resource_group_name  = var.resource_group_name
    virtual_network_name = azurerm_virtual_network.onprem-vnet.name
    address_prefixes     = ["192.168.255.224/27"]
}

resource "azurerm_subnet" "onprem-mgmt" {
    name                 = "${var.onprem_name}"
    resource_group_name  = var.resource_group_name
    virtual_network_name = azurerm_virtual_network.onprem-vnet.name
    address_prefixes     = ["192.168.1.128/25"]
}

resource "azurerm_public_ip" "onprem-pip" {
    name                         = "${var.onprem_name}-pip"
    location            = var.location
    resource_group_name = var.resource_group_name
    allocation_method   = "Dynamic"

    tags = {
        environment = var.environment
    }
}

resource "azurerm_network_interface" "onprem-nic" {
    name                 = "${var.onprem_name}-nic"
    location            = var.location
    resource_group_name = var.resource_group_name
    enable_ip_forwarding = true

    ip_configuration {
    name                          = var.onprem_name
    subnet_id                     = azurerm_subnet.onprem-mgmt.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.onprem-pip.id
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "onprem-nsg" {
    name                = "${var.onprem_name}-nsg"
    location            = var.location
    resource_group_name = var.resource_group_name

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags = {
        environment = "onprem"
    }
}

resource "azurerm_subnet_network_security_group_association" "mgmt-nsg-association" {
    subnet_id                 = azurerm_subnet.onprem-mgmt.id
    network_security_group_id = azurerm_network_security_group.onprem-nsg.id
}

resource "azurerm_virtual_machine" "onprem-vm" {
    name                  = "${var.onprem_name}-vm"
    location            = var.location
    resource_group_name = var.resource_group_names
    network_interface_ids = [azurerm_network_interface.onprem-nic.id]
    vm_size               = var.vmsize

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04-LTS"
        version   = "latest"
    }

    storage_os_disk {
        name              = "myosdisk1"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Standard_LRS"
    }

    os_profile {
        computer_name  = "${local.prefix-onprem}-vm"
        admin_username = var.username
        admin_password = var.password
    }

    os_profile_linux_config {
        disable_password_authentication = false
    }

    tags = {
        environment = var.environment
    }
}

resource "azurerm_public_ip" "onprem-vpn-gateway1-pip" {
    name                = "${var.onprem_name}-vpn-gateway1-pip"
    location            = var.location
    resource_group_name = var.resource_group_name

    allocation_method = "Dynamic"
}

resource "azurerm_virtual_network_gateway" "onprem-vpn-gateway" {
    name                = "${var.onprem_name}-vpn-gateway"
    location            = var.location
    resource_group_name = var.resource_group_name

    type     = "Vpn"
    vpn_type = "RouteBased"

    active_active = false
    enable_bgp    = false
    sku           = "VpnGw1"

    ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.onprem-vpn-gateway1-pip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.onprem-gateway-subnet.id
    }
    depends_on = [azurerm_public_ip.onprem-vpn-gateway1-pip]

}