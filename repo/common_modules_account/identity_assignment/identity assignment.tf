data "azurerm_client_config" "example" {}

resource "azurerm_role_assignment" "example" {
  principal_id         = var.principal_id
  role_definition_name = "Contributor"
  scope                = data.azurerm_client_config.example.subscription_id
}
