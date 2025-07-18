# Output values
output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "vm_public_ip" {
  description = "Public IP address of the VM"
  value       = azurerm_public_ip.main.ip_address
}

output "vm_fqdn" {
  description = "FQDN of the VM"
  value       = azurerm_public_ip.main.fqdn
}

output "load_balancer_public_ip" {
  description = "Public IP address of the load balancer"
  value       = azurerm_public_ip.lb.ip_address
}

output "scale_set_name" {
  description = "Name of the Virtual Machine Scale Set"
  value       = azurerm_linux_virtual_machine_scale_set.main.name
}

output "scale_set_instances" {
  description = "Number of instances in the scale set"
  value       = azurerm_linux_virtual_machine_scale_set.main.instances
}

output "vm_image_id" {
  description = "ID of the created VM image"
  value       = azurerm_image.main.id
}

output "website_url" {
  description = "URL to access the website on the original VM"
  value       = "http://${azurerm_public_ip.main.ip_address}"
}

output "load_balancer_url" {
  description = "URL to access the website through the load balancer"
  value       = "http://${azurerm_public_ip.lb.ip_address}"
}

output "availability_zones" {
  description = "Availability zones used by the scale set"
  value       = azurerm_linux_virtual_machine_scale_set.main.zones
}
