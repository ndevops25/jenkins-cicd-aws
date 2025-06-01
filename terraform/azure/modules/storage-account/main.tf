resource "azurerm_storage_account" "sa" {
  name                     = lower(replace("${var.prefix}sa${random_string.suffix.result}", "-", ""))
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
  min_tls_version          = "TLS1_2"
  
  # Permitir acesso de blob público se necessário
  allow_nested_items_to_be_public = true
  
  tags = var.tags
}

# Adicionar sufixo aleatório para garantir nome único
resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

resource "azurerm_storage_container" "container" {
  name                  = var.container_name
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
  
  depends_on = [azurerm_storage_account.sa]
}