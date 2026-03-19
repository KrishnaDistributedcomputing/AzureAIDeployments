# Pattern 3: Hybrid Pattern (Central AI + Spoke Inference)

## 📌 Pattern Overview

Core AI services are **centralized in the Hub** (base models, model registry), while **inference, customization, and RAG components** are deployed in application spokes. This balances cost efficiency with workload autonomy.

---

## 🏗️ Architecture (Single Region)

| Layer | Component | Azure Service |
|-------|-----------|---------------|
| **Region** | Canada Central | — |
| **Hub (Platform LZ)** | Base LLM Models | Azure OpenAI (GPT-4o, Embeddings) |
| | Model Registry & Training | Azure Machine Learning |
| | Secrets | Azure Key Vault |
| | Model/Dataset Storage | ADLS Gen2 |
| | Monitoring | Log Analytics + App Insights |
| **Spoke (App LZ)** | Vector DB / RAG | Azure AI Search |
| | Workload Data | ADLS Gen2 (per-workload) |
| | App Compute | App Service **or** AKS (selectable) |
| | Private Connectivity | VNet Peering to Hub |

### Network Topology

```
┌──────────────────────────────────────────┐
│          Hub VNet (10.0.0.0/16)          │
│                                          │
│  ┌──────────────┐  ┌─────────────────┐   │
│  │ Azure OpenAI  │  │ AML + KV + ADLS│   │
│  │ (base models) │  │ (registry)     │   │
│  │   PE: /24     │  │   PE: /24      │   │
│  └──────┬───────┘  └──────┬──────────┘   │
└─────────┼──────────────────┼─────────────┘
          │   VNet Peering   │
          │                  │
┌─────────┴──────────────────┴─────────────┐
│        Spoke VNet (10.1.0.0/16)          │
│                                          │
│  ┌──────────┐  ┌──────────┐  ┌────────┐ │
│  │ AI Search│  │ App Svc  │  │  ADLS  │ │
│  │ (vector) │  │ or AKS   │  │ (docs) │ │
│  │  PE: /24 │  │  /24     │  │        │ │
│  └──────────┘  └──────────┘  └────────┘ │
└──────────────────────────────────────────┘
```

---

## 📦 Azure Resources Deployed

### Hub Layer

| Resource | Name Pattern | SKU / Tier |
|----------|-------------|------------|
| Azure OpenAI | `{base}-hub-{env}-openai` | S0 |
| Azure Machine Learning | `{base}-hub-{env}-aml` | — |
| ADLS Gen2 | `{base}hub{env}sa` | Standard_LRS, HNS |
| Key Vault | `{base}-hub-{env}-kv` | Standard |
| Hub VNet | `{base}-hub-{env}-vnet` | /16, 3 subnets |
| Private DNS Zones | 5 zones | Global |
| Private Endpoints | OpenAI PE | — |

### Spoke Layer (Per Workload)

| Resource | Name Pattern | SKU / Tier |
|----------|-------------|------------|
| Azure AI Search | `{base}-{spoke}-{env}-search` | Standard, Semantic |
| ADLS Gen2 | `{base}{spoke}{env}sa` | Standard_LRS, HNS |
| App Service **or** AKS | `{base}-{spoke}-{env}-app/aks` | P1v3 / D4s_v5 |
| Spoke VNet | `{base}-{spoke}-{env}-vnet` | /16, 3 subnets |
| VNet Peering | Hub↔Spoke (bidirectional) | — |
| Private Endpoints | AI Search PE | — |

### Hub OpenAI Model Deployments

| Deployment Name | Model | Version | Capacity (TPM) | SKU |
|----------------|-------|---------|-----------------|-----|
| gpt-4o | gpt-4o | 2024-08-06 | 50K | GlobalStandard |
| text-embedding-3-large | text-embedding-3-large | 1 | 120K | Standard |

### Storage Layout

| Account | Containers | Owner |
|---------|-----------|-------|
| Hub ADLS | `models`, `datasets`, `artifacts` | Platform team |
| Spoke ADLS | `documents`, `embeddings`, `cache` | App team |

---

## 🔐 Security & Networking

- Hub AI services behind **Private Endpoints**
- Spoke connects to Hub via **bidirectional VNet Peering**
- **Private DNS Zones** linked to Hub VNet (shared resolution)
- App Service uses **VNet Integration** for outbound to private endpoints
- Key Vault uses **RBAC authorization**
- App identity injected as **App Settings** referencing Hub OpenAI endpoint

---

## ✅ Use Cases

- **CSI-style vertical applications** — custom RAG logic per business unit, shared base models
- **RAG-based applications** — spoke owns the vector DB + documents, hub owns the LLM
- **Controlled reuse of base models** — single OpenAI deployment, per-spoke search indexes
- Cost-efficient pattern for organizations with many small AI-powered apps

---

## ⚠️ Constraints & Considerations

| Constraint | Mitigation |
|-----------|------------|
| Model versioning governance needed | Use AML model registry with staged deployments |
| Data movement between hub and spokes | Use managed identities + Private Link for secure access |
| Shared OpenAI quota across spokes | Implement per-spoke throttling via APIM or app-level rate limiting |
| Network latency (peering) | Minimal within same region; monitor P95 latency |
| Spoke depends on Hub availability | Monitor Hub services; consider read replicas for AI Search |

---

## 🚀 Deployment

```bash
# Deploy hub + one spoke together
az deployment group create \
  --resource-group rg-hybrid-ai-dev \
  --template-file main.bicep \
  --parameters main.bicepparam
```

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `location` | string | `canadacentral` | Target region |
| `environmentName` | enum | `dev` | dev / staging / prod |
| `baseName` | string | `hybrid` | Naming prefix |
| `spokeWorkloadName` | string | `app1` | Spoke identifier |
| `hubVnetAddressPrefix` | string | `10.0.0.0/16` | Hub CIDR |
| `spokeVnetAddressPrefix` | string | `10.1.0.0/16` | Spoke CIDR |
| `useAppService` | bool | `true` | `true` = App Service, `false` = AKS |
| `hubOpenAiDeployments` | array | GPT-4o + Embeddings | Hub model configs |

---

## � Estimated Monthly Cost (USD, Canada Central)

| Environment | Estimate | Key Cost Drivers |
|-------------|----------|------------------|
| **Dev** | $4,000 – $6,500 | Shared OpenAI (hub) + per-spoke App Service/Search |
| **Moderate Prod** | **~$5,685/mo** | ~500M tokens/mo, shared hub OpenAI, AI Search S1, App Service |
| **Prod (scaled)** | $20,000 – $35,000 | Hub OpenAI quota, App Service P1v3, AI Search S1 per spoke |

### Component Breakdown (Moderate Production, ~500M tokens/mo)

| Service | SKU / Tier | Unit Price (March 2026) |
|---------|-----------|------------------------|
| Azure OpenAI GPT-4o (hub) | Global Standard | $2.50/1M input tokens, $10/1M output tokens |
| text-embedding-3-small | Standard | $0.022/1M tokens |
| AI Search | S1 | $245.28/mo |
| APIM v2 | Basic | $150.01/mo |
| App Service | P1v3 | ~$115/mo |
| Azure ML Compute | D4s v3 | $140.16/mo |
| Key Vault | Standard | $0.03/10K transactions |
| Azure Monitor (Log Analytics) | Per-GB | $2.30/GB ingested |
| Private Endpoints | Per endpoint | ~$7.30/mo each |

> Prices sourced from [Azure Pricing Pages](https://azure.microsoft.com/pricing/) (March 2026). Most cost-efficient multi-workload pattern — hub absorbs expensive AI services.

---

## 📊 Azure Service SLAs

| Service | SLA | Conditions |
|---------|-----|------------|
| Azure OpenAI | 99.9% | Standard deployment |
| Azure AI Search | 99.9% | 2+ replicas for read HA |
| App Service | 99.95% | Standard tier and above |
| AKS (Standard) | 99.95% (with AZs) | If AKS chosen over App Service |
| Azure Machine Learning | 99.9% | Online endpoints |
| Key Vault | 99.99% | — |
| VNet Peering | 99.99% | — |

---

## 📏 Key Azure Service Limits

| Service | Limit | Value |
|---------|-------|-------|
| Azure OpenAI | gpt-4o GlobalStandard TPM | 300,000 (shared across spokes) |
| Azure OpenAI | text-embedding-3-large TPM | 1,000,000 |
| AI Search (S1) | Max indexes | 50 per spoke search service |
| AI Search | Indexer schedule min interval | 5 minutes |
| AI Search | Max indexer run time (private) | 24 hours |
| App Service | Max instances (Standard) | 30 |

---

## 🏛️ Well-Architected Framework Alignment

| Pillar | Rating | Notes |
|--------|--------|-------|
| **Cost Optimization** | ✅ Excels | Expensive services (OpenAI, AML) shared; spokes pay only for search + compute |
| **Security** | ✅ Excels | Centralized identity/model access in hub |
| **Operational Excellence** | ⚠️ Attention | Split ownership (hub team vs. spoke team) requires clear RACI |
| **Reliability** | ⚠️ Attention | Spoke depends on hub availability for LLM calls |
| **Performance Efficiency** | ✅ Good | VNet peering latency is sub-millisecond within region |

---

## 🔬 Best Practices

### Hub-Spoke Model Versioning
- Use AML Model Registry for versioned model deployment
- Tag hub OpenAI deployments with version labels
- Implement canary deployments: route 10% traffic to new model version

### RAG Pattern in Spoke
- AI Search indexes should use **integrated vectorization** with hub OpenAI embedding skill
- Enable **incremental enrichment** cache to avoid reprocessing unchanged documents
- Schedule indexers at 5-minute intervals for near-real-time updates
- Use **shared private link** from AI Search to spoke ADLS for private data access

### App Service VNet Integration
- Use **regional VNet integration** (subnet delegation to `Microsoft.Web/serverFarms`)
- Outbound calls to hub OpenAI traverse VNet peering → Private Endpoint
- Set `WEBSITE_VNET_ROUTE_ALL=1` to route all traffic through VNet

---

## �📁 Files

| File | Purpose |
|------|---------|
| `Hybrid-Central-Spoke-Spec.md` | This specification document |
| `main.bicep` | Hub + Spoke combined deployment |
| `main.bicepparam` | Default parameters (claims spoke) |
