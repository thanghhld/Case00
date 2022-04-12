output "hub_vnet_name" {
    value = "${azurerm_virtual_network.hub-vnet.name}"
}

output "hub_vnet_id" {
    value = "${azurerm_virtual_network.hub-vnet.id}"
}

output "hub_vnet_gateway_name" {
    value = "${azurerm_virtual_network_gateway.hub-vnet-gateway.name}"
}
