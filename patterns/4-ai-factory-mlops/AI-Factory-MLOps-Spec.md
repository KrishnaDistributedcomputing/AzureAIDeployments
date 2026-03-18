# Pattern 4: AI Factory Pattern (MLOps Landing Zone)

## 📌 Pattern Overview

A **dedicated AI Factory Landing Zone** for the full ML lifecycle in a single region. Covers data engineering, feature engineering, model training, registry, deployment pipelines, and monitoring — all within a purpose-built subscription under the Platform.

---

## 🏗️ Architecture (Single Region)

| Layer | Component | Azure Service |
|-------|-----------|---------------|
| **Region** | Canada Central | — |
| **ML Workspace** | Pipelines, Experiments, Registry | Azure Machine Learning |
| **Training** | Spark / Distributed Training | Azure Databricks (Premium, VNet-injected) |
| **Feature Store** | Feature Engineering & Storage | ADLS Gen2 |
| **Model Storage** | Registered Models & Packages | ADLS Gen2 (separate account) |
| **Container Registry** | ML Model Images | Azure Container Registry (Premium) |
| **Inference** | LLM Endpoints | Azure OpenAI |
| **Secrets** | Keys & Connection Strings | Azure Key Vault |
| **Monitoring** | Experiment & Pipeline Tracking | Log Analytics + App Insights |
| **CI/CD** | Pipeline Automation | GitHub Actions / Azure DevOps |

### Network Topology

```
┌──────────────────────────────────────────────────┐
│            AI Factory VNet (10.20.0.0/16)        │
│                                                  │
│  ┌──────────────────────────────────────┐        │
│  │        Databricks (VNet-injected)    │        │
│  │  Public Subnet /22  │ Private /22    │        │
│  └──────────────────────────────────────┘        │
│                                                  │
│  ┌─────────────┐  ┌─────────────┐                │
│  │  ML Compute  │  │   Private   │                │
│  │    /22       │  │  Endpoints  │                │
│  │              │  │    /24      │                │
│  └─────────────┘  └─────────────┘                │
│                                                  │
│  ┌─────────────┐                                 │
│  │    Data      │                                 │
│  │  Endpoints   │                                 │
│  │    /24       │                                 │
│  └─────────────┘                                 │
└──────────────────────────────────────────────────┘
```

---

## 📦 Azure Resources Deployed

| Resource | Name Pattern | SKU / Tier |
|----------|-------------|------------|
| Azure Machine Learning | `{base}-{env}-aml` | Workspace with ACR |
| Azure Databricks | `{base}-{env}-dbw` | Premium, VNet-injected |
| Azure OpenAI | `{base}-{env}-openai` | S0 |
| ADLS Gen2 (Features) | `{base}{env}features` | Standard_LRS, HNS |
| ADLS Gen2 (Models) | `{base}{env}models` | Standard_LRS, HNS |
| Container Registry | `{base}{env}acr` | Premium, 30-day retention |
| Key Vault | `{base}-{env}-kv` | Standard |
| Log Analytics | `{base}-{env}-law` | PerGB2018, 120-day retention |
| Application Insights | `{base}-{env}-ai` | Workspace-based |
| VNet | `{base}-{env}-vnet` | /16 with 5 subnets |
| Private DNS Zones | 6 zones (OpenAI, Blob, DFS, KV, AML, ACR) | Global |
| Private Endpoints | 4 (OpenAI, Features Blob, KV, ACR) | — |

### Feature Store Containers

| Container | Purpose |
|-----------|---------|
| `feature-store` | Computed features for training |
| `training-data` | Raw training datasets |
| `model-artifacts` | Training outputs |
| `experiment-outputs` | Experiment logs and metrics |

### Model Storage Containers

| Container | Purpose |
|-----------|---------|
| `registered-models` | Versioned model binaries |
| `model-packages` | Packaged model containers |
| `serving-artifacts` | Deployment-ready artifacts |

### Databricks Configuration

| Property | Value |
|----------|-------|
| Pricing Tier | Premium |
| VNet Injection | Enabled |
| Public Subnet | /22 (delegated) |
| Private Subnet | /22 (delegated) |

---

## 🔐 Security & Networking

- Databricks **VNet-injected** — no public Databricks infrastructure
- All data services behind **Private Endpoints**
- Container Registry with **admin user disabled** (managed identity only)
- Key Vault with **RBAC authorization** and **purge protection**
- AML workspace linked to ACR, ADLS, KV, and App Insights
- 120-day log retention for audit compliance
- 6 Private DNS Zones for full private name resolution

---

## ✅ Use Cases

- **Large-scale ML pipelines** — Databricks for distributed training, AML for orchestration
- **Continuous retraining** — automated pipelines triggered by data drift
- **Enterprise AI product teams** — full MLOps lifecycle in one landing zone
- **Feature engineering at scale** — Spark-based feature computation on Databricks

---

## ⚠️ Constraints & Considerations

| Constraint | Mitigation |
|-----------|------------|
| Operational complexity | Requires dedicated MLOps / DataOps team |
| Requires DataOps + MLOps maturity | Start with AML pipelines; adopt Databricks incrementally |
| Databricks + AML overlap | Use Databricks for training, AML for registry + deployment |
| Cost of Premium Databricks | Use autoscaling clusters; terminate idle clusters |
| Container Registry image sprawl | 30-day retention policy; automate cleanup |

---

## 🚀 Deployment

```bash
az deployment group create \
  --resource-group rg-ai-factory-dev \
  --template-file main.bicep \
  --parameters main.bicepparam
```

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `location` | string | `canadacentral` | Target region |
| `environmentName` | enum | `dev` | dev / staging / prod |
| `baseName` | string | `aifactory` | Naming prefix |
| `vnetAddressPrefix` | string | `10.20.0.0/16` | VNet CIDR |
| `databricksTier` | enum | `premium` | standard / premium |
| `containerRegistrySku` | enum | `Premium` | Basic / Standard / Premium |
| `openAiDeployments` | array | GPT-4o | Model deployments |

---

## � Estimated Monthly Cost (USD, Canada Central)

| Environment | Estimate | Key Cost Drivers |
|-------------|----------|------------------|
| **Dev** | $5,000 – $8,000 | Databricks DBUs ($0.40/DBU), AML compute, ACR Premium |
| **Prod** | $25,000 – $50,000 | Databricks clusters ($3K–$8K/mo), 2× ADLS accounts, ACR geo-replication |

> Databricks is the dominant cost. Use autoscaling clusters + auto-terminate idle (15 min).

---

## 📊 Azure Service SLAs

| Service | SLA | Conditions |
|---------|-----|------------|
| Azure Databricks | 99.95% | Premium tier |
| Azure Machine Learning | 99.9% | Online endpoints |
| Azure OpenAI | 99.9% | Standard deployment |
| ADLS Gen2 (LRS) | 99.9% | 99.99% with RA-GRS |
| Container Registry (Premium) | 99.95% | Geo-replicated for higher availability |
| Key Vault | 99.99% | — |

---

## 📏 Key Azure Service Limits

| Service | Limit | Value |
|---------|-------|-------|
| Databricks | Concurrent running tasks/workspace | 2,000 |
| Databricks | Saved jobs per workspace | 10,000 |
| Databricks | Concurrent pipeline updates | 200 |
| Databricks | Tables per pipeline | 1,000 |
| ACR (Premium) | Webhooks | 500 |
| AML | Max compute clusters per workspace | 200 |
| AML | Max nodes per compute cluster | 100 (default) |

---

## 🏛️ Well-Architected Framework Alignment

| Pillar | Rating | Notes |
|--------|--------|-------|
| **Operational Excellence** | ✅ Excels | CI/CD, reproducibility, MLflow tracking |
| **Performance Efficiency** | ✅ Excels | Optimized Spark-based ML pipelines |
| **Security** | ⚠️ Attention | Broad data access across training data; enforce column-level security |
| **Cost Optimization** | ⚠️ Attention | Databricks DBU costs; use auto-terminate + spot instances |
| **Reliability** | ✅ Good | VNet-injected compute, private endpoints |

---

## 🔬 Best Practices

### Databricks VNet Injection — NSG Requirements
- Two dedicated subnets required: **public** (control plane) and **private** (worker nodes)
- Both subnets: minimum `/26` (64 IPs), recommended `/24` for production
- **Required NSG inbound**: Allow Databricks control plane IPs on ports 22, 5557
- **Required NSG outbound**: Allow HTTPS (443) to Databricks webapp, SQL, Storage, Event Hub
- Delegate both subnets to `Microsoft.Databricks/workspaces`
- If using Azure Firewall: add UDR routes for control plane, DBFS storage, metastore

### MLOps Pipeline Best Practices
- Use AML pipelines for orchestration, Databricks for compute
- Version all training data in ADLS with folder-based partitioning (`/year/month/day/`)
- Store model artifacts in ACR as container images for consistent serving
- Enable AML workspace diagnostics → Log Analytics for pipeline monitoring
- ACR: disable admin user, use managed identity for pulls

### Cost Control
- Auto-terminate Databricks clusters after 15 minutes idle
- Use **spot instances** for training jobs (up to 90% savings)
- ACR retention policy: 30 days for untagged manifests
- Schedule AML compute to scale down to 0 nodes during off-hours

---

## �📁 Files

| File | Purpose |
|------|---------|
| `AI-Factory-MLOps-Spec.md` | This specification document |
| `main.bicep` | Full AI Factory infrastructure |
| `main.bicepparam` | Default parameters for dev |
