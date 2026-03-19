# Pattern 6: Secure AI Pattern (Private AI / Zero Trust)

## 📌 Pattern Overview

AI deployed in a **fully private, single-region network boundary**. All services accessed exclusively via Private Endpoints, no public internet exposure. Azure Firewall controls egress, NSGs enforce micro-segmentation, and centralized logging provides full audit trails. Aligns with **Zero Trust** principles.

---

## 🏗️ Architecture (Single Region)

| Layer | Component | Azure Service |
|-------|-----------|---------------|
| **Region** | Canada Central | — |
| **Network Perimeter** | Firewall & Egress Control | Azure Firewall (Premium) |
| | Route Table | UDR → Firewall |
| | Micro-segmentation | NSGs (per subnet) |
| **AI Services** (all private) | LLM / Completions | Azure OpenAI (Disabled public) |
| | Vector Search | Azure AI Search (Disabled public) |
| | ML Workspace | Azure Machine Learning (Disabled public) |
| **Data** (all private) | Data Lake | ADLS Gen2 (Disabled public) |
| | Secrets | Key Vault (Disabled public) |
| **Compute** (VNet-injected) | Container Compute | AKS (Private Cluster) |
| **Observability** | Centralized Logging | Log Analytics (365-day retention) |
| | Diagnostics | App Insights + Diagnostic Settings |
| **DNS** | Private Resolution | 6 Private DNS Zones |

### Network Topology

```
┌───────────────────────────────────────────────────────┐
│               Secure VNet (10.30.0.0/16)              │
│                                                       │
│  ┌─────────────────┐                                  │
│  │ AzureFirewall   │ ◄── All egress routed here      │
│  │ Subnet /26      │     (UDR 0.0.0.0/0)             │
│  └────────┬────────┘                                  │
│           │                                           │
│  ┌────────┴────────┐  ┌─────────────┐                 │
│  │  AKS (Private)  │  │  Private    │                 │
│  │  Nodes /20      │  │  Endpoints  │                 │
│  │  NSG: deny inet │  │  /24        │                 │
│  └─────────────────┘  │  NSG: VNet  │                 │
│                       │  only       │                 │
│                       └─────────────┘                 │
│  ┌─────────────┐  ┌──────────┐                        │
│  │  Data PEs   │  │ Mgmt     │                        │
│  │  /24        │  │ /24      │                        │
│  └─────────────┘  └──────────┘                        │
│                                                       │
│  Private DNS Zones: openai, search, blob, dfs, kv, aml│
└───────────────────────────────────────────────────────┘

   ALL SERVICES: publicNetworkAccess = Disabled
```

---

## 📦 Azure Resources Deployed

| Resource | Name Pattern | SKU / Tier | Public Access |
|----------|-------------|------------|---------------|
| Azure Firewall | `{base}-{env}-fw` | Premium | N/A (perimeter) |
| Azure OpenAI | `{base}-{env}-openai` | S0 | **Disabled** |
| Azure AI Search | `{base}-{env}-search` | Standard | **Disabled** |
| Azure Machine Learning | `{base}-{env}-aml` | — | **Disabled** |
| ADLS Gen2 | `{base}{env}adls` | Standard_LRS, HNS | **Disabled** |
| Key Vault | `{base}-{env}-kv` | Standard | **Disabled** |
| AKS | `{base}-{env}-aks` | D4s_v5 × 3 | **Private Cluster** |
| Log Analytics | `{base}-{env}-law` | PerGB2018, **365-day** | — |
| Application Insights | `{base}-{env}-ai` | Workspace-based | — |
| Route Table | `{base}-{env}-rt` | UDR → Firewall | — |
| NSG (AI subnets) | `{base}-{env}-ai-nsg` | Deny Internet In+Out | — |
| NSG (AKS subnet) | `{base}-{env}-aks-nsg` | Deny Internet In | — |
| Private DNS Zones | 6 zones | Global | — |
| Private Endpoints | 7 (OpenAI, Search, Blob, DFS, KV, AML) | — | — |
| Diagnostic Settings | OpenAI → Log Analytics | allLogs + AllMetrics | — |

### NSG Rules — AI Subnets

| Rule | Priority | Direction | Action | Source | Destination |
|------|----------|-----------|--------|--------|-------------|
| AllowVNetInbound | 100 | Inbound | Allow | VirtualNetwork | VirtualNetwork |
| DenyInternetInbound | 4000 | Inbound | Deny | Internet | * |
| DenyAllOutboundInternet | 4000 | Outbound | Deny | * | Internet |

### NSG Rules — AKS Subnet

| Rule | Priority | Direction | Action | Source | Destination |
|------|----------|-----------|--------|--------|-------------|
| AllowVNetInbound | 100 | Inbound | Allow | VirtualNetwork | VirtualNetwork |
| AllowAzureLB | 200 | Inbound | Allow | AzureLoadBalancer | * |
| DenyInternetInbound | 4000 | Inbound | Deny | Internet | * |

### Firewall Configuration

| Property | Value |
|----------|-------|
| SKU | Premium (AZFW_VNet) |
| Threat Intel Mode | Deny |
| DNS Proxy | Enabled |
| Policy | `{base}-{env}-fw-policy` |

### Storage Containers

| Container | Purpose |
|-----------|---------|
| `data` | Application datasets |
| `embeddings` | Vector embeddings |
| `models` | Model artifacts |
| `audit-logs` | Compliance audit data |

---

## 🔐 Security & Networking

- **Zero public endpoints** — every service has `publicNetworkAccess: Disabled`
- **Azure Firewall (Premium)** — all egress controlled, TLS inspection capable, threat intel deny
- **UDR route table** forces `0.0.0.0/0` → Firewall private IP
- **Private Cluster AKS** — API server not exposed publicly
- **NSGs per subnet** — deny internet inbound/outbound on AI subnets
- **7 Private Endpoints** covering all AI, data, and security services
- **6 Private DNS Zones** for internal name resolution
- Key Vault: **RBAC authorization**, **purge protection enabled**
- Storage: **TLS 1.2**, **HTTPS only**, **HNS enabled**, default deny network ACL
- **365-day log retention** for compliance auditing
- **Diagnostic Settings** on Azure OpenAI → Log Analytics (all logs + metrics)

---

## ✅ Use Cases

- **Canadian data residency requirements** — all data stays in Canada Central
- **Financial services workloads** — meets banking regulatory controls
- **Healthcare workloads** — PHI isolation, audit logging, no public exposure
- **CSI regulated customers** — Defender for Cloud, centralized logging, Zero Trust

---

## ⚠️ Constraints & Considerations

| Constraint | Mitigation |
|-----------|------------|
| Higher cost (Firewall Premium, Private Endpoints) | Budget for ~$1.5K/mo firewall + PE per-hour charges |
| Operational complexity | Requires network team for firewall rule management |
| No public access for developers | Use Azure Bastion or VPN for management access |
| AKS private cluster requires jump box | Deploy Bastion + management VM in management subnet |
| Firewall rule maintenance | Use Firewall Policy with rule collection groups |
| Deployment requires connectivity | CI/CD agents must be in-VNet (self-hosted) |

---

## 🚀 Deployment

```bash
az deployment group create \
  --resource-group rg-secure-ai-prod \
  --template-file main.bicep \
  --parameters main.bicepparam
```

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `location` | string | `canadacentral` | Target region |
| `environmentName` | enum | `dev` | dev / staging / prod |
| `baseName` | string | `secureai` | Naming prefix |
| `vnetAddressPrefix` | string | `10.30.0.0/16` | VNet CIDR |
| `aksSystemNodeCount` | int | `3` | AKS system pool nodes |
| `firewallSkuTier` | enum | `Premium` | Standard / Premium |
| `openAiDeployments` | array | GPT-4o + Embeddings | Standard SKU (regional) |

---

## � Estimated Monthly Cost (USD, Canada Central)

| Environment | Estimate | Key Cost Drivers |
|-------------|----------|------------------|
| **Dev** | $8,000 – $12,000 | Azure Firewall Standard/Premium, Private AKS, 7+ PEs |
| **Moderate Prod** | **~$10,240/mo** | ~500M tokens/mo, Firewall Standard, AI Search S2, private AKS |
| **Prod (scaled)** | $35,000 – $65,000 | Firewall Premium data processing, AKS scaling, 365-day log retention, Bastion |

### Component Breakdown (Moderate Production, ~500M tokens/mo)

| Service | SKU / Tier | Unit Price (March 2026) |
|---------|-----------|------------------------|
| Azure OpenAI GPT-4o | Global Standard | $2.50/1M input tokens, $10/1M output tokens |
| text-embedding-3-small | Standard | $0.022/1M tokens |
| Azure Firewall | Standard | $912/mo ($1.25/hr) |
| Azure Firewall | Premium | $1,278/mo ($1.75/hr) |
| AI Search | S2 | $981.12/mo |
| AKS (3× D4s v3 nodes) | Standard | ~$420/mo |
| Key Vault | Standard | $0.03/10K transactions |
| Azure Monitor (Log Analytics) | Per-GB | $2.30/GB; Basic Logs $0.50/GB |
| Private Endpoints (×7+) | Per endpoint | ~$7.30/mo each |

> Prices sourced from [Azure Pricing Pages](https://azure.microsoft.com/pricing/) (March 2026). This is the most expensive pattern due to Firewall + full private networking.

---

## 📊 Azure Service SLAs

| Service | SLA | Conditions |
|---------|-----|------------|
| Azure Firewall | 99.95% (single AZ) / 99.99% (multi-AZ) | Multi-AZ for highest SLA |
| Azure OpenAI | 99.9% | Standard deployment |
| AKS (Standard, Private) | 99.95% (with AZs) | Standard tier + AZ deployment |
| Azure AI Search | 99.9% | 2+ replicas |
| ADLS Gen2 (LRS) | 99.9% | Consider ZRS for higher durability |
| Key Vault | 99.99% | — |
| Azure Machine Learning | 99.9% | Online endpoints |
| Azure Bastion | 99.95% | If deployed for jump box access |

---

## 📏 Key Azure Service Limits

| Service | Limit | Value |
|---------|-------|-------|
| Azure Firewall (Premium) | Max throughput | 100 Gbps |
| Azure Firewall | SNAT ports per public IP | 2,048 |
| Azure Firewall | Max DNAT rules | 250 |
| Azure Firewall (Premium) | TLS inspection | Yes (67,000+ IDPS rules) |
| Private Endpoints | Cost per PE | ~$7.30/mo + $0.01/GB |
| AKS Private | API server | Not publicly accessible |

---

## 🏛️ Well-Architected Framework Alignment

| Pillar | Rating | Notes |
|--------|--------|-------|
| **Security** | ✅ Excels | Zero Trust — all private, firewall-controlled, IDPS, TLS inspection |
| **Reliability** | ✅ Excels | Multi-AZ firewall (99.99%), private AKS, no internet dependency |
| **Cost Optimization** | ⚠️ Attention | Firewall + PE charges significant; budget $1,750+/mo for firewall alone |
| **Operational Excellence** | ⚠️ Attention | Complex DNS/routing, firewall rule management, private AKS access |
| **Performance Efficiency** | ✅ Good | All traffic stays on Azure backbone; no public internet hops |

---

## 🔬 Best Practices

### AKS Private Cluster Access
- Deploy **Azure Bastion** (Standard SKU) in Hub VNet for SSH/RDP to jump box
- Use **jump box VM** (Linux D2s_v5) in same VNet for `kubectl` access
- Enable **Run Command** (`az aks command invoke`) for emergency access
- For CI/CD: **self-hosted agents** in the same VNet (Azure DevOps or GitHub ARC)
- Private DNS zone `privatelink.canadacentral.azmk8s.io` must be resolvable

### Azure Firewall Rule Management
- Use **Firewall Policy** with rule collection groups for organized rule management
- Enable **TLS inspection** (Premium only) for encrypted traffic visibility
- Enable **IDPS** in Alert+Deny mode for threat detection
- Use **threat intelligence** feed in Deny mode
- Log all traffic to Log Analytics with 365-day retention for compliance

### DNS Architecture for Zero Trust
```
Client (in VNet) → Azure Private DNS Zone → PE IP
  ↓ (if not resolved)
Azure Firewall DNS Proxy → Upstream DNS
```
- Enable DNS Proxy on Azure Firewall for centralized resolution
- Link all private DNS zones to the Hub/Secure VNet
- UDR forces all traffic through firewall, including DNS

### Data Residency Compliance
- All resources in Canada Central — meets Canadian data residency requirements
- ADLS network ACL: `defaultAction: Deny`, `bypass: AzureServices`
- Key Vault purge protection: data cannot be permanently deleted for 90 days
- 365-day log retention for regulatory audit trails

---

## �📁 Files

| File | Purpose |
|------|---------|
| `Secure-Private-AI-Spec.md` | This specification document |
| `main.bicep` | Full Zero Trust AI infrastructure |
| `main.bicepparam` | Default parameters (prod environment) |
