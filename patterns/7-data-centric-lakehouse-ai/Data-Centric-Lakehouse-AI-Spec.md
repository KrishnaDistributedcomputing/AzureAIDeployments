# Pattern 7: Data-Centric AI Pattern (Lakehouse + AI)

## 📌 Pattern Overview

AI tightly integrated with a **single-region data platform**. Combines a lakehouse architecture (ADLS Gen2 + Databricks + Delta Lake) with Azure AI Search as a vector layer and Azure OpenAI for inference. Data flows through medallion zones (raw → curated → serving) with AI applied at the serving layer.

---

## 🏗️ Architecture (Single Region)

| Layer | Component | Azure Service |
|-------|-----------|---------------|
| **Region** | Canada Central | — |
| **Data Engineering** | Spark / ETL / Delta Lake | Azure Databricks (Premium, VNet-injected) |
| **Raw Zone** | Landing & Ingestion | ADLS Gen2 (`raw` account) |
| **Curated Zone** | Silver/Gold Delta Tables | ADLS Gen2 (`curated` account) |
| **Serving Zone** | Embeddings & Vectors | ADLS Gen2 (`serving` account) |
| **Vector Search** | Semantic / Hybrid Search | Azure AI Search (Standard) |
| **LLM Inference** | Chat / Completions | Azure OpenAI (GPT-4o) |
| **App Compute** | RAG Application | App Service (optional) |
| **Secrets** | Connection Strings & Keys | Azure Key Vault |
| **Monitoring** | Telemetry & Audit | Log Analytics + App Insights |

### Data Flow & Architecture

```
┌──────────────────────────────────────────────────────┐
│            Lakehouse + AI VNet (10.40.0.0/16)        │
│                                                      │
│  ┌───────────────────────────────────────┐           │
│  │      Databricks (VNet-injected)       │           │
│  │   Public /22      │   Private /22     │           │
│  └──────────┬────────────────────────────┘           │
│             │ ETL / Feature Engineering               │
│             ▼                                        │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐           │
│  │ Raw ADLS │─▶│ Curated  │─▶│ Serving  │           │
│  │ landing/ │  │ silver/  │  │ embed/   │           │
│  │ raw/     │  │ gold/    │  │ vectors/ │           │
│  │ archive/ │  │ delta/   │  │ models/  │           │
│  └──────────┘  └──────────┘  └────┬─────┘           │
│                                    │                  │
│                    ┌───────────────┼──────┐           │
│                    ▼               ▼      ▼           │
│              ┌──────────┐   ┌──────────┐             │
│              │ AI Search│   │  Azure   │             │
│              │ (vector) │   │  OpenAI  │             │
│              └────┬─────┘   └────┬─────┘             │
│                   │              │                    │
│                   ▼              ▼                    │
│              ┌──────────────────────┐                 │
│              │   App Service (RAG)  │                 │
│              │   VNet-integrated    │                 │
│              └──────────────────────┘                 │
└──────────────────────────────────────────────────────┘
```

### Medallion Architecture

```
  Raw Zone          Curated Zone         Serving Zone
 ┌──────────┐      ┌──────────┐       ┌──────────────┐
 │ landing/ │ ──▶  │ silver/  │ ──▶   │ embeddings/  │
 │ raw/     │      │ gold/    │       │ vector-idx/  │
 │ archive/ │      │ delta-   │       │ model-arts/  │
 │          │      │ tables/  │       │ documents/   │
 └──────────┘      └──────────┘       └──────────────┘
   Ingestion        Transform           AI-Ready
```

---

## 📦 Azure Resources Deployed

| Resource | Name Pattern | SKU / Tier |
|----------|-------------|------------|
| Azure Databricks | `{base}-{env}-dbw` | Premium, VNet-injected |
| Azure OpenAI | `{base}-{env}-openai` | S0 |
| Azure AI Search | `{base}-{env}-search` | Standard, 2 replicas, Semantic |
| ADLS Gen2 (Raw) | `{base}{env}raw` | Standard_LRS, HNS |
| ADLS Gen2 (Curated) | `{base}{env}curated` | Standard_LRS, HNS |
| ADLS Gen2 (Serving) | `{base}{env}serving` | Standard_LRS, HNS |
| App Service (optional) | `{base}-{env}-app` | P1v3, Linux |
| Key Vault | `{base}-{env}-kv` | Standard |
| Log Analytics | `{base}-{env}-law` | PerGB2018, 90-day |
| Application Insights | `{base}-{env}-appinsights` | Workspace-based |
| VNet | `{base}-{env}-vnet` | /16 with 6 subnets |
| Private DNS Zones | 5 zones (OpenAI, Search, Blob, DFS, KV) | Global |
| Private Endpoints | 7 (OpenAI, Search, Raw-Blob, Raw-DFS, Curated-DFS, Serving-Blob, KV) | — |

### OpenAI Model Deployments

| Deployment Name | Model | Version | Capacity (TPM) | SKU |
|----------------|-------|---------|-----------------|-----|
| gpt-4o | gpt-4o | 2024-08-06 | 40K | GlobalStandard |
| text-embedding-3-large | text-embedding-3-large | 1 | 120K | Standard |

### Storage Accounts — Medallion Zones

| Account | Containers | Purpose |
|---------|-----------|---------|
| `{base}{env}raw` | `landing`, `raw`, `archive` | Ingestion & raw data |
| `{base}{env}curated` | `silver`, `gold`, `delta-tables` | Transformed / curated |
| `{base}{env}serving` | `embeddings`, `vector-indexes`, `model-artifacts`, `documents` | AI-ready data |

### AI Search Configuration

| Property | Value |
|----------|-------|
| SKU | Standard |
| Replicas | 2 (HA for search queries) |
| Partitions | 1 |
| Semantic Search | Standard |

### Databricks Configuration

| Property | Value |
|----------|-------|
| Pricing Tier | Premium |
| VNet Injection | Enabled |
| Public Subnet | /22 (delegated) |
| Private Subnet | /22 (delegated) |

---

## 🔐 Security & Networking

- Databricks **VNet-injected** — compute runs in your VNet
- All data stores behind **Private Endpoints** (7 PEs total)
- **5 Private DNS Zones** for internal resolution
- App Service uses **VNet Integration** for outbound calls
- Key Vault with **RBAC authorization** and **purge protection**
- All ADLS accounts: **TLS 1.2**, **HTTPS only**, **HNS enabled**
- AI Search with **2 replicas** for query availability

---

## ✅ Use Cases

- **RAG (Retrieval-Augmented Generation)** — documents flow through lakehouse → embeddings → AI Search → OpenAI
- **Knowledge copilots** — enterprise knowledge bases powered by Delta Lake + vector search
- **Analytics + AI combined workloads** — BI dashboards and AI apps share the same curated data
- **Data-intensive AI** — large-scale document processing, chunking, embedding generation

---

## ⚠️ Constraints & Considerations

| Constraint | Mitigation |
|-----------|------------|
| Three storage accounts increases cost | Consolidate zones if data volume is small |
| Databricks + AI Search data sync | Use Databricks jobs to push data to AI Search indexes |
| Embedding pipeline latency | Pre-compute embeddings in Databricks; incremental updates |
| Delta Lake → AI Search format mismatch | Use Databricks notebooks to export to JSON for indexing |
| Operational complexity (Lakehouse + AI) | Start with Serving zone only; add Raw/Curated as data grows |

---

## 🚀 Deployment

```bash
az deployment group create \
  --resource-group rg-datalake-ai-dev \
  --template-file main.bicep \
  --parameters main.bicepparam
```

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `location` | string | `canadacentral` | Target region |
| `environmentName` | enum | `dev` | dev / staging / prod |
| `baseName` | string | `datalake` | Naming prefix |
| `vnetAddressPrefix` | string | `10.40.0.0/16` | VNet CIDR |
| `databricksTier` | enum | `premium` | standard / premium |
| `deployAppService` | bool | `true` | Deploy App Service for RAG app |
| `openAiDeployments` | array | GPT-4o + Embeddings | Model deployments |

---

## � Estimated Monthly Cost (USD, Canada Central)

| Environment | Estimate | Key Cost Drivers |
|-------------|----------|------------------|
| **Dev** | $6,000 – $10,000 | 3× ADLS accounts, Databricks DBUs, AI Search S1, OpenAI |
| **Moderate Prod** | **~$8,350/mo** | ~500M tokens/mo, Databricks clusters, AI Search S1, 3× ADLS |
| **Prod (scaled)** | $30,000 – $55,000 | Databricks clusters ($3K–$8K/mo), AI Search 2 replicas, App Service, 7 PEs |

### Component Breakdown (Moderate Production, ~500M tokens/mo)

| Service | SKU / Tier | Unit Price (March 2026) |
|---------|-----------|------------------------|
| Azure OpenAI GPT-4o | Global Standard | $2.50/1M input tokens, $10/1M output tokens |
| text-embedding-3-small | Standard | $0.022/1M tokens |
| Azure Databricks | Premium | ~$0.40/DBU |
| Synapse Spark | Memory Optimized | $0.138/vCore-hr |
| ADLS Gen2 (×3 accounts) | Standard | $0.0208/GB/mo (Hot LRS) |
| AI Search | S1 | $245.28/mo |
| App Service | P1v3 | ~$115/mo |
| Key Vault | Standard | $0.03/10K transactions |
| Azure Monitor (Log Analytics) | Per-GB | $2.30/GB ingested |
| Private Endpoints (×7) | Per endpoint | ~$7.30/mo each |

> Prices sourced from [Azure Pricing Pages](https://azure.microsoft.com/pricing/) (March 2026). Data storage is cheap ($0.0208/GB/mo Hot LRS); Databricks compute is the dominant cost.

---

## 📊 Azure Service SLAs

| Service | SLA | Conditions |
|---------|-----|------------|
| Azure Databricks | 99.95% | Premium tier |
| Azure OpenAI | 99.9% | Standard deployment |
| Azure AI Search | 99.9% | 2 replicas deployed |
| App Service | 99.95% | Standard/Premium tier |
| ADLS Gen2 (LRS) | 99.9% | Per account; 3 accounts = independent failure domains |
| Key Vault | 99.99% | — |

---

## 📏 Key Azure Service Limits

| Service | Limit | Value |
|---------|-------|-------|
| ADLS Gen2 | Max account capacity | 5 PiB per account |
| ADLS Gen2 | Max ingress (Canada Central) | 60 Gbps |
| ADLS Gen2 | Max storage accounts per region/sub | 250 |
| AI Search | Blob indexer max doc size | 128 MB (S1), 256 MB (S2+) |
| AI Search | Indexer schedule min interval | 5 minutes |
| AI Search | Max indexer run time (private) | 24 hours |
| Databricks | Concurrent running tasks | 2,000 |
| Databricks | Tables per pipeline | 1,000 |

---

## 🏛️ Well-Architected Framework Alignment

| Pillar | Rating | Notes |
|--------|--------|-------|
| **Performance Efficiency** | ✅ Excels | Medallion architecture optimizes data for each processing stage |
| **Reliability** | ✅ Excels | 3 independent storage accounts = data redundancy |
| **Cost Optimization** | ⚠️ Attention | 3× ADLS + Databricks; consolidate zones if data volume is small |
| **Security** | ⚠️ Attention | Broad data lake access; enforce ACLs per medallion zone |
| **Operational Excellence** | ✅ Good | Clear data lineage through medallion layers |

---

## 🔬 Best Practices

### Medallion Architecture Data Flow
```
Raw (landing/raw/archive) → Curated (silver/gold/delta) → Serving (embeddings/vectors)
                Databricks ETL                    Databricks + AI Search Indexer
```
- **Raw zone**: Append-only, immutable. Store original documents.
- **Curated zone**: Delta Lake format. Schema-enforced, deduped, business-ready.
- **Serving zone**: Chunked documents, embeddings, vector indexes. AI-ready.

### AI Search Indexer Patterns
- **Blob indexer**: Supports PDF, DOCX, JSON, CSV, plain text (max 128 MB on S1)
- **ADLS Gen2 indexer**: Connect via managed identity + shared private link
- **Custom skillset**: Call Azure Function for chunking, OCR, entity extraction
- **Integrated vectorization**: Use OpenAI embedding skill for automated chunk-and-embed
- Enable **incremental enrichment** cache to avoid reprocessing unchanged documents

### Databricks → AI Search Data Sync
- Use Databricks notebooks to export Delta Lake tables to JSON for AI Search indexing
- Schedule Databricks jobs to push updated embeddings to the Serving zone ADLS
- AI Search indexer picks up new/modified blobs on a 5-minute schedule
- Use change tracking (blob metadata) for efficient incremental indexing

### Cost Optimization
- Start with Serving zone only; add Raw/Curated as data volume grows
- Use ADLS lifecycle management: move archive data to Cool/Archive tier after 90 days
- Databricks: auto-terminate clusters after 15 min idle; use spot instances for ETL
- AI Search: start with 1 replica in dev; scale to 2+ for production HA

---

## �📁 Files

| File | Purpose |
|------|---------|
| `Data-Centric-Lakehouse-AI-Spec.md` | This specification document |
| `main.bicep` | Full Lakehouse + AI infrastructure |
| `main.bicepparam` | Default parameters for dev |
