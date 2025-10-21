# ============================================
# Required Variables
# ============================================

variable "name" {
  description = "The name of the Azure Container Registry. Must be globally unique and contain only alphanumeric characters."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9]+$", var.name))
    error_message = "ACR name must contain only alphanumeric characters."
  }

  validation {
    condition     = length(var.name) >= 5 && length(var.name) <= 50
    error_message = "ACR name must be between 5 and 50 characters."
  }
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the Container Registry."
  type        = string
}

variable "location" {
  description = "The Azure region where the Container Registry should be created."
  type        = string
}

variable "sku" {
  description = "The SKU name of the container registry. Possible values are Basic, Standard and Premium."
  type        = string
  default     = "Premium"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "SKU must be one of: Basic, Standard, Premium."
  }
}

variable "tags" {
  description = "Required ALZ tags for the Azure Container Registry."
  type = object({
    SERVICE          = string
    ENVIRONMENT      = string
    SERVICE_OWNER    = string
    RESPONSIBLE_TEAM = string
    CALLOUT_TEAM     = string
    COST_CENTRE      = string
  })

  validation {
    condition     = alltrue([for k, v in var.tags : v != "" && v != null])
    error_message = "All required tags must have non-empty values."
  }
}

# ============================================
# Optional Variables - Network & Security
# ============================================

variable "public_network_access_enabled" {
  description = "Whether public network access is allowed for the container registry. Set to false for enhanced security."
  type        = bool
  default     = false
}

variable "network_rule_bypass_option" {
  description = "Whether to allow trusted Azure services to access a network-restricted Container Registry. Possible values are None and AzureServices."
  type        = string
  default     = "AzureServices"

  validation {
    condition     = contains(["None", "AzureServices"], var.network_rule_bypass_option)
    error_message = "Network rule bypass option must be None or AzureServices."
  }
}

variable "export_policy_enabled" {
  description = "Boolean value that indicates whether export policy is enabled. Must be false if public_network_access_enabled is false."
  type        = bool
  default     = true
}

variable "network_rule_set" {
  description = "Network rule set configuration for Premium SKU. Includes default action and IP rules."
  type = object({
    default_action = string
    ip_rules       = list(string)
  })
  default = null

  validation {
    condition     = var.network_rule_set == null || contains(["Allow", "Deny"], var.network_rule_set.default_action)
    error_message = "Network rule set default action must be Allow or Deny."
  }
}

# ============================================
# Optional Variables - Premium SKU Features
# ============================================

variable "quarantine_policy_enabled" {
  description = "Boolean value that indicates whether quarantine policy is enabled (Premium SKU only)."
  type        = bool
  default     = false
}

variable "retention_policy_in_days" {
  description = "The number of days to retain an untagged manifest after which it gets purged (Premium SKU only)."
  type        = number
  default     = 7

  validation {
    condition     = var.retention_policy_in_days >= 0 && var.retention_policy_in_days <= 365
    error_message = "Retention policy must be between 0 and 365 days."
  }
}

variable "trust_policy_enabled" {
  description = "Boolean value that indicates whether trust policy is enabled (Premium SKU only)."
  type        = bool
  default     = false
}

variable "zone_redundancy_enabled" {
  description = "Whether zone redundancy is enabled for this Container Registry (Premium SKU only)."
  type        = bool
  default     = false
}

variable "data_endpoint_enabled" {
  description = "Whether to enable dedicated data endpoints for this Container Registry (Premium SKU only)."
  type        = bool
  default     = false
}

# ============================================
# Optional Variables - Identity & Encryption
# ============================================

variable "identity_type" {
  description = "Specifies the type of Managed Service Identity. Possible values are SystemAssigned, UserAssigned, or SystemAssigned, UserAssigned."
  type        = string
  default     = "SystemAssigned"

  validation {
    condition     = var.identity_type == null || contains(["SystemAssigned", "UserAssigned", "SystemAssigned, UserAssigned"], var.identity_type)
    error_message = "Identity type must be SystemAssigned, UserAssigned, or SystemAssigned, UserAssigned."
  }
}

variable "identity_ids" {
  description = "List of User Assigned Managed Identity IDs to be assigned to this Container Registry."
  type        = list(string)
  default     = []
}

variable "encryption_enabled" {
  description = "Enable customer-managed key encryption (Premium SKU only)."
  type        = bool
  default     = false
}

variable "encryption_key_vault_key_id" {
  description = "The ID of the Key Vault Key for encryption (required if encryption_enabled is true)."
  type        = string
  default     = null
}

variable "encryption_identity_client_id" {
  description = "The client ID of the managed identity associated with the encryption key (required if encryption_enabled is true)."
  type        = string
  default     = null
}

# ============================================
# Optional Variables - Geo-replication
# ============================================

variable "georeplications" {
  description = "List of geo-replication configurations for Premium SKU."
  type = list(object({
    location                  = string
    regional_endpoint_enabled = optional(bool, false)
    zone_redundancy_enabled   = optional(bool, false)
    tags                      = optional(map(string), {})
  }))
  default = []
}

# ============================================
# Optional Variables - Private Endpoint
# ============================================

variable "create_private_endpoint" {
  description = "Whether to create a private endpoint for the Container Registry."
  type        = bool
  default     = false
}

variable "private_endpoint_subnet_id" {
  description = "The ID of the subnet where the private endpoint should be created."
  type        = string
  default     = null
}

variable "private_dns_zone_ids" {
  description = "List of private DNS zone IDs to associate with the private endpoint."
  type        = list(string)
  default     = null
}

# ============================================
# Optional Variables - Monitoring
# ============================================

variable "enable_diagnostic_settings" {
  description = "Whether to enable diagnostic settings for the Container Registry."
  type        = bool
  default     = true
}

variable "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics workspace to send diagnostic logs to."
  type        = string
  default     = null
}

# ============================================
# Optional Variables - Tags
# ============================================

variable "additional_tags" {
  description = "Additional tags to apply to the Container Registry beyond the required ALZ tags."
  type        = map(string)
  default     = {}
}
