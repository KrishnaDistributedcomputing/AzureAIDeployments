# Pattern 2: Decentralized AI per Workload (Spoke AI Pattern)

## 📌 Pattern Overview

Each application has its **own complete AI stack** deployed inside its own landing zone, all within the same region. There is **no dependency on a central AI hub** — every workload is fully self-contained with its own Azure OpenAI, storage, search, and compute.

---

## 🏗️ Architecture (Single Region)

| Layer | Component | Azure Service |
|-------|-----------|---------------|
| **Region** | Canada Central | — |
| **Per-Workload Spoke** | LLM / Chat | Azure OpenAI |
| | Vector Search | Azure AI Search |
| | Data Lake | ADLS Gen2 (HNS) |
| | Secrets | Azure Key Vault |
| | Container Compute | AKS (system + optional GPU pools) |
| | Monitoring | Log Analytics + App Insights |
| | Networking | Dedicated VNet, NSG, Private Endpoints |

### Network Topology

```
    ┌─────────────────────────────────────────────┐
    │         Workload VNet (10.10.0.0/16)        │
    │                                             │
    │  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
    │  │ AKS Nodes│  │ Private  │  │   Data   │  │
    │  │   /20    │  │ Endpoints│  │ Endpoints│  │
    │  │          │  │   /24    │  │   /24    │  │
    │  └──────────┘  └──────────┘  └──────────┘  │
    │                     │                       │
    │         ┌───────────┼───────────┐           │
    │         ▼           ▼           ▼           │
    │   Azure OpenAI  AI Search   ADLS + KV      │
    │    (Private)    (Private)   (Private)       │
    └─────────────────────────────────────────────┘

    (Each workload is an independent, isolated copy)
```

---

## 📦 Azure Resources Deployed (Per Workload)

| Resource | Name Pattern | SKU / Tier |
|----------|-------------|------------|
| Azure OpenAI | `{workload}-{env}-openai` | S0 |
| Azure AI Search | `{workload}-{env}-search` | Standard, Semantic: Standard |
| ADLS Gen2 | `{workload}{env}sa` | Standard_LRS, HNS enabled |
| Key Vault | `{workload}-{env}-kv` | Standard, RBAC, purge-protected |
| AKS | `{workload}-{env}-aks` | System pool + optional GPU pool |
| Log Analytics | `{workload}-{env}-law` | PerGB2018 |
| Application Insights | `{workload}-{env}-ai` | Workspace-based |
| VNet | `{workload}-{env}-vnet` | /16 with 3 subnets |
| NSG | `{workload}-{env}-nsg` | Default rules |
| Private DNS Zones | 4 zones (OpenAI, Search, Blob, KV) | Global |
| Private Endpoints | 4 (one per AI/data service) | — |

### OpenAI Model Deployments (Example)

| Deployment Name | Model | Version | Capacity (TPM) | SKU |
|----------------|-------|---------|-----------------|-----|
| gpt-4o | gpt-4o | 2024-08-06 | 20K | GlobalStandard |
| text-embedding-3-large | text-embedding-3-large | 1 | 80K | Standard |

### AKS Configuration

| Pool | VM Size | Count | Purpose |
|------|---------|-------|---------|
| system | Standard_D4s_v5 | 3 | System workloads |
| aigpu (optional) | Standard_NC6s_v3 | 0+ | GPU inference (tainted) |

### Storage Containers

| Container | Purpose |
|-----------|---------|
| `data` | Workload-specific datasets |
| `embeddings` | Vector embeddings |
| `models` | Model artifacts |

---

## 🔐 Security & Networking

- **Fully isolated VNet** per workload — no shared hub dependency
- All services behind **Private Endpoints**
- **Private DNS Zones** scoped to the workload VNet
- Key Vault with **RBAC authorization**
- AKS with **Azure RBAC for Kubernetes**
- Calico network policy in AKS
- TLS 1.2 minimum on all storage and endpoints

---

## ✅ Use Cases

- **Data isolation requirements** (PII, PCI-DSS, PHI) — each workload has its own encryption boundary
- **Independent product teams** with full autonomy over their AI stack
- **High throughput workloads** needing dedicated OpenAI quota
- Workloads with different compliance or regulatory requirements

---

## ⚠️ Constraints & Considerations

| Constraint | Mitigation |
|-----------|------------|
| Cost duplication (each spoke pays for full stack) | Use consumption-based SKUs where possible; right-size per workload |
| Harder to standardize across workloads | Use shared Bicep modules with org-wide defaults |
| No shared model registry | Consider adding a lightweight registry spoke or use AML |
| OpenAI quota per subscription limits | Spread workloads across subscriptions if needed |
| Operational overhead (N clusters to manage) | GitOps + centralized monitoring in Log Analytics |

---

## 🚀 Deployment

```bash
# Deploy a single workload spoke
az deployment group create \
  --resource-group rg-claims-ai-dev \
  --template-file main.bicep \
  --parameters main.bicepparam
```

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `location` | string | `canadacentral` | Target Azure region |
| `environmentName` | enum | `dev` | dev / staging / prod |
| `workloadName` | string | *(required)* | Unique name for this workload |
| `vnetAddressPrefix` | string | `10.10.0.0/16` | VNet CIDR block |
| `aksSystemNodeCount` | int | `3` | System node pool size |
| `aksAiNodeCount` | int | `0` | GPU node pool size (0 = skip) |
| `openAiDeployments` | array | GPT-4o | Model deployments |

---

## � Estimated Monthly Cost (USD, Canada Central)

| Environment | Estimate (per spoke) | Key Cost Drivers |
|-------------|---------------------|------------------|
| **Dev** | $6,000 – $9,000 | Duplicated OpenAI + AI Search + AKS per workload |
| **Prod** | $25,000 – $45,000 | AKS GPU nodes ($2,100+/mo), OpenAI dedicated quota, PE charges |

> Cost scales linearly per workload. 5 spokes in prod = $125K–$225K/mo total.

---

## 📊 Azure Service SLAs

| Service | SLA | Conditions |
|---------|-----|------------|
| Azure OpenAI | 99.9% | Standard deployment |
| Azure AI Search | 99.9% | 2+ replicas |
| AKS (Standard) | 99.95% (with AZs) | Requires Standard tier |
| ADLS Gen2 (LRS) | 99.9% | 99.99% with RA-GRS |
| Key Vault | 99.99% | — |

---

## 📏 Key Azure Service Limits

| Service | Limit | Value |
|---------|-------|-------|
| AKS | Max nodes per cluster | 5,000 |
| AKS | Max nodes per node pool | 1,000 |
| AKS | Max pods per node (Azure CNI) | 250 (30 default) |
| Azure OpenAI | Resources per region/sub | 30 |
| Azure OpenAI | gpt-4o GlobalStandard TPM | 300,000 |
| AI Search (S1) | Max indexes | 50 |
| ADLS Gen2 | Max request rate (Canada Central) | 40,000 req/s |

---

## 🏛️ Well-Architected Framework Alignment

| Pillar | Rating | Notes |
|--------|--------|-------|
| **Reliability** | ✅ Excels | Blast radius isolation — one workload failure doesn't affect others |
| **Performance Efficiency** | ✅ Excels | Dedicated resources, no shared quota contention |
| **Cost Optimization** | ⚠️ Attention | Full resource duplication; use consumption SKUs where possible |
| **Operational Excellence** | ⚠️ Attention | Governance sprawl; enforce via shared Bicep modules + policies |
| **Security** | ✅ Good | Full isolation boundary per workload |

---

## 🔬 Best Practices

### AKS GPU Node Pools
- Use taints (`nvidia.com/gpu=present:NoSchedule`) to prevent non-GPU workloads scheduling on expensive nodes
- Set `aksAiNodeCount = 0` in dev; scale up only for prod inference
- Enable cluster autoscaler with min=0 for GPU pools to save cost during idle

### Per-Workload OpenAI Quota
- Each workload gets its own OpenAI resource = dedicated quota
- Max 30 OpenAI resources per region per subscription — plan subscription topology
- For >30 workloads, use multiple subscriptions or shared Pattern 1/3

### Cross-Workload Standardization
- Enforce consistency via shared Bicep modules (this repo)
- Use Azure Policy to audit resource naming, tagging, and SKU compliance
- Centralize monitoring: forward all spoke Log Analytics to a central workspace

---

## �📁 Files

| File | Purpose |
|------|---------|
| `Decentralized-Spoke-AI-Spec.md` | This specification document |
| `main.bicep` | Full workload infrastructure deployment |
| `main.bicepparam` | Default parameters (claims-ai workload) |
