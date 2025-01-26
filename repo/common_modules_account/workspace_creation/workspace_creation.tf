resource "azurerm_databricks_workspace" "this" {
  name                = "${var.resource_prefix}-workspace"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "premium"
}

// Storage Configuration
resource "azurerm_storage_account" "this" {
  name                     = "${var.resource_prefix}storage"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

// Network Configuration
resource "azurerm_virtual_network" "this" {
  name                = "${var.resource_prefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "this" {
  name                 = "${var.resource_prefix}-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefix       = "10.0.1.0/24"
}

// Workspace Configuration
resource "databricks_mws_workspaces" "this" {
  workspace_name           = azurerm_databricks_workspace.this.name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  pricing_tier             = "premium"
}
