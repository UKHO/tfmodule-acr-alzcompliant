# ============================================
# Azure Container Registry (ACR) Module
# ALZ Compliant Configuration
# ============================================

# Create the Azure Container Registry
resource "azurerm_container_registry" "acr" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku

  # Security: Disable admin account access (use RBAC instead)
  admin_enabled = false

  # Security: Disable anonymous pull access for compliance
  anonymous_pull_enabled = false

  # Security: Control public network access
  public_network_access_enabled = var.public_network_access_enabled

  # Premium SKU features
  quarantine_policy_enabled  = var.sku == "Premium" ? var.quarantine_policy_enabled : null
  retention_policy_in_days   = var.sku == "Premium" ? var.retention_policy_in_days : null
  trust_policy_enabled       = var.sku == "Premium" ? var.trust_policy_enabled : null
  zone_redundancy_enabled    = var.sku == "Premium" ? var.zone_redundancy_enabled : null
  export_policy_enabled      = var.export_policy_enabled
  data_endpoint_enabled      = var.sku == "Premium" ? var.data_endpoint_enabled : null
  network_rule_bypass_option = var.network_rule_bypass_option

  # Managed Identity configuration
  dynamic "identity" {
    for_each = var.identity_type != null ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = var.identity_type == "UserAssigned" || var.identity_type == "SystemAssigned, UserAssigned" ? var.identity_ids : null
    }
  }

  # Customer-managed encryption (Premium SKU only)
  dynamic "encryption" {
    for_each = var.encryption_enabled && var.sku == "Premium" ? [1] : []
    content {
      key_vault_key_id   = var.encryption_key_vault_key_id
      identity_client_id = var.encryption_identity_client_id
    }
  }

  # Geo-replication configuration (Premium SKU only)
  dynamic "georeplications" {
    for_each = var.sku == "Premium" ? var.georeplications : []
    content {
      location                  = georeplications.value.location
      regional_endpoint_enabled = georeplications.value.regional_endpoint_enabled
      zone_redundancy_enabled   = georeplications.value.zone_redundancy_enabled
      tags                      = georeplications.value.tags
    }
  }

  # Network rules (Premium SKU only)
  dynamic "network_rule_set" {
    for_each = var.sku == "Premium" && var.network_rule_set != null ? [var.network_rule_set] : []
    content {
      default_action = network_rule_set.value.default_action

      dynamic "ip_rule" {
        for_each = network_rule_set.value.ip_rules
        content {
          action   = "Allow"
          ip_range = ip_rule.value
        }
      }
    }
  }

  # ALZ required tags
  tags = merge(
    {
      SERVICE          = var.tags.SERVICE
      ENVIRONMENT      = var.tags.ENVIRONMENT
      SERVICE_OWNER    = var.tags.SERVICE_OWNER
      RESPONSIBLE_TEAM = var.tags.RESPONSIBLE_TEAM
      CALLOUT_TEAM     = var.tags.CALLOUT_TEAM
      COST_CENTRE      = var.tags.COST_CENTRE
    },
    var.additional_tags
  )

  lifecycle {
    precondition {
      condition     = var.sku == "Premium" || (var.georeplications == null || length(var.georeplications) == 0)
      error_message = "Geo-replication is only supported with Premium SKU."
    }

    precondition {
      condition     = var.sku == "Premium" || var.network_rule_set == null
      error_message = "Network rules are only supported with Premium SKU."
    }

    precondition {
      condition     = var.sku == "Premium" || !var.encryption_enabled
      error_message = "Customer-managed encryption is only supported with Premium SKU."
    }
  }
}

# Optional: Private endpoint for private network access
resource "azurerm_private_endpoint" "acr" {
  count               = var.create_private_endpoint ? 1 : 0
  name                = "${var.name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.name}-psc"
    private_connection_resource_id = azurerm_container_registry.acr.id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_ids != null ? [1] : []
    content {
      name                 = "default"
      private_dns_zone_ids = var.private_dns_zone_ids
    }
  }

  tags = merge(
    {
      SERVICE          = var.tags.SERVICE
      ENVIRONMENT      = var.tags.ENVIRONMENT
      SERVICE_OWNER    = var.tags.SERVICE_OWNER
      RESPONSIBLE_TEAM = var.tags.RESPONSIBLE_TEAM
      CALLOUT_TEAM     = var.tags.CALLOUT_TEAM
      COST_CENTRE      = var.tags.COST_CENTRE
    },
    var.additional_tags
  )
}

# Optional: Diagnostic settings for monitoring and compliance
resource "azurerm_monitor_diagnostic_setting" "acr" {
  count                      = var.enable_diagnostic_settings ? 1 : 0
  name                       = "${var.name}-diag"
  target_resource_id         = azurerm_container_registry.acr.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  # Enable all available log categories
  enabled_log {
    category = "ContainerRegistryRepositoryEvents"
  }

  enabled_log {
    category = "ContainerRegistryLoginEvents"
  }

  # Enable all metrics (using enabled_metric instead of deprecated metric)
  enabled_metric {
    category = "AllMetrics"
  }
}
