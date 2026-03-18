# Pattern 5: Serverless AI Pattern (Lightweight / PoC)

## 📌 Pattern Overview

**Minimal infrastructure** using fully managed, serverless services within a single region. Designed for rapid prototyping, internal copilots, and low-operational-overhead applications. No VNets or private endpoints by default — pure PaaS simplicity.

---

## 🏗️ Architecture (Single Region)

| Layer | Component | Azure Service |
|-------|-----------|---------------|
| **Region** | Canada Central | — |
| **LLM** | Chat / Completions | Azure OpenAI (GPT-4o-mini) |
| **Embeddings** | Vector generation | Azure OpenAI (text-embedding-3-small) |
| **Search** | Vector / keyword search | Azure AI Search (Basic) |
| **Compute** | Event-driven processing | Azure Functions (Consumption plan) |
| **Storage** | Documents & embeddings | Azure Blob Storage (Standard) |
| **Gateway** (optional) | API facade | Azure API Management (Consumption) |
| **Monitoring** | Telemetry & logs | Log Analytics + App Insights |

### Architecture Diagram

```
┌─────────────────────────────────────────────────┐
│                 Serverless AI Stack              │
│                                                 │
│   ┌──────────┐     ┌──────────────┐             │
│   │  Client   │────▶│ Azure        │             │
│   │  Apps     │     │ Functions    │             │
│   └──────────┘     └──────┬───────┘             │
│                           │                      │
│              ┌────────────┼────────────┐         │
│              ▼            ▼            ▼         │
│        ┌──────────┐ ┌──────────┐ ┌─────────┐   │
│        │  Azure   │ │  Azure   │ │  Blob   │   │
│        │  OpenAI  │ │ AI Search│ │ Storage │   │
│        └──────────┘ └──────────┘ └─────────┘   │
│                                                 │
│   ┌──────────────────┐  (optional)              │
│   │ API Management   │                          │
│   │ (Consumption)    │                          │
│   └──────────────────┘                          │
└─────────────────────────────────────────────────┘
```

---

## 📦 Azure Resources Deployed

| Resource | Name Pattern | SKU / Tier |
|----------|-------------|------------|
| Azure OpenAI | `{base}-{env}-openai` | S0 |
| Azure AI Search | `{base}-{env}-search` | Basic, Semantic: Free |
| Azure Functions | `{base}-{env}-func` | Consumption (Y1) |
| Functions Storage | `{base}{env}funcsa` | Standard_LRS |
| Blob Storage | `{base}{env}sa` | Standard_LRS (no HNS) |
| Log Analytics | `{base}-{env}-law` | PerGB2018, 30-day retention |
| Application Insights | `{base}-{env}-ai` | Workspace-based |
| API Management (optional) | `{base}-{env}-apim` | Consumption |

### OpenAI Model Deployments

| Deployment Name | Model | Version | Capacity (TPM) | SKU |
|----------------|-------|---------|-----------------|-----|
| gpt-4o-mini | gpt-4o-mini | 2024-07-18 | 20K | GlobalStandard |
| text-embedding-3-small | text-embedding-3-small | 1 | 60K | Standard |

### Function App Configuration

| Property | Value |
|----------|-------|
| Runtime | Python 3.11 (configurable: Node, .NET) |
| Plan | Consumption (Y1) — pay per execution |
| Extensions | v4 |
| HTTPS Only | Yes |
| FTPS State | Disabled |

### Storage Containers

| Container | Purpose |
|-----------|---------|
| `documents` | Source documents for RAG |
| `embeddings` | Pre-computed embeddings |

---

## 🔐 Security & Networking

- **No VNet / Private Endpoints** — services use public endpoints with service-level auth
- Functions use **System-Assigned Managed Identity**
- Storage enforces **TLS 1.2** and **HTTPS-only**
- FTPS **disabled** on Functions
- OpenAI endpoint + Search name injected via **App Settings**
- Optional APIM provides **API key management** and **rate limiting**

> ⚠️ For production or regulated workloads, consider Pattern 6 (Secure AI) instead.

---

## ✅ Use Cases

- **Internal copilots** — Slack/Teams bots, internal knowledge assistants
- **MVPs / rapid prototyping** — validate AI concepts before investing in full infrastructure
- **Low operational overhead apps** — no clusters, no VNets, no private endpoints
- **Hackathons / innovation sprints** — deploy a full AI stack in minutes

---

## ⚠️ Constraints & Considerations

| Constraint | Mitigation |
|-----------|------------|
| Limited control over scaling and networking | Acceptable for PoC; upgrade to Pattern 1/6 for production |
| Not ideal for strict enterprise environments | No private endpoints; public-facing services |
| Cold start latency on Consumption plan | Use Premium plan for latency-sensitive workloads |
| Basic AI Search has limited capacity | Upgrade to Standard for production scale |
| No VNet isolation | Add private endpoints if moving to production |

---

## 🚀 Deployment

```bash
az deployment group create \
  --resource-group rg-serverless-ai-dev \
  --template-file main.bicep \
  --parameters main.bicepparam
```

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `location` | string | `canadacentral` | Target region |
| `environmentName` | enum | `dev` | dev / staging / prod |
| `baseName` | string | `serverlessai` | Naming prefix |
| `deployApim` | bool | `false` | Deploy API Management gateway |
| `apimPublisherEmail` | string | `admin@contoso.com` | Required if `deployApim` = true |
| `apimPublisherName` | string | `AI Platform Team` | APIM publisher org name |
| `functionRuntime` | enum | `python` | python / node / dotnet-isolated |
| `openAiDeployments` | array | GPT-4o-mini + Emb-3-small | Model deployments |

---

## � Estimated Monthly Cost (USD, Canada Central)

| Environment | Estimate | Key Cost Drivers |
|-------------|----------|------------------|
| **Dev** | $500 – $1,500 | OpenAI token usage, Functions consumption, AI Search Basic ($75/mo) |
| **Prod** | $5,000 – $12,000 | OpenAI volume, APIM Consumption pay-per-call, Functions Premium (if upgraded) |

> Lowest-cost pattern. Functions Consumption plan: first 1M executions free, then $0.20/1M.

---

## 📊 Azure Service SLAs

| Service | SLA | Conditions |
|---------|-----|------------|
| Azure OpenAI | 99.9% | Standard deployment |
| Azure Functions | 99.95% | Dedicated/Premium plan (no SLA on Consumption) |
| Azure AI Search (Basic) | 99.9% | Single replica |
| Azure Storage | 99.9% | LRS |
| APIM (Consumption) | 99.95% | Per-request billing |
| Application Insights | 99.9% | — |

> ⚠️ Functions Consumption plan has **no SLA**. Upgrade to Premium for production guarantees.

---

## 📏 Key Azure Service Limits

| Service | Limit | Value |
|---------|-------|-------|
| Azure OpenAI | gpt-4o-mini GlobalStandard TPM | 2,000,000 |
| AI Search (Basic) | Max indexes | 5 (15 with higher density) |
| AI Search (Basic) | Partition storage | 160 GB |
| Functions (Consumption) | Max execution time | 10 minutes |
| Functions (Consumption) | Max concurrent executions | 200 |
| APIM (Consumption) | Max requests per subscription | 10,000/min |

---

## 🏛️ Well-Architected Framework Alignment

| Pillar | Rating | Notes |
|--------|--------|-------|
| **Cost Optimization** | ✅ Excels | Pay-per-execution, no idle infrastructure |
| **Performance Efficiency** | ✅ Good | Auto-scale; but cold start latency (1–3s) |
| **Security** | ⚠️ Attention | No VNet — public endpoints with service-level auth |
| **Reliability** | ⚠️ Attention | Consumption plan cold starts; no SLA guarantee |
| **Operational Excellence** | ✅ Good | Minimal ops overhead; fully managed |

---

## 🔬 Best Practices

### Function App Cold Start Mitigation
- Use **Premium plan** (EP1) for latency-sensitive production workloads
- Keep functions warm with **always-ready instances** (Premium plan feature)
- Python runtime: minimize package size, use lazy imports

### AI Search Basic Tier Limits
- Max 5 indexes (15 with higher density option) — plan index strategy carefully
- Single replica = no HA. Acceptable for PoC, not production
- Upgrade to Standard (S1) for production: 50 indexes, 512 GB, up to 12 replicas

### OpenAI in Serverless Context
- Functions timeout = 10 min on Consumption; set `max_tokens` to limit response time
- Use **streaming** (`stream=True`) for chat completions to improve perceived latency
- Implement retry with exponential backoff in the Function code
- Store OpenAI API key in App Settings (injected at runtime), not in code

### Graduation Path
- Start with Pattern 5 for PoC
- Graduate to Pattern 1 (Hub) or Pattern 3 (Hybrid) for enterprise production
- Graduate to Pattern 6 (Secure) if compliance requirements emerge

---

## �📁 Files

| File | Purpose |
|------|---------|
| `Serverless-AI-Spec.md` | This specification document |
| `main.bicep` | Full serverless AI stack |
| `main.bicepparam` | Default parameters for dev |
