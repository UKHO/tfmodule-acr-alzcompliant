# ============================================
# Premium Example - ACR with Private Endpoint
# ============================================

terraform {
  required_version = ">= 1.13.4"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0.0, < 5.1.1"
    }
  }
}

provider "azurerm" {
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "example" {
  name     = "rg-acr-premium-example"
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

# Create a virtual network
resource "azurerm_virtual_network" "example" {
  name                = "vnet-acr-example"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  tags = azurerm_resource_group.example.tags
}

# Create a subnet for the private endpoint
resource "azurerm_subnet" "example" {
  name                 = "snet-private-endpoints"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create a private DNS zone for ACR
resource "azurerm_private_dns_zone" "acr" {
  name                = "privatelink.azurecr.io"
  resource_group_name = azurerm_resource_group.example.name

  tags = azurerm_resource_group.example.tags
}

# Link the private DNS zone to the virtual network
resource "azurerm_private_dns_zone_virtual_network_link" "acr" {
  name                  = "acr-dns-link"
  resource_group_name   = azurerm_resource_group.example.name
  private_dns_zone_name = azurerm_private_dns_zone.acr.name
  virtual_network_id    = azurerm_virtual_network.example.id

  tags = azurerm_resource_group.example.tags
}

# Create a Log Analytics workspace for monitoring
resource "azurerm_log_analytics_workspace" "example" {
  name                = "law-acr-example"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = azurerm_resource_group.example.tags
}

# Deploy ACR with premium features
module "acr" {
  source = "../.."

  name                = "acrpremiumexample001"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  sku                 = "Premium"

  # Security: Disable public access for production
  public_network_access_enabled = false
  export_policy_enabled         = false

  # Premium features
  quarantine_policy_enabled = true
  retention_policy_in_days  = 30
  trust_policy_enabled      = true
  zone_redundancy_enabled   = true
  data_endpoint_enabled     = true

  # Network rules for controlled access
  network_rule_set = {
    default_action = "Deny"
    ip_rules       = []
  }

  # Private endpoint configuration
  create_private_endpoint    = true
  private_endpoint_subnet_id = azurerm_subnet.example.id
  private_dns_zone_ids       = [azurerm_private_dns_zone.acr.id]

  # Diagnostic settings
  enable_diagnostic_settings = true
  log_analytics_workspace_id = azurerm_log_analytics_workspace.example.id

  # Geo-replication for high availability
  georeplications = [
    {
      location                  = "UK West"
      zone_redundancy_enabled   = true
      regional_endpoint_enabled = true
      tags                      = {}
    }
  ]

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
    Project          = "PremiumExample"
    Compliance       = "ALZ"
    HighAvailability = "true"
  }
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

output "private_endpoint_ip" {
  description = "The private IP address of the ACR"
  value       = module.acr.private_endpoint_ip_address
}

output "identity_principal_id" {
  description = "The principal ID for RBAC assignments"
  value       = module.acr.identity_principal_id
}
