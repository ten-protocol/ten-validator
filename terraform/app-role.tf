# Create a role assignment for the service principal# Create a service principal
resource "azuread_application" "ten_validatorApp" {
  display_name = "ten_validatorApp"
}

resource "azuread_service_principal" "ten_validatorApp" {
  application_id = azuread_application.ten_validatorApp.application_id
}

resource "azuread_service_principal_password" "ten_validatorApp" {
  service_principal_id = azuread_service_principal.ten_validatorApp.object_id
  end_date             = "2099-01-01T00:00:00Z"
}

# Data source to get the current subscription ID
data "azurerm_subscription" "primary" {}

# Role assignment resource
resource "azurerm_role_assignment" "ra" {
  principal_id         = azuread_service_principal.ten_validatorApp.object_id
  role_definition_name = "Reader"
  scope                = data.azurerm_subscription.primary.id
}

data "azurerm_client_config" "ten_validatorApp" {}
