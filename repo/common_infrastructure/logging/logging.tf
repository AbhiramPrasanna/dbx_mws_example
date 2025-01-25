// Terraform Documentation: https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/mws_log_delivery

// Azure Storage Account
resource "azurerm_storage_account" "log_delivery" {
  name                     = "${var.resource_prefix}logdelivery"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    Name = "${var.resource_prefix}-log-delivery"
  }
}

// Azure Storage Container
resource "azurerm_storage_container" "log_delivery" {
  name                  = "logdelivery"
  storage_account_name  = azurerm_storage_account.log_delivery.name
  container_access_type = "private"
}

// Azure Storage Account SAS
resource "azurerm_storage_account_sas" "log_delivery" {
  storage_account_name = azurerm_storage_account.log_delivery.name
  https_only           = true
  expiry               = "2030-01-01"
  signed_ip            = "0.0.0.0-255.255.255.255"
  signed_protocol      = "https"
  permissions {
    read    = true
    write   = true
    delete  = true
    list    = true
    add     = true
    create  = true
  }
}

// Azure Role Assignment for Log Delivery
resource "azurerm_role_assignment" "log_delivery" {
  scope                = azurerm_storage_account.log_delivery.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.databricks_principal_id
}

// Databricks Configurations

// Databricks Credential Configuration for Logs
resource "databricks_mws_credentials" "log_writer" {
  account_id        = var.databricks_account_id
  credentials_name  = "${var.resource_prefix}-log-delivery-credential"
  client_id         = var.databricks_client_id
  client_secret     = var.databricks_client_secret
  tenant_id         = var.databricks_tenant_id
  depends_on = [
    azurerm_storage_account_sas.log_delivery
  ]
}

// Databricks Storage Configuration for Logs
resource "databricks_mws_storage_configurations" "log_bucket" {
  account_id                 = var.databricks_account_id
  storage_configuration_name = "${var.resource_prefix}-log-delivery-bucket"
  container_name             = azurerm_storage_container.log_delivery.name
  storage_account_name       = azurerm_storage_account.log_delivery.name
  sas_token                  = azurerm_storage_account_sas.log_delivery.sas
  depends_on = [
    azurerm_storage_account_sas.log_delivery
  ]
}

// Databricks Billable Usage Logs Configurations
resource "databricks_mws_log_delivery" "billable_usage_logs" {
  account_id               = var.databricks_account_id
  credentials_id           = databricks_mws_credentials.log_writer.credentials_id
  storage_configuration_id = databricks_mws_storage_configurations.log_bucket.storage_configuration_id
  delivery_path_prefix     = "billable-usage-logs"
  config_name              = "Billable Usage Logs"
  log_type                 = "BILLABLE_USAGE"
  output_format            = "CSV"
  depends_on = [
    azurerm_storage_account_sas.log_delivery
  ]
}

// Databricks Audit Logs Configurations
resource "databricks_mws_log_delivery" "audit_logs" {
  account_id               = var.databricks_account_id
  credentials_id           = databricks_mws_credentials.log_writer.credentials_id
  storage_configuration_id = databricks_mws_storage_configurations.log_bucket.storage_configuration_id
  delivery_path_prefix     = "audit-logs"
  config_name              = "Audit Logs"
  log_type                 = "AUDIT_LOGS"
  output_format            = "JSON"
  depends_on = [
    azurerm_storage_account_sas.log_delivery
  ]
}
