# Quick Start Guide - ACR ALZ Module

## 1. Basic Deployment (Standard SKU)

For development and testing environments:

```hcl
module "acr" {
  source = "github.com/UKHO/tfmodule-acr-alzcompliant"

  name                = "myacr${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  sku                 = "Standard"

  public_network_access_enabled = false

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

## 2. Production Deployment (Premium SKU with Private Endpoint)

For production environments with enhanced security:

```hcl
module "acr" {
  source = "github.com/UKHO/tfmodule-acr-alzcompliant"

  name                = "myacrprod${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  sku                 = "Premium"

  # Security - Disable public access
  public_network_access_enabled = false
  export_policy_enabled         = false

  # Premium features
  quarantine_policy_enabled = true
  retention_policy_in_days  = 30
  trust_policy_enabled      = true
  zone_redundancy_enabled   = true

  # Private endpoint
  create_private_endpoint    = true
  private_endpoint_subnet_id = azurerm_subnet.pe.id
  private_dns_zone_ids       = [azurerm_private_dns_zone.acr.id]

  # Monitoring
  enable_diagnostic_settings = true
  log_analytics_workspace_id = azurerm_log_analytics_workspace.example.id

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

## 3. Testing the Module

### Validate Configuration
```bash
terraform init
terraform validate
terraform fmt -check
```

### Plan Deployment
```bash
terraform plan -out=tfplan
```

### Apply Changes
```bash
terraform apply tfplan
```

## 4. Post-Deployment Tasks

### Log in to ACR (with Azure CLI)
```bash
az acr login --name <acr_name>
```

### Push an Image
```bash
docker tag myimage:latest <acr_login_server>/myimage:latest
docker push <acr_login_server>/myimage:latest
```

### Grant AKS Access (if using with AKS)
```bash
az aks update -n myAKS -g myResourceGroup --attach-acr <acr_name>
```

## 5. RBAC Roles for ACR

Common Azure RBAC roles for ACR access:

- **AcrPull** - Pull images (read-only)
- **AcrPush** - Push and pull images
- **AcrDelete** - Delete images
- **Owner/Contributor** - Full management access

Example granting AKS cluster access:
```hcl
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name = "AcrPull"
  scope                = module.acr.id
}
```

## 6. Monitoring and Diagnostics

The module automatically enables diagnostic settings when `enable_diagnostic_settings = true`.

Key metrics to monitor:
- **Repository Events** - Push, pull, delete operations
- **Login Events** - Authentication attempts
- **Storage Usage** - Registry storage consumption
- **Webhook Calls** - Webhook trigger events

## 7. Troubleshooting

### Issue: Can't push/pull images
- Verify RBAC permissions (`AcrPull` or `AcrPush` role)
- Check network connectivity if using private endpoint
- Ensure authenticated: `az acr login --name <acr_name>`

### Issue: Private endpoint not working
- Verify DNS resolution points to private IP
- Check NSG rules allow traffic on port 443
- Ensure private DNS zone is linked to VNet

### Issue: Geo-replication not working
- Verify Premium SKU is selected
- Check replication regions don't include primary location
- Confirm sufficient quota in target regions

## 8. Cost Optimization

- Use **Basic SKU** for dev/test (£0.004/day + storage)
- Use **Standard SKU** for pre-production
- Use **Premium SKU** for production only when features are needed
- Enable retention policies to automatically purge old images
- Monitor storage usage and clean up unused images regularly

## 9. Security Best Practices

✅ **Do:**
- Use private endpoints for production
- Enable diagnostic logging
- Use RBAC instead of admin accounts
- Enable quarantine and trust policies (Premium)
- Use customer-managed encryption for sensitive workloads
- Regularly scan images with Defender for Containers

❌ **Don't:**
- Enable admin access in production
- Allow anonymous pull access
- Use public network access for sensitive workloads
- Hardcode credentials in code

## 10. Compliance Checklist

- [ ] All required ALZ tags are present
- [ ] Admin access is disabled
- [ ] Anonymous pull is disabled
- [ ] Public network access is restricted
- [ ] Diagnostic settings are enabled
- [ ] Retention policy is configured
- [ ] RBAC roles are properly assigned
- [ ] Images are regularly scanned for vulnerabilities
