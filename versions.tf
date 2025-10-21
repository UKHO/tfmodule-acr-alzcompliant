# ============================================
# Terraform and Provider Version Constraints
# ============================================

terraform {
  required_version = ">= 1.13.4"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0.0, < 5.0.0"
    }
  }
}
