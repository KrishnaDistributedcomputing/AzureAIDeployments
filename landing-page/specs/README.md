# Azure Core Modules - Bicep Specifications Guide

Comprehensive Infrastructure as Code (Bicep) deployment templates and quick-start guides for all 16 Core Azure Modules.

## 📋 Complete Module Inventory

### 🤖 AI & Cognitive Services (4 modules)
| Module | Bicep Spec | Landing Page | Pricing (est.) | Status |
|--------|-----------|-------------|----------------|--------|
| **Azure OpenAI** | `azure-openai.bicep` | `/modules/module-openai.html` | $1,100-3,000/mo | ✅ Ready |
| **AI Search** | `azure-aisearch.bicep` | Coming soon | $73-250/mo | ✅ Ready |
| **Azure AI Foundry** | Built-in | Coming soon | Included | ✅ Ready |
| **Container Registry** | `azure-containerreg.bicep` | Coming soon | $10-50/mo | ✅ Ready |

### 💾 Data & Storage Services (3 modules)
| Module | Bicep Spec | Landing Page | Pricing (est.) | Status |
|--------|-----------|-------------|----------------|--------|
| **Cosmos DB** | `azure-cosmosdb.bicep` | Coming soon | $50-500+/mo | ✅ Ready |
| **Microsoft Fabric** | `azure-fabric.bicep` | Coming soon | $500-5,000+/mo | ✅ Ready |
| **Key Vault** | `azure-keyvault.bicep` | Coming soon | $15-50/mo | ✅ Ready |

### 🌐 Networking & Security (5 modules)
| Module | Bicep Spec | Landing Page | Pricing (est.) | Status |
|--------|-----------|-------------|----------------|--------|
| **Virtual Network** | `azure-vnet.bicep` | Coming soon | Free - $30/mo | ✅ Ready |
| **Private Link** | `azure-privatelink.bicep` | Coming soon | $0.32/day | ✅ Ready |
| **Azure Firewall** | `azure-firewall.bicep` | Coming soon | $912+/mo | ✅ Ready |
| **DDoS Protection** | `azure-ddosprotection.bicep` | Coming soon | $2,944/mo | ✅ Ready |
| **Azure Bastion** | `azure-bastion.bicep` | Coming soon | $65/mo | ✅ Ready |

### ⚡ Compute & Orchestration (2 modules)
| Module | Bicep Spec | Landing Page | Pricing (est.) | Status |
|--------|-----------|-------------|----------------|--------|
| **Container Apps** | `azure-containerapps.bicep` | Coming soon | $0.000024/vCPU-s | ✅ Ready |
| **Azure Functions** | `azure-functions.bicep` | Coming soon | $0.20/1M exec | ✅ Ready |

### 📊 Monitoring & Management (3 modules)
| Module | Bicep Spec | Landing Page | Pricing (est.) | Status |
|--------|-----------|-------------|----------------|--------|
| **Azure Monitor** | `azure-monitor.bicep` | Coming soon | $2.30-0.50/GB | ✅ Ready |
| **Event Grid** | `azure-eventgrid.bicep` | Coming soon | $0.50/1M ops | ✅ Ready |
| **Entra ID** | `azure-entraid.bicep` | Coming soon | Free-800/user | ✅ Ready |

### 🔗 Enterprise Services (2 modules)
| Module | Bicep Spec | Landing Page | Pricing (est.) | Status |
|--------|-----------|-------------|----------------|--------|
| **API Management** | `azure-apimgmt.bicep` | Coming soon | $150-500/mo | ✅ Ready |
| **SQL Managed Instance** | `azure-sqlmi.bicep` | Coming soon | $500-2,000/mo | ✅ Ready |

---

## 🚀 Quick Start: Deploying with Bicep

### Prerequisites
- Azure CLI installed (`az --version`)
- Bicep CLI (`az bicep --version` or `az bicep install`)
- Current subscription set: `az account show`

### Deploy a Single Module

```bash
# Deploy Azure OpenAI
az group create --name myResourceGroup --location eastus
az deployment group create \
  --resource-group myResourceGroup \
  --template-file azure-openai.bicep \
  --parameters location=eastus environment=prod
```

### Deploy Multiple Modules Together

```bash
# Create main.bicep to orchestrate
param location string = resourceGroup().location
param environment string = 'prod'

module openai './azure-openai.bicep' = {
  name: 'openai-deployment'
  params: {
    location: location
    environment: environment
  }
}

module search './azure-aisearch.bicep' = {
  name: 'search-deployment'
  params: {
    location: location
    environment: environment
  }
}

module vault './azure-keyvault.bicep' = {
  name: 'vault-deployment'
  params: {
    location: location
    environment: environment
  }
}

outputs:
  openaiEndpoint: string = openai.outputs.openaiEndpoint
  searchEndpoint: string = search.outputs.searchServiceEndpoint
  vaultUri: string = vault.outputs.keyVaultUri
```

---

## 📦 Typical Architecture Deployments

### 1. RAG (Retrieval-Augmented Generation) System
**Modules needed:** OpenAI, AI Search, Key Vault, Azure Monitor, Container Apps

```bash
# Deploy RAG Architecture
az deployment group create \
  --resource-group rag-rg \
  --template-file rag-architecture.bicep \
  --parameters location=eastus environment=prod
```

### 2. Enterprise GenAI Gateway
**Modules needed:** API Management, OpenAI, Cosmos DB, Key Vault, Private Link, Firewall

```bash
# Deploy GenAI Gateway
az deployment group create \
  --resource-group genai-rg \
  --template-file genai-gateway.bicep
```

### 3. Data Lake with AI Analytics
**Modules needed:** Microsoft Fabric, Cosmos DB, Container Apps, Azure Monitor, Functions

```bash
# Deploy Data Lake
az deployment group create \
  --resource-group datalake-rg \
  --template-file datalake-architecture.bicep
```

---

## 🔐 Security Best Practices

### Key Vault Integration
All specs reference Key Vault for secrets management:
```bicep
// Store connection strings in Key Vault
resource secret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'openai-api-key'
  properties: {
    value: apiKey
  }
}
```

### Network Isolation
Use Private Link + Firewall for complete network isolation:
```bicep
// Reference in your module
module privateLink './azure-privatelink.bicep' = {
  params: {
    vnetId: vnet.id
    subnetId: peSubnet.id
  }
}
```

### Managed Identity
All compute resources use Managed Identity:
```bicep
identity: {
  type: 'SystemAssigned'  // or UserAssigned
}
```

---

## 📈 Monitoring & Observability

All modules integrate with Azure Monitor:
```bicep
// Deploy monitoring first
module monitor './azure-monitor.bicep' = {
  name: 'monitoring'
  params: {
    location: location
    environment: environment
  }
}

// Reference in other modules
diagnostic: {
  logsEnabled: true
  workspaceId: monitor.outputs.workspaceId
}
```

---

## 🔄 CI/CD Integration

### GitHub Actions Example
```yaml
name: Deploy Azure Infrastructure

on: [push]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      - name: Validate Bicep
        run: |
          az bicep build --file specs/azure-openai.bicep
      - name: Deploy
        run: |
          az deployment group create \
            --resource-group myRG \
            --template-file specs/azure-openai.bicep
```

---

## 📋 Customization Guide

### Common Parameters
All specs accept standard parameters:
- `location` - Azure region (e.g., `eastus`, `ukSouth`)
- `environment` - Deployment environment (`dev`, `test`, `prod`)
- `tags` - Resource tags for organization

### Adjusting Capacity/Tier
```bicep
// In azure-openai.bicep
sku: {
  name: 'S0'  // Change to S1 for Premium
}

// In azure-monitor.bicep
properties: {
  sku: {
    name: 'PerGB2018'  // Current pricing model
  }
}
```

---

## ✅ Validation Checklist

Before deploying:
- [ ] Correct Azure subscription selected (`az account show`)
- [ ] Resource group exists or will be created
- [ ] API quotas available (especially for OpenAI TPM limits)
- [ ] Network connectivity (VNet, subnets pre-created if required)
- [ ] RBAC permissions (Contributor or higher)
- [ ] Budget alerts configured
- [ ] Monitoring & logging enabled
- [ ] Backup/DR strategy defined

---

## 🆘 Troubleshooting

### Module Deployment Fails
```bash
# Validate syntax
az bicep build --file azure-openai.bicep

# Show detailed error
az deployment group create \
  --resource-group myRG \
  --template-file azure-openai.bicep \
  --debug
```

### Quota Exceeded
For OpenAI, check TPM (tokens per minute) limits:
```bash
# Requested quota
az cognitiveservices account list --resource-group myRG
```

### Cost Overruns
```bash
# Check actual spending
az costmanagement query \
  --scope "/subscriptions/{subscriptionId}" \
  --timeframe TheLastMonth
```

---

## 📚 Reference Links

- [Bicep Documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
- [Azure OpenAI Service](https://learn.microsoft.com/en-us/azure/cognitive-services/openai/)
- [Azure Architecture Center](https://learn.microsoft.com/en-us/azure/architecture/)
- [Well-Architected Framework](https://learn.microsoft.com/en-us/azure/architecture/framework/)

---

## 📞 Support

For issues or questions:
1. Check Azure documentation for service-specific limits
2. Review diagnostic logs in Azure Portal
3. Consult Azure Support (if on support plan)
4. Review Bicep best practices: `mcp bicep get_bicep_best_practices`

---

**Last Updated:** March 2026  
**Version:** 2.0  
**Status:** All 16 modules ready for production deployment
