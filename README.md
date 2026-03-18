# Azure AI Deployment Patterns — Overview Specification

## Summary

This repository contains **7 Azure AI deployment patterns** for single-region deployments, each with a dedicated Bicep IaC template and specification document. All patterns use shared, reusable Bicep modules.

Each pattern spec includes: architecture diagrams, full resource inventory, estimated costs, Azure SLAs, service limits, Well-Architected Framework alignment, and production best practices.

---

## Pattern Catalog

| # | Pattern | Landing Zone | Complexity | Cost | Security |
|---|---------|-------------|------------|------|----------|
| 1 | [Centralized Hub AI](patterns/1-centralized-hub-ai/Centralized-Hub-AI-Spec.md) | Platform (Hub) | Medium | Low (shared) | Private Endpoints |
| 2 | [Decentralized Spoke AI](patterns/2-decentralized-spoke-ai/Decentralized-Spoke-AI-Spec.md) | App (per workload) | Medium | High (duplicated) | Private Endpoints |
| 3 | [Hybrid Central + Spoke](patterns/3-hybrid-central-spoke/Hybrid-Central-Spoke-Spec.md) | Platform + App | Medium-High | Medium | VNet Peering + PE |
| 4 | [AI Factory (MLOps)](patterns/4-ai-factory-mlops/AI-Factory-MLOps-Spec.md) | Dedicated AI Factory | High | High | VNet Injection + PE |
| 5 | [Serverless AI](patterns/5-serverless-ai/Serverless-AI-Spec.md) | App / Sandbox | Low | Low | Public (PaaS auth) |
| 6 | [Secure Private AI](patterns/6-secure-private-ai/Secure-Private-AI-Spec.md) | Platform (enforced) | Very High | Very High | Zero Trust / Full Private |
| 7 | [Data-Centric Lakehouse AI](patterns/7-data-centric-lakehouse-ai/Data-Centric-Lakehouse-AI-Spec.md) | Data + App | High | High | Private Endpoints |

---

## Decision Matrix

```
                          Low Cost ◄──────────────────► High Cost
                              │                            │
  Low Complexity ─────── Pattern 5 (Serverless)            │
         │                    │                            │
         │               Pattern 1 (Hub)                   │
         │                    │                            │
         │               Pattern 3 (Hybrid) ──── Pattern 2 (Spoke)
         │                    │                            │
         │               Pattern 7 (Lakehouse) ── Pattern 4 (Factory)
         │                    │                            │
  High Complexity ────────────┼──────────── Pattern 6 (Secure)
                              │                            │
                     Low Security ◄────────────► High Security
```

---

## Pattern Selection Guide

| Scenario | Recommended Pattern |
|----------|-------------------|
| Quick PoC / internal chatbot | **5 — Serverless AI** |
| Enterprise copilot shared across BUs | **1 — Centralized Hub AI** |
| Workload with strict data isolation (PII/PCI/PHI) | **2 — Decentralized Spoke AI** |
| Shared base models + per-app RAG | **3 — Hybrid Central + Spoke** |
| Full ML lifecycle (training → serving) | **4 — AI Factory (MLOps)** |
| Regulated / zero-trust / data residency | **6 — Secure Private AI** |
| RAG on enterprise data lakehouse | **7 — Data-Centric Lakehouse AI** |

---

## 💰 Estimated Monthly Costs (USD, Canada Central)

| Pattern | Dev Estimate | Prod Estimate | Key Cost Drivers |
|---------|-------------|---------------|------------------|
| 1. Hub AI | $3,500 – $5,500 | $18,000 – $30,000 | Hub VNet, OpenAI tokens, AML compute |
| 2. Spoke AI | $6,000 – $9,000 /spoke | $25,000 – $45,000 /spoke | Duplicated OpenAI/Search/AKS per workload |
| 3. Hybrid | $4,000 – $6,500 | $20,000 – $35,000 | Shared OpenAI (hub) + per-spoke Search/compute |
| 4. AI Factory | $5,000 – $8,000 | $25,000 – $50,000 | Databricks DBUs, AML compute, ACR |
| 5. Serverless | $500 – $1,500 | $5,000 – $12,000 | OpenAI tokens, Functions consumption |
| 6. Secure AI | $8,000 – $12,000 | $35,000 – $65,000 | Firewall Premium (~$1,750/mo), PEs, Bastion |
| 7. Lakehouse | $6,000 – $10,000 | $30,000 – $55,000 | 3× ADLS, Databricks DBUs, AI Search |

### Key Pricing References
- Azure Firewall Premium: ~$1.75/hr base + $0.016/GB data processing
- AI Search: Basic $75/mo · S1 $250/mo · S2 $1,000/mo
- AKS (3× D4s_v5): ~$525/mo · (6× D8s_v5): ~$2,100/mo
- Databricks Premium DBU: ~$0.40/DBU
- OpenAI gpt-4o: ~$2.50/1M input tokens, $10/1M output tokens
- Private Endpoints: ~$7.30/mo each + $0.01/GB processed

---

## 📊 Azure Service SLAs

| Service | SLA | Key Conditions |
|---------|-----|----------------|
| Azure OpenAI | 99.9% | Standard deployment |
| Azure AI Search | 99.9% | 2+ replicas (read); 3+ replicas (read/write) |
| AKS (Standard) | 99.95% | With Availability Zones; 99.9% without |
| App Service | 99.95% | Standard tier and above |
| Azure Functions | 99.95% | Premium/Dedicated plan (no SLA on Consumption) |
| Key Vault | 99.99% | Standard and Premium |
| ADLS Gen2 / Storage | 99.9% (LRS) | 99.99% with RA-GRS/RA-GZRS |
| Azure Firewall | 99.99% | Multi-AZ deployment; 99.95% single AZ |
| Azure Databricks | 99.95% | Premium tier |
| Azure Machine Learning | 99.9% | Online endpoints |
| VNet / VNet Peering | 99.99% | — |

---

## 🏛️ Well-Architected Framework Alignment

| Pattern | Cost Optimization | Operational Excellence | Reliability | Performance | Security |
|---------|:-:|:-:|:-:|:-:|:-:|
| 1. Hub AI | ✅ | ✅ | ⚠️ | ⚠️ | ✅ |
| 2. Spoke AI | ⚠️ | ⚠️ | ✅ | ✅ | ✅ |
| 3. Hybrid | ✅ | ⚠️ | ⚠️ | ✅ | ✅ |
| 4. AI Factory | ⚠️ | ✅ | ✅ | ✅ | ⚠️ |
| 5. Serverless | ✅ | ✅ | ⚠️ | ✅ | ⚠️ |
| 6. Secure AI | ⚠️ | ⚠️ | ✅ | ✅ | ✅ |
| 7. Lakehouse | ⚠️ | ✅ | ✅ | ✅ | ⚠️ |

✅ = Excels &nbsp;&nbsp; ⚠️ = Needs Attention

---

## 📏 Key Azure Service Limits

| Service | Limit | Value |
|---------|-------|-------|
| Azure OpenAI | Resources per region/subscription | 30 |
| Azure OpenAI | Max deployments per resource | 32 |
| Azure OpenAI | gpt-4o GlobalStandard TPM | 300,000 |
| Azure OpenAI | gpt-4o-mini GlobalStandard TPM | 2,000,000 |
| AI Search (S1) | Max indexes | 50 |
| AI Search (S1) | Partition storage | 512 GB |
| AI Search | Max vector dimensions per field | 4,096 |
| AKS | Max nodes per cluster | 5,000 |
| AKS | Max pods per node (Azure CNI) | 250 |
| ADLS Gen2 | Max account capacity | 5 PiB |
| ADLS Gen2 | Max ingress (Canada Central) | 60 Gbps |
| Azure Firewall (Premium) | Max throughput | 100 Gbps |
| Databricks | Concurrent running tasks/workspace | 2,000 |

---

## Shared Modules

All patterns reference reusable Bicep modules under `modules/`:

| Module | Path | Description |
|--------|------|-------------|
| VNet | `modules/networking/vnet.bicep` | Virtual network with configurable subnets |
| Private Endpoint | `modules/networking/privateEndpoint.bicep` | PE with DNS zone integration |
| Private DNS Zone | `modules/networking/privateDnsZone.bicep` | DNS zone with VNet link |
| NSG | `modules/networking/nsg.bicep` | Network Security Group |
| Azure OpenAI | `modules/ai/openai.bicep` | Cognitive Services (OpenAI) + model deployments |
| AI Search | `modules/ai/aiSearch.bicep` | Azure AI Search service |
| Machine Learning | `modules/ai/machineLearning.bicep` | AML workspace |
| ADLS Gen2 | `modules/storage/adlsGen2.bicep` | Data Lake Storage with containers |
| AKS | `modules/compute/aks.bicep` | Kubernetes with system + GPU pools |
| App Service | `modules/compute/appService.bicep` | App Service Plan + Web App |
| Azure Functions | `modules/compute/functionApp.bicep` | Serverless Function App |
| Key Vault | `modules/security/keyVault.bicep` | Key Vault with RBAC |
| Firewall | `modules/security/firewall.bicep` | Azure Firewall + policy |
| Databricks | `modules/data/databricks.bicep` | Databricks workspace (VNet-injectable) |
| API Management | `modules/gateway/apim.bicep` | APIM gateway |
| Log Analytics | `modules/monitoring/logAnalytics.bicep` | Log Analytics workspace |
| App Insights | `modules/monitoring/appInsights.bicep` | Application Insights |

---

## Repository Structure

```
AzureAIDeployments/
├── README.md                              ← This file
├── modules/
│   ├── ai/
│   │   ├── openai.bicep
│   │   ├── aiSearch.bicep
│   │   └── machineLearning.bicep
│   ├── compute/
│   │   ├── aks.bicep
│   │   ├── appService.bicep
│   │   └── functionApp.bicep
│   ├── data/
│   │   └── databricks.bicep
│   ├── gateway/
│   │   └── apim.bicep
│   ├── monitoring/
│   │   ├── logAnalytics.bicep
│   │   └── appInsights.bicep
│   ├── networking/
│   │   ├── vnet.bicep
│   │   ├── privateEndpoint.bicep
│   │   ├── privateDnsZone.bicep
│   │   └── nsg.bicep
│   ├── security/
│   │   ├── keyVault.bicep
│   │   └── firewall.bicep
│   └── storage/
│       └── adlsGen2.bicep
└── patterns/
    ├── 1-centralized-hub-ai/
    │   ├── Centralized-Hub-AI-Spec.md
    │   ├── main.bicep
    │   └── main.bicepparam
    ├── 2-decentralized-spoke-ai/
    │   ├── Decentralized-Spoke-AI-Spec.md
    │   ├── main.bicep
    │   └── main.bicepparam
    ├── 3-hybrid-central-spoke/
    │   ├── Hybrid-Central-Spoke-Spec.md
    │   ├── main.bicep
    │   └── main.bicepparam
    ├── 4-ai-factory-mlops/
    │   ├── AI-Factory-MLOps-Spec.md
    │   ├── main.bicep
    │   └── main.bicepparam
    ├── 5-serverless-ai/
    │   ├── Serverless-AI-Spec.md
    │   ├── main.bicep
    │   └── main.bicepparam
    ├── 6-secure-private-ai/
    │   ├── Secure-Private-AI-Spec.md
    │   ├── main.bicep
    │   └── main.bicepparam
    └── 7-data-centric-lakehouse-ai/
        ├── Data-Centric-Lakehouse-AI-Spec.md
        ├── main.bicep
        └── main.bicepparam
```

---

## Default Region

All patterns default to **Canada Central** (`canadacentral`). Override via the `location` parameter.

---

## Deployment

Each pattern is independently deployable:

```bash
az deployment group create \
  --resource-group <resource-group> \
  --template-file patterns/<N>-<pattern>/main.bicep \
  --parameters patterns/<N>-<pattern>/main.bicepparam
```
