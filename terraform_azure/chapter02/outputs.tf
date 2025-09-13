# Networking outputs
output "vm_public_ip" {
  description = "The public IP address of the VM"
  value       = azurerm_public_ip.pip.ip_address
}

output "vm_private_ip" {
  description = "The private IP address of the VM"
  value       = azurerm_network_interface.nic.ip_configuration[0].private_ip_address
}

output "subnet_id" {
  description = "The ID of the subnet used by the VM"
  value       = azurerm_subnet.subnet.id
}

output "vnet_id" {
  description = "The ID of the virtual network"
  value       = azurerm_virtual_network.vnet.id
}

# Resource Group
output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.rg.name
}

# VM details
output "vm_name" {
  description = "The name of the VM"
  value       = azurerm_linux_virtual_machine.vm.name
}

output "vm_id" {
  description = "The ID of the VM"
  value       = azurerm_linux_virtual_machine.vm.id
}