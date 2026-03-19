# Pattern 1: Centralized AI Platform (Hub AI Pattern)

## 📌 Pattern Overview

A **single-region shared AI platform** hosted in the Platform Landing Zone (Hub) and consumed by multiple application spokes. All AI services are centrally managed, governed, and shared across business units.

---

## 🏗️ Architecture (Single Region)

| Layer | Component | Azure Service |
|-------|-----------|---------------|
| **Region** | Canada Central | — |
| **Hub (Platform LZ)** | LLM / Chat Completions | Azure OpenAI (GPT-4o) |
| | Embeddings | Azure OpenAI (text-embedding-3-large) |
| | ML Workspace & Registry | Azure Machine Learning |
| | Vector / Semantic Search | Azure AI Search |
| | Data Lake | ADLS Gen2 |
| | Secrets Management | Azure Key Vault |
| | Monitoring | Log Analytics + Application Insights |
| **Spokes (App LZ)** | Application Compute | AKS / App Service |
| | Private Access | VNet Peering → Hub AI Services |

### Network Topology

```
┌─────────────────────────────────────────────────────────┐
│                    Hub VNet (10.0.0.0/16)                │
│  ┌──────────────┐  ┌──────────┐  ┌──────────────────┐  │
│  │ Azure OpenAI  │  │ AI Search│  │ AML + ADLS + KV  │  │
│  │  (PE: /24)    │  │ (PE)     │  │   (PE: /24)      │  │
│  └──────────────┘  └──────────┘  └──────────────────┘  │
│        ▲                ▲                ▲               │
│        │   Private Endpoints + DNS Zones │               │
└────────┼────────────────┼────────────────┼───────────────┘
         │  VNet Peering  │                │
    ┌────┴────┐      ┌────┴────┐      ┌────┴────┐
    │ Spoke 1 │      │ Spoke 2 │      │ Spoke N │
    │ AKS/App │      │ AKS/App │      │ AKS/App │
    │10.1.0/16│      │10.2.0/16│      │10.N.0/16│
    └─────────┘      └─────────┘      └─────────┘
```

---

## 📦 Azure Resources Deployed

| Resource | Name Pattern | SKU / Tier |
|----------|-------------|------------ |
| Azure OpenAI | `{baseName}-{env}-openai` | S0 |
| Azure AI Search | `{baseName}-{env}-search` | Standard, Semantic: Standard |
| Azure Machine Learning | `{baseName}-{env}-aml` | — |
| ADLS Gen2 | `{baseName}{env}adls` | Standard_LRS, HNS enabled |
| Key Vault | `{baseName}-{env}-kv` | Standard, RBAC auth, purge-protected |
| Log Analytics | `{baseName}-{env}-law` | PerGB2018, 90-day retention |
| Application Insights | `{baseName}-{env}-ai` | Workspace-based |
| Hub VNet | `{baseName}-{env}-hub-vnet` | /16 with 4 subnets |
| Spoke VNets (×N) | `{baseName}-{env}-spoke-{n}-vnet` | /16 with 2 subnets each |
| Private DNS Zones | 6 zones (OpenAI, Search, KV, Blob, DFS, AML) | Global |
| Private Endpoints | Per AI service | — |
| NSG | `{baseName}-{env}-hub-nsg` | DenyAllInbound default |

### OpenAI Model Deployments

| Deployment Name | Model | Version | Capacity (TPM) | SKU |
|----------------|-------|---------|-----------------|-----|
| gpt-4o | gpt-4o | 2024-08-06 | 30K | GlobalStandard |
| text-embedding-3-large | text-embedding-3-large | 1 | 120K | Standard |

### Storage Containers

| Container | Purpose |
|-----------|---------|
| `raw` | Raw ingested data |
| `processed` | Transformed/cleaned data |
| `models` | Trained model artifacts |
| `embeddings` | Generated embedding vectors |

---

## 🔐 Security & Networking

- All AI services accessed via **Private Endpoints** within the Hub VNet
- Spokes connect through **VNet Peering** (hub-to-spoke + spoke-to-hub)
- **Private DNS Zones** linked to Hub VNet for name resolution
- Key Vault uses **RBAC authorization** (no access policies)
- NSG with **DenyAllInbound** default rule on Hub subnets
- TLS 1.2 minimum on all storage

---

## ✅ Use Cases

- Enterprise-wide copilots (shared GPT-4o across multiple apps)
- Shared AI services across CSI business units
- Controlled cost + centralized governance
- Standardized model management via AML registry

---

## ⚠️ Constraints & Considerations

| Constraint | Mitigation |
|-----------|------------|
| Shared quota limits (OpenAI TPM/RPM) | Implement per-spoke rate limiting; request quota increases |
| Requires strong RBAC + isolation strategy | Use Azure RBAC per-spoke, service-level RBAC on OpenAI |
| Single point of failure for AI services | Monitor with App Insights; plan capacity headroom |
| Cross-spoke data leakage risk | Separate storage containers per spoke; enforce RBAC |

---

## 🚀 Deployment

```bash
# Deploy to a resource group
az deployment group create \
  --resource-group rg-hub-ai-dev \
  --template-file main.bicep \
  --parameters main.bicepparam
```

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `location` | string | `canadacentral` | Target Azure region |
| `environmentName` | enum | `dev` | dev / staging / prod |
| `baseName` | string | `hubai` | Prefix for all resource names |
| `spokeCount` | int | `2` | Number of spoke VNets (1-10) |
| `spokeVnetAddressPrefixes` | string[] | `['10.1.0.0/16','10.2.0.0/16']` | One CIDR per spoke |
| `openAiDeployments` | array | GPT-4o + Embeddings | Model deployment configs |
| `hubVnetAddressPrefix` | string | `10.0.0.0/16` | Hub VNet CIDR |

---

## � Estimated Monthly Cost (USD, Canada Central)

| Environment | Estimate | Key Cost Drivers |
|-------------|----------|------------------|
| **Dev** | $3,500 – $5,500 | Hub VNet infra, OpenAI token consumption, AML compute |
| **Moderate Prod** | **~$3,723/mo** | ~500M tokens/mo, AI Search S1, APIM Basic, AML D4s v3 |
| **Prod (scaled)** | $18,000 – $30,000 | AI Search S1, AKS clusters, multiple PEs, high token volume |

### Component Breakdown (Moderate Production, ~500M tokens/mo)

| Service | SKU / Tier | Unit Price (March 2026) |
|---------|-----------|------------------------|
| Azure OpenAI GPT-4o | Global Standard | $2.50/1M input tokens, $10/1M output tokens |
| text-embedding-3-small | Standard | $0.022/1M tokens |
| AI Search | S1 | $245.28/mo |
| APIM v2 | Basic | $150.01/mo |
| Azure ML Compute | D4s v3 | $140.16/mo |
| Key Vault | Standard | $0.03/10K transactions |
| Azure Monitor (Log Analytics) | Per-GB | $2.30/GB ingested |
| Private Endpoints | Per endpoint | ~$7.30/mo each |

> Prices sourced from [Azure Pricing Pages](https://azure.microsoft.com/pricing/) (March 2026). VNet Peering: ~$0.01/GB transferred.

---

## 📊 Azure Service SLAs

| Service | SLA | Conditions |
|---------|-----|------------|
| Azure OpenAI | 99.9% | Standard deployment |
| Azure AI Search | 99.9% | Requires 2+ replicas for read HA; 3+ for read/write |
| Azure Machine Learning | 99.9% | Online endpoints |
| ADLS Gen2 (LRS) | 99.9% | 99.99% with RA-GRS |
| Key Vault | 99.99% | Standard and Premium |
| VNet Peering | 99.99% | — |
| Log Analytics | 99.9% | — |

---

## 📏 Key Azure Service Limits

| Service | Limit | Value |
|---------|-------|-------|
| Azure OpenAI | Resources per region/sub | 30 |
| Azure OpenAI | Max deployments per resource | 32 |
| Azure OpenAI | gpt-4o GlobalStandard TPM | 300,000 |
| AI Search (S1) | Max indexes | 50 |
| AI Search (S1) | Partition storage | 512 GB |
| AI Search | Max vector dimensions | 4,096 |
| ADLS Gen2 | Default account capacity | 5 PiB |
| ADLS Gen2 | Max ingress (Canada Central) | 60 Gbps |

---

## 🏛️ Well-Architected Framework Alignment

| Pillar | Rating | Notes |
|--------|--------|-------|
| **Cost Optimization** | ✅ Excels | Shared resources across spokes reduce per-workload cost |
| **Operational Excellence** | ✅ Excels | Central governance, single point of management |
| **Reliability** | ⚠️ Attention | Single hub = potential SPOF; plan capacity headroom |
| **Performance Efficiency** | ⚠️ Attention | Cross-VNet latency (minimal within region); shared quota contention |
| **Security** | ✅ Good | Private Endpoints + centralized RBAC |

---

## 🔬 Best Practices

### Private Endpoint DNS Resolution
```
Client → Azure Private DNS Zone → Private Endpoint IP (10.x.x.x)
resource.openai.azure.com → CNAME resource.privatelink.openai.azure.com → A → 10.0.1.5
```
- Link private DNS zones to Hub VNet; use DNS forwarders for spoke resolution
- For cross-VNet: link DNS zones to each spoke VNet or use centralized DNS forwarder

### OpenAI Token Management
- Implement **exponential backoff** with jitter (1s initial, 2× multiplier, 60s max)
- Monitor `x-ratelimit-remaining-tokens` and `x-ratelimit-remaining-requests` headers
- Set `max_tokens` explicitly to prevent unbounded responses
- Implement **circuit breaker**: open after 5 consecutive 429s, half-open after 30s
- Consider **Provisioned Throughput Units (PTU)** for predictable prod latency

### Spoke Quota Management
- Implement per-spoke rate limiting via APIM or application-level throttling
- Request OpenAI quota increases proactively for production
- Use Global Batch API for async bulk workloads (up to 50M tokens enqueued)

---

## �📁 Files

| File | Purpose |
|------|---------|
| `Centralized-Hub-AI-Spec.md` | This specification document |
| `main.bicep` | Full infrastructure-as-code deployment |
| `main.bicepparam` | Default parameter values for dev |
