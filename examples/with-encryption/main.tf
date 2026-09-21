# ============================================
# Premium Example - ACR with Customer-Managed Encryption
# ============================================

terraform {
  required_version = ">= 1.13.4"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0.0, < 5.6.1"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
  }
}

# Get current client configuration
data "azurerm_client_config" "current" {}

# Create a resource group
resource "azurerm_resource_group" "example" {
  name     = "rg-acr-encryption-example"
  location = "UK South"

  tags = {
    SERVICE          = "container-registry"
    ENVIRONMENT      = "prod"
    SERVICE_OWNER    = "devops-chapter"
    RESPONSIBLE_TEAM = "devops"
    CALLOUT_TEAM     = "platform-support"
    COST_CENTRE      = "IT-001"
  }
}

# Create a user-assigned managed identity for encryption
resource "azurerm_user_assigned_identity" "acr" {
  name                = "id-acr-encryption"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location

  tags = azurerm_resource_group.example.tags
}

# Create a Key Vault
resource "azurerm_key_vault" "example" {
  name                       = "kv-acr-enc-${substr(uuid(), 0, 8)}"
  location                   = azurerm_resource_group.example.location
  resource_group_name        = azurerm_resource_group.example.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "premium"
  soft_delete_retention_days = 7
  purge_protection_enabled   = true

  tags = azurerm_resource_group.example.tags
}

# Grant the managed identity access to the Key Vault
resource "azurerm_key_vault_access_policy" "acr_identity" {
  key_vault_id = azurerm_key_vault.example.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.acr.principal_id

  key_permissions = [
    "Get",
    "UnwrapKey",
    "WrapKey"
  ]
}

# Grant the current user access to create keys
resource "azurerm_key_vault_access_policy" "current_user" {
  key_vault_id = azurerm_key_vault.example.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions = [
    "Get",
    "Create",
    "Delete",
    "List",
    "Update",
    "GetRotationPolicy"
  ]
}

# Create a key for encryption
resource "azurerm_key_vault_key" "acr" {
  name         = "acr-encryption-key"
  key_vault_id = azurerm_key_vault.example.id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey"
  ]

  depends_on = [
    azurerm_key_vault_access_policy.current_user,
    azurerm_key_vault_access_policy.acr_identity
  ]

  tags = azurerm_resource_group.example.tags
}

# Deploy ACR with customer-managed encryption
module "acr" {
  source = "../.."

  name                = "acrencryptionex001"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  sku                 = "Premium"

  # Security configuration
  public_network_access_enabled = false
  export_policy_enabled         = false

  # Premium features
  zone_redundancy_enabled = true

  # Managed identity configuration
  identity_type = "UserAssigned"
  identity_ids  = [azurerm_user_assigned_identity.acr.id]

  # Customer-managed encryption
  encryption_enabled            = true
  encryption_key_vault_key_id   = azurerm_key_vault_key.acr.id
  encryption_identity_client_id = azurerm_user_assigned_identity.acr.client_id

  # Required ALZ tags
  tags = {
    SERVICE          = "container-registry"
    ENVIRONMENT      = "prod"
    SERVICE_OWNER    = "devops-chapter"
    RESPONSIBLE_TEAM = "devops"
    CALLOUT_TEAM     = "platform-support"
    COST_CENTRE      = "IT-001"
  }

  # Additional custom tags
  additional_tags = {
    Project    = "EncryptionExample"
    Compliance = "ALZ"
    Encrypted  = "true"
  }

  depends_on = [
    azurerm_key_vault_access_policy.acr_identity
  ]
}

# Outputs
output "acr_login_server" {
  description = "The login server URL for the ACR"
  value       = module.acr.login_server
}

output "acr_id" {
  description = "The resource ID of the ACR"
  value       = module.acr.id
}

output "identity_principal_id" {
  description = "The principal ID of the user-assigned identity"
  value       = module.acr.identity_principal_id
}
