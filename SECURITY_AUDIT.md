# Security Audit Report — Azure AI Deployment Portal

**Audit Date:** March 26, 2026  
**Scope:** Landing page portal, Bicep IaC modules, deployment configurations  
**Status:** ⚠️ **FINDINGS IDENTIFIED** — See critical and high-priority items

---

## Executive Summary

This portal provides 10 Azure AI deployment patterns with infrastructure-as-code templates. The overall security posture is **strong** for cloud infrastructure with good practices around networking, identity, and encryption. However, **3 critical issues** were identified that require immediate remediation, primarily related to:

1. **Hardcoded credentials** in SQL MI template
2. **Content Security Policy violations** in HTML (inline event handlers)
3. **Unsafe client-side patterns** with CDN dependencies

---

## Critical Issues (Fix Immediately)

### 1. 🔴 CRITICAL: Hardcoded Password in SQL MI Deployment Spec

**Location:** [landing-page/specs/azure-sqlmi.bicep](landing-page/specs/azure-sqlmi.bicep#L27)

```bicep
administratorLoginPassword: 'P@ssw0rd1234!!'  // Use KeyVault reference in production
```

**Risk:** If this template is used in production, the database administrator password is hardcoded, allowing anyone with repository access to obtain it. This violates fundamental credential management practices.

**Impact:** 
- 🔓 Unauthorized database access
- 📋 Compliance violation (PCI-DSS, HIPAA, SOC 2)
- 🎯 Attack vector for lateral movement

**Remediation:**
```bicep
@secure()
param sqlAdminPassword string

// Use parameter instead
administratorLoginPassword: sqlAdminPassword
```

Also update the help documentation to **never use hardcoded passwords** and always reference Key Vault.

**Verification:** ✓ Template is sample/spec file (good), but documentation warning needed

---

### 2. 🔴 CRITICAL: Inline Event Handlers Violate Content Security Policy

**Location:** Multiple HTML files in [landing-page/](landing-page/)
- [csi-education.html](landing-page/csi-education.html#L323) (lines 323, 571, 674, 860, 913)
- [index.html](landing-page/index.html#L1084) (lines 1084, 1109, 1134, etc.)
- [help.html](landing-page/help.html#L941)

**Example:**
```html
<!-- Inline onclick - violates CSP -->
<button onclick="enlargeDiagram(this)">Enlarge</button>
<button onclick="openDeploySpec(1)">Generate Deployment Spec</button>
<button id="backToTop" onclick="window.scrollTo({top:0,behavior:'smooth'})">↑</button>
```

**Risk:**
- ⚠️ Static Web Apps has CSP: `script-src 'self' 'unsafe-inline'` which allows these but is security anti-pattern
- XSS vulnerability if any attributes are user-controlled
- Maintenance debt: harder to audit event handlers

**Impact:**
- 🎯 Potential XSS if input is reflected in onclick handlers
- 📋 OWASP Top 10: A03:2021 – Injection
- 🔐 Non-compliance with strict CSP best practices

**Remediation:** Convert all inline handlers to event listeners

**Example Fix:**
```html
<!-- Before -->
<button onclick="enlargeDiagram(this)">Enlarge</button>

<!-- After -->
<button class="btn-enlarge" data-action="enlarge-diagram">Enlarge</button>

<!-- Script -->
<script>
  document.addEventListener('click', (e) => {
    if (e.target.classList.contains('btn-enlarge')) {
      enlargeDiagram(e.target);
    }
  });
</script>
```

**Priority:** High — Remove all `onclick`, `onload`, `onerror` handlers

---

### 3. 🔴 CRITICAL: Missing Subresource Integrity (SRI) on External Scripts

**Location:** [landing-page/](landing-page/) — All HTML files with Bootstrap/CDN

**Current:**
```html
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" />
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.min.js"></script>
```

**Risk:**
- 🎯 CDN compromise or MITM: attacker injects malicious code
- 📊 No integrity verification of external resources

**Impact:**
- **Severity:** High
- **Attack Vector:** Network-level (ISP, BGP hijacking, DNS poisoning)
- **User Impact:** Malicious script execution in browser

**Remediation:** Add `integrity` and `crossorigin="anonymous"` attributes

**Example Fix:**
```html
<!-- Secure CDN links with SRI hashes -->
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" 
      rel="stylesheet" 
      integrity="sha384-QWTKZyjpPEjHS1QVoT2H8K1OKNqNdfHU6rEQf12wnhx0VTpEpfJ35vAVgdW2hIGd" 
      crossorigin="anonymous" />
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js" 
        integrity="sha384-YvpcrYf0tY3lHB60NNkmXc5s9fDVZLESaAA55DQYC+9uNTmQvcQV1RoGtR1uxHnL" 
        crossorigin="anonymous"></script>
```

**How to generate SRI hashes:**
```bash
# From https://www.srihash.org/ or using npm
npm install -g sri

# Or curl + openssl
curl -s https://cdn.example.com/bootstrap.min.js | openssl dgst -sha384 -binary | openssl base64 -A
```

---

## High-Priority Issues (Fix Before Production)

### 4. 🟠 HIGH: Mermaid Security Level Set to 'loose'

**Location:** [landing-page/csi-education.html](landing-page/csi-education.html#L920)

```javascript
mermaid.initialize({
  startOnLoad: true,
  theme: 'default',
  securityLevel: 'loose',  // ⚠️ UNSAFE
  htmlLabels: true,         // ⚠️ Allows HTML in diagram labels
  // ...
});
```

**Risk:**
- Mermaid with `htmlLabels: true` + `securityLevel: 'loose'` can execute arbitrary HTML/scripts in diagrams
- If diagram data comes from user input → XSS vulnerability

**Remediation:**
```javascript
mermaid.initialize({
  startOnLoad: true,
  theme: 'default',
  securityLevel: 'strict',  // Block dangerous HTML
  htmlLabels: false,        // Disable HTML in labels
  // ...
});
```

---

### 5. 🟠 HIGH: Content Security Policy Allows 'unsafe-inline'

**Location:** [landing-page/staticwebapp.config.json](landing-page/staticwebapp.config.json)

```json
"Content-Security-Policy": "default-src 'self'; script-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net; style-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net; ..."
```

**Issues:**
- ✗ `script-src 'unsafe-inline'` — allows inline scripts (reduces CSP effectiveness)
- ✓ `frame-src 'none'` — good (prevents clickjacking)
- ✓ `object-src 'none'` — good (blocks plugins)

**Recommendation:** Remove `'unsafe-inline'` after fixing inline event handlers (#2)

**Strict CSP (post-remediation):**
```json
"Content-Security-Policy": "default-src 'self'; script-src 'self' https://cdn.jsdelivr.net; style-src 'self' https://cdn.jsdelivr.net; font-src 'self' https://cdn.jsdelivr.net; img-src 'self' data: https:; frame-src 'none'; object-src 'none'; base-uri 'self'; form-action 'self'; upgrade-insecure-requests"
```

---

### 6. 🟠 HIGH: SQL MI Has publicDataEndpointEnabled

**Location:** [landing-page/specs/azure-sqlmi.bicep](landing-page/specs/azure-sqlmi.bicep#L33)

```bicep
publicDataEndpointEnabled: true  // ⚠️ Allows public internet access
```

**Risk:**
- SQL MI instance is accessible from the internet if network-level restrictions absent
- Should only be enabled for specific dev/test scenarios with strong authentication

**Remediation:**
```bicep
@description('Enable public data endpoint (only for dev/test)')
param enablePublicDataEndpoint bool = false

// In template:
publicDataEndpointEnabled: enablePublicDataEndpoint
```

**Guidance:** Document that production deployments should use private endpoints

---

### 7. 🟠 HIGH: Container Registry Admin User Not Disabled by Default

**Location:** [landing-page/specs/azure-containerreg.bicep](landing-page/specs/azure-containerreg.bicep#L20)

```bicep
adminUserEnabled: false  // ✓ Good (but verify all specs follow this)
```

**Status:** ✓ Correct in specs, but recommended to explicitly disable in docs.

**Best Practice:** Use managed identities + role assignments instead of admin credentials.

**Verification needed:** Ensure all pattern templates follow this.

---

### 8. 🟠 HIGH: Key Vault Public Network Access Not Consistently Disabled

**Locations:**
- [modules/security/keyVault.bicep](modules/security/keyVault.bicep) — defaults to 'Enabled' ⚠️
- [patterns/6-secure-private-ai/main.bicep](patterns/6-secure-private-ai/main.bicep#L271) — correctly set to 'Disabled' ✓

**Issue:**
```bicep
// Current default in module:
param publicNetworkAccess ('Enabled' | 'Disabled') = 'Enabled'  // ⚠️ Too permissive
```

**Remediation:**
```bicep
// Better default for security patterns:
param publicNetworkAccess ('Enabled' | 'Disabled') = 'Disabled'

// Or better yet, pattern-specific:
// - Pattern 1-5: 'Enabled' (with network ACLs)
// - Pattern 6 (Secure): 'Disabled' (private endpoints only)
```

---

## Medium-Priority Issues (Fix Before General Availability)

### 9. 🟡 MEDIUM: AKS Default Configuration Missing Security Best Practices

**Location:** [modules/compute/aks.bicep](modules/compute/aks.bicep)

**Status:** ✓ Has Azure RBAC enabled
**Missing:**
- Pod security policy / Pod Security Standards
- Network policies (Calico/Azure NPM)
- API server authorized IP ranges
- Disable local account authentication

**Remediation:** Add optional security parameters:
```bicep
@description('Enable network policies for pod-to-pod communication control')
param enableNetworkPolicy bool = true

@description('API server authorized IP ranges')
param apiServerAuthorizedIpRanges array = []

@description('Disable local Kubernetes accounts')
param disableLocalAccounts bool = true
```

---

### 10. 🟡 MEDIUM: GitHub Actions Missing Security Workflow Checks

**Location:** [.github/workflows/deploy-swa.yml](.github/workflows/deploy-swa.yml)

**Missing:**
- ✗ No SAST (Static Application Security Testing)
- ✗ No dependency scanning
- ✗ No artifact signing
- ✗ No deployment approval gate

**Recommended additions:**
```yaml
- name: Run Bicep validation
  run: |
    az bicep validate --file patterns/*/main.bicep

- name: Scan for secrets (TruffleHog)
  uses: trufflesecurity/trufflehog@main

- name: SAST - Checkov
  uses: bridgecrewio/checkov-action@master
  with:
    directory: modules
    framework: bicep
```

---

### 11. 🟡 MEDIUM: Deployment Parameters Not Validated

**Issue:** Bicep templates accept user parameters without comprehensive validation

**Example:**
- OpenAI deployment capacity: no bounds checking
- VM sizes: no validation against quota availability
- VNet CIDR blocks: no overlap detection

**Remediation:** Add parameter validation with `@minValue`, `@maxValue`, `@metadata`

---

### 12. 🟡 MEDIUM: No Rate Limiting on Frontend

**Location:** [landing-page/staticwebapp.config.json](landing-page/staticwebapp.config.json)

**Issue:** No rate limiting configured for the landing page

**Remediation:** Add Azure Front Door or WAF rules:
```json
"rateLimit": {
  "requests": 100,
  "durationInSeconds": 60
}
```

---

## Low-Priority Issues (Best Practices)

### 13. 🔵 LOW: Consider Pinning Bootstrap Version

**Location:** All HTML files

**Current:**
```html
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" />
```

**Better:**
```html
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-..." crossorigin="anonymous" />
```

Pin specific patch version to avoid unexpected updates (e.g., `@5.3.3` instead of `@5`)

---

### 14. 🔵 LOW: Add Security.txt File

**Recommended:** Add [/.well-known/security.txt](https://securitytxt.org/) to portal for vulnerability disclosure:

```text
Contact: security@azuretools.wiki
Expires: 2027-03-26T00:00:00.000Z
Preferred-Languages: en
```

---

### 15. 🔵 LOW: Document Secret Rotation Policy

**Location:** [landing-page/help.html](landing-page/help.html#L207)

Add guidance on:
- Rotate AZURE_STATIC_WEB_APPS_API_TOKEN on deployment workflow
- Regenerate Service Principal credentials quarterly
- Store all secrets in GitHub Organization secrets, not repo secrets

---

## Security Strengths ✓

| Area | Implementation | Notes |
|------|-------------------|-------|
| **HTTPS/TLS** | ✓ Enforced | STS header set; minimum TLS 1.2 |
| **Managed Identities** | ✓ Comprehensive | Used across AKS, App Service, Functions, AML |
| **Private Endpoints** | ✓ Extensive | Pattern 1-7 use private endpoints for sensitive services |
| **Network Segmentation** | ✓ Strong | NSGs, VNet peering, firewall rules |
| **RBAC** | ✓ Good | Azure RBAC enabled in AKS, all services use managed identity principals |
| **Encryption** | ✓ Standard | TLS 1.2+, encryptionWithCmk in specs |
| **Secret Management** | ✓ Key Vault | Integrated throughout templates |
| **Monitoring** | ✓ Log Analytics | Centralized logging in secure patterns |
| **API Security** | ✓ Headers | X-Frame-Options, X-Content-Type-Options, Referrer-Policy set |
| **Firewall Rules** | ✓ Pattern 6 | Azure Firewall with threat intel enabled in secure pattern |

---

## Remediation Checklist

### Immediate (This Week)
- [ ] **#1** Replace hardcoded SQL password with parameter + KeyVault reference
- [ ] **#2** Convert all inline event handlers to event listeners
- [ ] **#3** Add SRI hashes to all CDN dependencies
- [ ] **#4** Change Mermaid `securityLevel` to `'strict'` and `htmlLabels` to `false`

### Before Release (This Month)
- [ ] **#5** Remove `'unsafe-inline'` from CSP script-src
- [ ] **#6** Document SQL MI publicDataEndpoint best practices
- [ ] **#8** Set Key Vault `publicNetworkAccess` default to 'Disabled'
- [ ] **#10** Add GitHub Actions security scanning (Checkov, TruffleHog)
- [ ] **#11** Add `@minValue`/`@maxValue` validators to Bicep parameters
- [ ] **#12** Configure rate limiting in Static Web Apps

### Before General Availability
- [ ] **#9** Add network policy support to AKS template
- [ ] **#13** Document version pinning strategy
- [ ] **#14** Add security.txt file
- [ ] **#15** Document secret rotation policy
- [ ] [ ] Security team review of compliance mappings (CIS, PCI-DSS, HIPAA)

---

## Testing Recommendations

### Automated Security Testing

```bash
# 1. Bicep Validation
az bicep validate --file patterns/*/main.bicep

# 2. ARM Template Validation
for f in patterns/*/main.bicep; do
  az bicep build --file "$f" --outfile "${f%.bicep}.json"
  az resource group deployment validate --template-file "${f%.bicep}.json"
done

# 3. Secret Scanning
git log --all -p | git-secrets --scan

# 4. CSP Validation
curl -I https://ai.azuretools.wiki | grep -i content-security

# 5. SRI Hash Verification
npm install -g sri
sri --file bootstrap.min.js  # Compare with HTML
```

### Manual Testing
- [ ] Test with CSP violation reporter (report-uri.com)
- [ ] Verify all CDN resources load correctly with SRI
- [ ] Test SQL MI with private endpoint only
- [ ] Verify Key Vault access from AKS without public endpoint

---

## Compliance Mapping

| Standard | Requirement | Status | Evidence |
|----------|-------------|--------|----------|
| **CIS Azure** | 1.1 - Encrypt data in transit | ✓ | TLS 1.2+ enforced, HTTPS only |
| **PCI-DSS** | 6.5.1 - Injection flaws | ⚠️ | Fix #2 (inline handlers), #4 (Mermaid) |
| **PCI-DSS** | 2.2.4 - Disable unnecessary services | ✓ | FTP disabled, local accounts disabled |
| **HIPAA** | 164.312(e)(2)(ii)(B) - Encryption | ⚠️ | Fix #1 (no hardcoded secrets) |
| **SOC 2** | CC6.1 - Logical access control | ✓ | RBAC, managed identities, Key Vault |
| **SOC 2** | CC7.2 - System monitoring | ✓ | Log Analytics integration |

---

## Conclusion

**Overall Security Rating: 7.5/10** ✅

This portal demonstrates **strong cloud security fundamentals** for IaC deployment patterns. The identified issues are **actionable and remediable**:

- **3 critical issues** require immediate fixes (credentials, CSP, SRI)
- **5 high-priority gaps** need addressing before production release
- **Infrastructure templates** follow security best practices

**Recommendation:** Fix critical issues before any production deployment, then implement remaining items in phased rollout.

---

## Appendix: Security Headers Reference

**Current Headers (Good):**
```
X-Content-Type-Options: nosniff
X-Frame-Options: SAMEORIGIN
X-XSS-Protection: 1; mode=block
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: camera=(), microphone=(), geolocation=(), payment=()
Strict-Transport-Security: max-age=31536000; includeSubDomains
```

---

**Audit completed by:** GitHub Copilot Security Analyzer  
**Report version:** 1.0  
**Last updated:** March 26, 2026

---
