# ============================================
# Basic Example - Standard SKU ACR
# ============================================

terraform {
  required_version = ">= 1.13.4"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0.0, < 5.8.1"
    }
  }
}

provider "azurerm" {
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "example" {
  name     = "rg-acr-basic-example"
  location = "UK South"

  tags = {
    SERVICE          = "container-registry"
    ENVIRONMENT      = "dev"
    SERVICE_OWNER    = "devops-chapter"
    RESPONSIBLE_TEAM = "devops"
    CALLOUT_TEAM     = "platform-support"
    COST_CENTRE      = "IT-001"
  }
}

# Deploy ACR with basic configuration
module "acr" {
  source = "../.."

  name                = "acrbasicexample001"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  sku                 = "Standard"

  # Security: Disable public access
  public_network_access_enabled = false

  # Required ALZ tags
  tags = {
    SERVICE          = "container-registry"
    ENVIRONMENT      = "dev"
    SERVICE_OWNER    = "devops-chapter"
    RESPONSIBLE_TEAM = "devops"
    CALLOUT_TEAM     = "platform-support"
    COST_CENTRE      = "IT-001"
  }

  # Additional custom tags
  additional_tags = {
    Project = "BasicExample"
  }
}

# Output the login server
output "acr_login_server" {
  description = "The login server URL for the ACR"
  value       = module.acr.login_server
}

output "acr_id" {
  description = "The resource ID of the ACR"
  value       = module.acr.id
}
