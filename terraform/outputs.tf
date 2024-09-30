# VM outputs
output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "public_ip_address" {
  value = azurerm_linux_virtual_machine.ten_validatorApp_terraform_vm.public_ip_address
}

output "user_name" {
  value = var.username
}

# Azure AD outputs
output "tenant_id" {
  value = data.azurerm_client_config.ten_validatorApp.tenant_id
}

output "client_id" {
  value = azuread_service_principal.ten_validatorApp.client_id
}

output "client_secret" {
  value = azuread_service_principal_password.ten_validatorApp.value
  sensitive = true
}

output "subscription_id" {
  value = data.azurerm_client_config.ten_validatorApp.subscription_id
}

# VM IP domain name output
output "ten_validator_dns_name" {
  value = "${azurerm_public_ip.ten_validatorApp_terraform_public_ip.domain_name_label}.uksouth.cloudapp.azure.com"
}
