# Specification Ruleset — Universal Standards

**Document ID:** SPEC-RULES-001  
**Version:** 1.0  
**Status:** Active  
**Applies to:** All specification documents produced by this team  
**Date:** 2026-03-19

> This ruleset is the single source of truth for how specs are written, structured, reviewed, and maintained. Every spec document — functional, deployment, architecture, data, or product — must comply before it is considered ready for engineering handoff.

---

## Contents

1. [Document Standards](#1--document-standards)
2. [Structure Rules](#2--structure-rules)
3. [Content Rules](#3--content-rules)
4. [Technical Specification Rules](#4--technical-specification-rules)
5. [Data & Schema Rules](#5--data--schema-rules)
6. [Security Rules](#6--security-rules)
7. [Cost & Estimation Rules](#7--cost--estimation-rules)
8. [Network & Infrastructure Rules](#8--network--infrastructure-rules)
9. [CI/CD & Deployment Rules](#9--cicd--deployment-rules)
10. [Review & Approval Rules](#10--review--approval-rules)
11. [Maintenance Rules](#11--maintenance-rules)
12. [Compliance Checklist](#12--compliance-checklist)

---

## 1.  Document Standards

### 1.1 Required Header

Every spec document must begin with the following header block. No field may be left blank.

```markdown
**Document ID:**   <PREFIX>-<DOMAIN>-<NNN>
**Version:**       <MAJOR.MINOR>
**Status:**        Draft | Review | Approved | Deprecated
**Type:**          Functional | Deployment | Architecture | Data | Product
**Owner:**         <name or team>
**Date:**          <YYYY-MM-DD>
**Applies to:**    <system, service, or feature name>
```

### 1.2 Document ID Format

| Prefix | Use |
|--------|-----|
| `SPEC` | General / product specifications |
| `FS` | Functional specifications |
| `DS` | Deployment specifications |
| `AS` | Architecture specifications |
| `SEC` | Security specifications |

Full format: `<PREFIX>-<DOMAIN>-<NNN>` — e.g. `FS-AVM-001`, `DS-ISB-003`, `SPEC-RULES-001`

Addenda to existing specs use: `<PARENT-ID>-ADD-<NNN>` — e.g. `FS-AVM-001-ADD-002`

### 1.3 Version Numbering

| Change Type | Version Bump | Example |
|------------|-------------|---------|
| Structural section added or removed | Major (`x.0`) | `1.0 → 2.0` |
| Content updated, rule changed | Minor (`x.y`) | `1.0 → 1.1` |
| Typo, formatting fix | Patch — no version bump, update date only | — |

### 1.4 Status Definitions

| Status | Meaning | Who can set |
|--------|---------|------------|
| `Draft` | Being written — not ready for engineering | Author |
| `Review` | Complete — pending stakeholder sign-off | Author |
| `Approved` | Signed off — safe to build against | Owner + reviewer |
| `Deprecated` | Superseded — do not build against | Owner |

A spec cannot move to `Approved` without at least one reviewer who is not the author.

---

## 2.  Structure Rules

### 2.1 Required Sections

Every spec must contain all of the following sections. Sections may be marked `N/A` with a reason but must not be silently omitted.

| # | Section | Required in |
|---|---------|------------|
| 1 | Purpose / Overview | All specs |
| 2 | Scope | All specs |
| 3 | Stakeholders | All specs |
| 4 | Functional / Technical Requirements | Functional, Deployment, Architecture |
| 5 | Data Schemas | Functional, Data specs |
| 6 | Error Handling | Functional, Deployment specs |
| 7 | Security | All specs |
| 8 | Cost Estimate (itemised) | Deployment, Architecture specs |
| 9 | Network Specification | Deployment, Architecture specs |
| 10 | Rollback / Recovery | Deployment specs |
| 11 | Acceptance Criteria | Functional, Deployment specs |
| 12 | Out of Scope | All specs |
| 13 | Glossary | All specs |

### 2.2 Table of Contents

Every spec with more than 5 sections must include a linked Table of Contents immediately after the header block. Anchor links must work in standard Markdown renderers (GitHub, VS Code Preview).

### 2.3 Section Numbering

- Top-level sections: `## 1.  Title`
- Subsections: `### 1.1 Title`
- Sub-subsections: `#### 1.1.1 Title` — maximum three levels deep
- Never use unnumbered heading levels for spec content

### 2.4 One Document, One Responsibility

Each spec covers one system, service, or feature. If a spec covers multiple unrelated systems, it must be split. Addenda (`-ADD-NNN`) are used for extensions; they do not replace sections in the parent — they augment them.

---

## 3.  Content Rules

### 3.1 Language

| Rule | Rationale |
|------|-----------|
| Use **must**, **must not**, **should**, **should not**, **may** (RFC 2119) for requirements | Removes ambiguity about whether something is mandatory |
| Write in active voice | "The system must send an alert" not "An alert must be sent" |
| Use present tense for requirements | "The API returns..." not "The API will return..." |
| No jargon without definition | Every acronym and technical term must appear in the Glossary |
| No vague quantifiers | Never write "fast", "soon", "large" without a measurable value |

### 3.2 Prohibited Phrases

The following phrases are banned in all specs. Replace them with specific, measurable statements.

| Banned phrase | Replace with |
|--------------|-------------|
| "As soon as possible" | Specific SLA or time target |
| "Best effort" | Quantified availability or throughput target |
| "TBD" / "TBC" | A placeholder with an owner and due date, e.g. `[TBD by @owner by YYYY-MM-DD]` |
| "etc." | Complete the list |
| "And so on" | Complete the list |
| "Fast" / "efficient" | Specific latency, throughput, or time target |
| "Scalable" | Specific scale target (e.g. "must handle 10,000 concurrent users") |
| "Secure" | Specific security control (e.g. "must enforce TLS 1.2 minimum") |
| "Simple" | Omit — not measurable |
| "Obviously" / "clearly" | Omit — condescending and imprecise |

### 3.3 Placeholder Policy

Placeholders are permitted only when the value is genuinely unknown at spec-writing time. They must follow this format:

```
<placeholder-name>          e.g. <subscription-id>
<placeholder-name:type>     e.g. <budget-limit:USD>
<placeholder-name:owner:due-date>   e.g. <api-key:@devops:2026-04-01>
```

A spec containing more than **5 unresolved placeholders** must not advance to `Approved` status.

### 3.4 Requirements Format

Functional and non-functional requirements must be written in this format:

```
**<ID>** — <Component> must <requirement>.
Rationale: <why this requirement exists>
```

Example:
```
**FR-04** — The API must return a response within 200ms at P95 under normal load.
Rationale: User-facing requests exceeding 200ms measurably increase abandonment rate.
```

---

## 4.  Technical Specification Rules

### 4.1 No Ambiguous Architecture Descriptions

Every architecture diagram must be accompanied by a written description. ASCII diagrams are acceptable; images are acceptable if also committed to the repository. Diagrams must show:

- All services / components
- Direction of data flow (arrows)
- Where authentication occurs
- Where data is persisted

### 4.2 API Specifications

Any API referenced in a spec must include:

- Full endpoint URL (or URL template with placeholders)
- HTTP method
- Authentication method
- Required parameters
- Response schema (minimum: key fields and types)
- Rate limits (if applicable)
- Link to official documentation

### 4.3 No Assumed Defaults

Every configurable value must be explicitly stated. Never rely on a service's default value being correct — defaults change between versions. Specify:

- SKU / tier
- Region
- Replication factor
- Retention period
- Timeout values
- Retry counts and backoff strategy

### 4.4 Technology Choices Must Be Justified

Any technology choice (framework, database, queue, language) must include a one-line rationale. Format:

```
| Technology | Choice | Rationale |
|------------|--------|-----------|
| Database   | PostgreSQL | ACID compliance required; team has existing expertise |
```

---

## 5.  Data & Schema Rules

### 5.1 All Schemas Must Be Typed

Every data schema must include:

- Field name
- Data type (string, integer, float, boolean, UUID, ISO 8601 datetime, enum)
- Required or optional
- Constraints (max length, allowed values, range)
- Example value

### 5.2 Schema Format

Use JSON with inline comments for schemas in spec documents:

```json
{
  "field_name": "<type>  // required | optional — <constraint> — example: <value>"
}
```

Example:

```json
{
  "restaurant_id": "UUID        // required — v4 UUID",
  "rating":        "float       // optional — range: 0.0–5.0 — example: 4.2",
  "price_range":   "enum        // required — values: $ | $$ | $$$",
  "last_seen":     "datetime    // required — ISO 8601 UTC — example: 2026-03-19T14:00:00Z"
}
```

### 5.3 No Unnamed Fields

Schemas must not contain unnamed fields, wildcard keys, or `object` types without definition. If a field's schema is dynamic, document the range of possible shapes.

### 5.4 Enum Values Must Be Exhaustive

Any field defined as an enum must list every possible value. Add a note if new values may be added in future: `// extensible enum — new values require schema version bump`.

---

## 6.  Security Rules

### 6.1 Mandatory Security Section

Every spec must contain a security section covering all of the following that apply:

| Area | Required content |
|------|-----------------|
| Authentication | Mechanism (Entra ID, API key, OAuth, JWT) + token lifetime |
| Authorisation | RBAC roles, permission model, least-privilege rationale |
| Secrets management | Where secrets live (Key Vault, env vars, GitHub Secrets) + rotation policy |
| Encryption in transit | TLS version minimum, protocols enforced |
| Encryption at rest | Encryption method (PMK / CMK), key management |
| Data classification | Sensitivity level per data type (Public / Internal / Confidential / Restricted) |
| Compliance | Frameworks applicable (SOC 2, ISO 27001, GDPR, HIPAA) |

### 6.2 No Hardcoded Credentials

Specs must never contain real credentials, connection strings, API keys, passwords, or tokens — even as examples. Use the placeholder format from Rule 3.3.

### 6.3 No "Security TBD"

Security requirements must be fully specified before a spec reaches `Approved` status. Security is not a post-deployment concern.

### 6.4 Zero Trust Checklist

Every deployment spec must address:

```
[ ] All service-to-service calls use Managed Identity or equivalent — no shared secrets
[ ] Least-privilege RBAC roles documented per component
[ ] Network access restricted to required flows only
[ ] All data classified and handling rules documented
[ ] Audit logging enabled on all sensitive operations
[ ] MFA enforced for human access to production systems
```

---

## 7.  Cost & Estimation Rules

### 7.1 No Unitemised Cost Estimates

A total monthly cost figure (e.g. `~$645/mo`) must never appear without a line-item breakdown. Every cost estimate must include:

- Service name
- SKU / configuration
- Unit price
- Estimated usage
- Monthly cost
- Source / basis for the estimate (Azure pricing calculator, known rate, previous month actuals)

### 7.2 Cost Estimate Format

```markdown
| Service | SKU / Config | Unit Price | Est. Usage | Monthly Cost |
|---------|-------------|-----------|-----------|-------------|
| <name>  | <sku>       | $x.xx/unit | <volume>  | $xx.xx      |
| **Total** | | | | **$xxx.xx** |
| **+ 20% buffer** | | | | **$xxx.xx** |
```

The 20% buffer is mandatory on all estimates. A budget ceiling must be stated.

### 7.3 Cost Sensitivity Analysis

Every cost estimate must identify the top three cost drivers and state what would happen if usage doubled:

```
Top cost drivers:
1. <service> — $x/mo (x% of total) — doubles to $x if <condition>
2. <service> — $x/mo (x% of total)
3. <service> — $x/mo (x% of total)
```

### 7.4 Budget Alerts Are Mandatory

Every deployment spec must include configured budget alerts at:

- 80% of budget — Warning
- 100% of budget — Critical
- 90% of budget (forecasted) — Early warning

The alert configuration must be included as runnable CLI or IaC code — not just described.

---

## 8.  Network & Infrastructure Rules

### 8.1 Make a Decision — No Contradictions

A spec must never simultaneously state "no VNet required" and describe VNet components (subnets, NSGs, Private Endpoints). The network architecture must be one of:

| Option | When to use |
|--------|------------|
| Public PaaS | Default — no compliance requirement for private connectivity |
| Private (VNet + Private Endpoints) | Compliance requires private connectivity (SOC 2, HIPAA, enterprise policy) |
| Hybrid | On-premises connectivity required — must specify ExpressRoute or VPN Gateway |

The chosen option must be stated explicitly. Any deviation requires written justification.

### 8.2 Subnet Specifications Are Mandatory (Private Option)

If VNet is used, the spec must include a complete subnet table:

```markdown
| Subnet name | CIDR | Purpose | Minimum size | NSG |
|-------------|------|---------|-------------|-----|
```

CIDR ranges must be:
- Non-overlapping with other subnets in the spec
- Non-overlapping with any stated hub or on-premises ranges
- Sized with 30% headroom for future growth

### 8.3 NSG Rules Must Be Complete

If NSGs are specified, every NSG must include a full rule table with: Priority, Name, Direction, Protocol, Source, Destination, Port, Action.

Default deny-all rules must be explicitly included — do not rely on implicit Azure defaults.

### 8.4 Private Endpoints Must Be Named

If Private Endpoints are used, every PE must have:

- Resource name (following the naming convention)
- Target service
- DNS zone
- NIC name
- Subnet placement

### 8.5 DNS Must Be Explicit

Specify whether DNS resolution uses:

- Azure-managed public DNS
- Private DNS Zones (list each zone)
- Custom DNS servers (specify IPs)
- Conditional forwarders (specify condition and target)

---

## 9.  CI/CD & Deployment Rules

### 9.1 Every Deployment Spec Must Include a Rollback Strategy

Rollback must be specified at every applicable layer:

| Layer | Required rollback mechanism |
|-------|---------------------------|
| Infrastructure (IaC) | Re-deploy previous Git tag; cancel in-flight deployment |
| Application (containers, functions) | Slot swap, revision rollback, or artifact re-deploy |
| Data | Point-in-time restore or migration rollback script |
| Configuration / secrets | Key Vault version rollback |

A rollback decision tree must be included showing which lever to pull and in what order.

### 9.2 Pipeline Must Have a Validate Gate

Every CI/CD pipeline must include a validate/what-if step that runs before any deployment. No deployment job may start without the validate job completing successfully.

### 9.3 Production Deployments Require Approval

Deployments to production environments must require a named human approver via a GitHub Environment protection rule or equivalent. Auto-deploy to production on push is not permitted.

### 9.4 Every Deployment Must Be Tagged

Successful production deployments must create a Git tag in the format:

```
prod-YYYYMMDD-HHMMSS
```

This tag is the rollback target for infrastructure re-deploys.

### 9.5 Pipeline Secrets Must Be Named

All secrets used in CI/CD pipelines must be listed in the spec with:

- Secret name (as it appears in the pipeline)
- What it contains (description, not the value)
- Where it is set (GitHub repo secrets, environment secrets, etc.)
- OIDC preferred over long-lived credentials — must be stated if OIDC is not used and why

### 9.6 Pre-Deployment Checklist Is Mandatory

Every deployment spec must include a pre-deployment checklist in checkbox format that an engineer can work through before running any deployment. Minimum items:

```
[ ] Subscription / account access verified
[ ] Required IAM roles / permissions confirmed
[ ] Quota pre-checked for all resource types
[ ] IaC validated (what-if / plan) against target environment
[ ] Rollback target identified and tagged
[ ] On-call contact identified for deployment window
[ ] Budget alert configured
[ ] Monitoring dashboards ready
```

---

## 10.  Review & Approval Rules

### 10.1 Reviewer Requirements

| Spec type | Minimum reviewers | Required expertise |
|-----------|------------------|-------------------|
| Functional spec | 1 | Engineering lead or senior developer |
| Deployment spec | 2 | 1 infrastructure + 1 security |
| Architecture spec | 2 | 1 architecture + 1 domain expert |
| Data spec | 1 | Data engineer or DBA |
| Security spec | 2 | Security engineer + legal/compliance |

### 10.2 Review Checklist

Reviewers must verify all of the following before approving:

```
[ ] All required sections present (Rule 2.1)
[ ] No prohibited phrases (Rule 3.2)
[ ] No more than 5 unresolved placeholders (Rule 3.3)
[ ] All schemas are typed with constraints (Rule 5.1)
[ ] Security section complete (Rule 6.1)
[ ] No hardcoded credentials (Rule 6.2)
[ ] Cost estimate is itemised with breakdown (Rule 7.1)
[ ] Budget alerts defined as runnable code (Rule 7.4)
[ ] Network decision is explicit — no contradictions (Rule 8.1)
[ ] Rollback strategy covers all layers (Rule 9.1)
[ ] Pre-deployment checklist present (Rule 9.6)
[ ] Acceptance criteria are testable — binary pass/fail (Rule 10.3)
[ ] Out of scope section present (Rule 2.1)
[ ] Glossary defines all acronyms used (Rule 3.1)
```

### 10.3 Acceptance Criteria Standards

Every acceptance criterion must be:

- Testable — a QA engineer can write a test for it without asking the author
- Binary — it passes or it fails, no partial credit
- Assigned — each AC maps to a feature or requirement ID

Bad AC: *"The system should be fast."*  
Good AC: *"AC-07 — The detail panel must render within 2 seconds for a cached SKU at P95 under normal load."*

---

## 11.  Maintenance Rules

### 11.1 Specs Must Be Updated When Systems Change

A spec that does not reflect the current system is worse than no spec. When a system changes:

- Update the spec before or simultaneously with the code change
- Bump the minor version
- Update the date field

### 11.2 Deprecation Policy

When a spec is superseded:

1. Set status to `Deprecated`
2. Add a notice at the top: `> This document is deprecated. See [replacement doc ID].`
3. Do not delete — retain for audit trail

### 11.3 Review Cadence

| Spec type | Mandatory review cadence |
|-----------|-------------------------|
| Functional spec | Before each sprint that touches the feature |
| Deployment spec | Before each production deployment |
| Architecture spec | Quarterly or when a major component changes |
| Security spec | Every 6 months or after any security incident |

### 11.4 Spec Ownership

Every spec must have a named owner responsible for keeping it current. The owner is not necessarily the author. When an owner leaves the team, ownership must be reassigned within 5 business days.

---

## 12.  Compliance Checklist

Use this checklist to verify a spec is ready to advance from `Draft` to `Review`, and from `Review` to `Approved`.

### Draft → Review

```
DOCUMENT STANDARDS
[ ] Header block complete with all required fields
[ ] Document ID follows naming convention
[ ] Version number set to 1.0
[ ] Status set to "Review"
[ ] Table of contents present with working anchor links

STRUCTURE
[ ] All required sections present or marked N/A with reason
[ ] Sections numbered correctly (no gaps, no duplicates)
[ ] Maximum 3 heading levels deep

CONTENT
[ ] No prohibited phrases (Rule 3.2)
[ ] All acronyms defined in Glossary
[ ] No vague quantifiers — all requirements are measurable
[ ] Placeholders follow correct format — fewer than 5 unresolved
[ ] Requirements use must / must not / should language

TECHNICAL
[ ] Architecture diagram present with data flow arrows
[ ] All APIs documented with endpoint, method, auth, response
[ ] All configurable values explicitly stated (no assumed defaults)
[ ] Technology choices include rationale

DATA
[ ] All schemas typed with field-level constraints
[ ] No unnamed fields or untyped object types
[ ] All enums exhaustive

SECURITY
[ ] Security section covers all 7 areas (Rule 6.1)
[ ] No hardcoded credentials
[ ] Zero Trust checklist complete
[ ] Data classified per field/entity

COST
[ ] Line-item cost breakdown present
[ ] 20% buffer applied
[ ] Top 3 cost drivers identified
[ ] Budget alerts defined as runnable code

NETWORK
[ ] Network option explicitly chosen (Public PaaS / Private / Hybrid)
[ ] No contradictions between sections
[ ] Subnet table present if VNet used (with CIDRs)
[ ] NSG rule tables complete if NSGs used
[ ] DNS architecture explicit

CI/CD & DEPLOYMENT
[ ] Rollback strategy covers infrastructure, application, and data layers
[ ] Rollback decision tree present
[ ] Validate/what-if gate in pipeline
[ ] Production approval gate specified
[ ] Pre-deployment checklist present
[ ] Pipeline secrets listed with descriptions

REVIEW
[ ] Acceptance criteria are binary and testable
[ ] Out of scope section present
[ ] At least one reviewer assigned who is not the author
```

### Review → Approved

```
[ ] All Draft → Review items confirmed
[ ] Review checklist (Rule 10.2) completed by required reviewers
[ ] All reviewer comments resolved or explicitly deferred with justification
[ ] All placeholders resolved OR remaining placeholders approved as acceptable risk
[ ] No open "TBD" items without named owner and due date
[ ] Status updated to "Approved"
[ ] Version confirmed correct
[ ] Document committed to repository under /docs/
```

---

## Appendix A — Spec Document Templates

Reference templates for each spec type are maintained at:

```
/docs/templates/
├── functional-spec-template.md
├── deployment-spec-template.md
├── architecture-spec-template.md
├── data-spec-template.md
└── security-spec-template.md
```

Each template is pre-populated with all required sections, placeholder content, and inline guidance comments.

---

## Appendix B — Quick Reference Card

```
EVERY SPEC NEEDS:
  Header block (ID, version, status, owner, date)
  Table of contents
  Purpose + scope + stakeholders
  Requirements (FR-xx / NFR-xx format)
  Typed schemas
  Security (auth, authz, secrets, encryption, classification)
  Cost breakdown (itemised, with 20% buffer)
  Network decision (explicit — no contradictions)
  Rollback strategy (infra + app + data)
  Acceptance criteria (binary, testable)
  Out of scope
  Glossary

NEVER WRITE:
  TBD / TBC (without owner + due date)
  "Fast" / "scalable" / "secure" (unmeasured)
  "Etc." / "and so on" (incomplete lists)
  Real credentials or API keys
  Unitemised cost totals
  Contradictory network requirements

BEFORE APPROVING:
  Two reviewers for deployment and architecture specs
  All prohibited phrases removed
  Fewer than 5 unresolved placeholders
  Budget alerts as runnable code
  Rollback decision tree present
```

---

*SPEC-RULES-001 · v1.0 · Active*  
*Owner: Engineering Lead*  
*Review cadence: Quarterly — next review: 2026-06-19*  
*All specs produced by this team are subject to this ruleset from 2026-03-19 onwards.*
