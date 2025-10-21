# Azure Container Registry (ACR) - ALZ Compliant Terraform Module

[![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![Azure](https://img.shields.io/badge/azure-%230072C6.svg?style=for-the-badge&logo=microsoftazure&logoColor=white)](https://azure.microsoft.com/)

This Terraform module creates an Azure Container Registry (ACR) that is compliant with Azure Landing Zone (ALZ) policies and best practices. The module provides a secure, scalable, and production-ready container registry with support for Premium features including geo-replication, customer-managed encryption, and private endpoints.

## Features

- ✅ **ALZ Compliant** - Follows Azure Landing Zone policies and best practices
- 🔒 **Security First** - Admin access disabled, anonymous pull disabled by default
- 🌍 **Geo-Replication** - Support for multi-region replication (Premium SKU)
- 🔐 **Customer-Managed Encryption** - Optional CMK encryption with Key Vault integration
- 🔗 **Private Endpoint** - Support for private network connectivity
- 📊 **Monitoring** - Integrated diagnostic settings with Log Analytics
- 🏷️ **Compliant Tagging** - Required ALZ tags enforced
- ⚡ **Premium Features** - Quarantine policy, retention policy, trust policy, zone redundancy

## Prerequisites

- Terraform >= 1.13.4
- Azure CLI or Azure PowerShell for authentication
- Azure subscription with appropriate permissions
- AzureRM provider >= 4.0.0

## Usage

### Basic Example (Standard SKU)

```hcl
module "acr" {
  source = "github.com/UKHO/tfmodule-acr-alzcompliant"

  name                = "myacr001"
  resource_group_name = "rg-container-services"
  location            = "UK South"
  sku                 = "Standard"

  # Security configuration
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
}
```

### Premium with Private Endpoint

```hcl
module "acr" {
  source = "github.com/UKHO/tfmodule-acr-alzcompliant"

  name                = "myacrpremium001"
  resource_group_name = "rg-container-services"
  location            = "UK South"
  sku                 = "Premium"

  # Security configuration
  public_network_access_enabled = false
  export_policy_enabled         = false

  # Premium features
  quarantine_policy_enabled = true
  retention_policy_in_days  = 30
  trust_policy_enabled      = true
  zone_redundancy_enabled   = true

  # Private endpoint
  create_private_endpoint    = true
  private_endpoint_subnet_id = azurerm_subnet.example.id
  private_dns_zone_ids       = [azurerm_private_dns_zone.acr.id]

  # Geo-replication
  georeplications = [
    {
      location                  = "UK West"
      zone_redundancy_enabled   = true
      regional_endpoint_enabled = true
      tags                      = {}
    }
  ]

  # Monitoring
  enable_diagnostic_settings = true
  log_analytics_workspace_id = azurerm_log_analytics_workspace.example.id

  # Required ALZ tags
  tags = {
    SERVICE          = "container-registry"
    ENVIRONMENT      = "prod"
    SERVICE_OWNER    = "devops-chapter"
    RESPONSIBLE_TEAM = "devops"
    CALLOUT_TEAM     = "platform-support"
    COST_CENTRE      = "IT-001"
  }
}
```

### Premium with Customer-Managed Encryption

```hcl
module "acr" {
  source = "github.com/UKHO/tfmodule-acr-alzcompliant"

  name                = "myacrencrypted001"
  resource_group_name = "rg-container-services"
  location            = "UK South"
  sku                 = "Premium"

  # Security configuration
  public_network_access_enabled = false

  # Managed identity
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
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.13.4 |
| azurerm | >= 4.0.0, < 5.0.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | >= 4.0.0, < 5.0.0 |

## Inputs

### Required Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | The name of the Azure Container Registry (must be globally unique, alphanumeric only, 5-50 characters) | `string` | n/a | yes |
| resource_group_name | The name of the resource group | `string` | n/a | yes |
| location | The Azure region where the Container Registry should be created | `string` | n/a | yes |
| tags | Required ALZ tags (SERVICE, ENVIRONMENT, SERVICE_OWNER, RESPONSIBLE_TEAM, CALLOUT_TEAM, COST_CENTRE) | `object` | n/a | yes |

### Optional Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| sku | The SKU name (Basic, Standard, or Premium) | `string` | `"Premium"` | no |
| public_network_access_enabled | Whether public network access is allowed | `bool` | `false` | no |
| network_rule_bypass_option | Allow trusted Azure services (None or AzureServices) | `string` | `"AzureServices"` | no |
| export_policy_enabled | Whether export policy is enabled | `bool` | `true` | no |
| quarantine_policy_enabled | Enable quarantine policy (Premium SKU only) | `bool` | `false` | no |
| retention_policy_in_days | Days to retain untagged manifests (Premium SKU only, 0-365) | `number` | `7` | no |
| trust_policy_enabled | Enable trust policy (Premium SKU only) | `bool` | `false` | no |
| zone_redundancy_enabled | Enable zone redundancy (Premium SKU only) | `bool` | `false` | no |
| data_endpoint_enabled | Enable dedicated data endpoints (Premium SKU only) | `bool` | `false` | no |
| identity_type | Type of Managed Identity (SystemAssigned, UserAssigned, or both) | `string` | `"SystemAssigned"` | no |
| identity_ids | List of User Assigned Managed Identity IDs | `list(string)` | `[]` | no |
| encryption_enabled | Enable customer-managed key encryption (Premium SKU only) | `bool` | `false` | no |
| encryption_key_vault_key_id | Key Vault Key ID for encryption | `string` | `null` | no |
| encryption_identity_client_id | Client ID of the managed identity for encryption | `string` | `null` | no |
| georeplications | List of geo-replication configurations (Premium SKU only) | `list(object)` | `[]` | no |
| network_rule_set | Network rule set with default action and IP rules (Premium SKU only) | `object` | `null` | no |
| create_private_endpoint | Whether to create a private endpoint | `bool` | `false` | no |
| private_endpoint_subnet_id | Subnet ID for the private endpoint | `string` | `null` | no |
| private_dns_zone_ids | List of private DNS zone IDs | `list(string)` | `null` | no |
| enable_diagnostic_settings | Enable diagnostic settings | `bool` | `true` | no |
| log_analytics_workspace_id | Log Analytics workspace ID for diagnostics | `string` | `null` | no |
| additional_tags | Additional tags beyond required ALZ tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | The ID of the Container Registry |
| name | The name of the Container Registry |
| login_server | The URL that can be used to log into the Container Registry |
| admin_username | The admin username (if enabled, marked sensitive) |
| admin_password | The admin password (if enabled, marked sensitive) |
| identity_principal_id | The Principal ID of the System Assigned Managed Identity |
| identity_tenant_id | The Tenant ID of the System Assigned Managed Identity |
| data_endpoint_host_names | Data endpoint hostnames (if data endpoints are enabled) |
| private_endpoint_id | The ID of the private endpoint (if created) |
| private_endpoint_ip_address | The private IP address (if private endpoint is created) |

## Examples

The `examples/` directory contains complete working examples:

- **basic** - Standard SKU ACR with minimal configuration
- **premium-with-private-endpoint** - Premium SKU with private endpoint and geo-replication
- **with-encryption** - Premium SKU with customer-managed encryption

To run an example:

```bash
cd examples/basic
terraform init
terraform plan
terraform apply
```

## Security Considerations

This module implements several security best practices:

1. **Admin Access Disabled** - Admin account is disabled by default (use RBAC instead)
2. **No Anonymous Pull** - Anonymous pull access is explicitly disabled
3. **Private Network Access** - Public network access disabled by default
4. **Customer-Managed Encryption** - Optional CMK encryption for data at rest
5. **Private Endpoints** - Support for private network connectivity
6. **Network Rules** - IP-based access control for Premium SKU
7. **Diagnostic Logging** - Comprehensive logging for security monitoring

## ALZ Compliance

This module enforces Azure Landing Zone compliance through:

- Required tagging for governance (SERVICE, ENVIRONMENT, SERVICE_OWNER, etc.)
- Security-first defaults (no admin access, no anonymous pull)
- Private network connectivity options
- Comprehensive monitoring and diagnostics
- Support for customer-managed encryption
- Zone redundancy for high availability

## SKU Comparison

| Feature | Basic | Standard | Premium |
|---------|-------|----------|---------|
| Storage | 10 GB | 100 GB | 500 GB |
| Geo-replication | ❌ | ❌ | ✅ |
| Customer-managed encryption | ❌ | ❌ | ✅ |
| Network rules | ❌ | ❌ | ✅ |
| Private endpoints | ❌ | ❌ | ✅ |
| Zone redundancy | ❌ | ❌ | ✅ |
| Quarantine policy | ❌ | ❌ | ✅ |
| Trust policy | ❌ | ❌ | ✅ |
| Retention policy | ❌ | ❌ | ✅ |
| Data endpoints | ❌ | ❌ | ✅ |

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## Security

If you discover a security vulnerability, please see [SECURITY.md](SECURITY.md) for reporting instructions.

## License

This module is maintained by UKHO and follows organizational standards and policies.

## Authors

- Devops Chapter - Initial work

## Changelog

See the [GitHub releases](../../releases) for a list of changes.

## Support

For support, please contact the Platform Team or raise an issue in the GitHub repository