# Compliance Mapping - DevSecOps Portfolio

## Overview

This document maps the security controls implemented in this DevSecOps platform to industry-standard frameworks and regulations.

---

## ISO/IEC 27001:2013 & 27002:2022

### A.5 - Information Security Policies
| Control | Implementation | Evidence |
|---------|---------------|----------|
| A.5.1.1 - Policies for information security | Security policies documented in `/docs` | This document, incident runbook |
| A.5.1.2 - Review of policies | Quarterly review process defined | Change control process |

### A.9 - Access Control
| Control | Implementation | Evidence |
|---------|---------------|----------|
| A.9.1.1 - Access control policy | RBAC implemented in AKS | `/k8s/rbac/` manifests |
| A.9.1.2 - Access to networks and services | Network policies restrict pod-to-pod traffic | `/k8s/network-policies/` |
| A.9.2.1 - User registration | Azure AD integration for AKS | `terraform/aks.tf` - AAD RBAC |
| A.9.2.2 - Privilege management | Least privilege via RBAC roles | ClusterRole definitions |
| A.9.2.3 - User access provisioning | Automated via Terraform | IAM role assignments |
| A.9.4.1 - Information access restriction | Secrets in Key Vault, not in code | `terraform/keyvault.tf` |
| A.9.4.5 - Access control to program source code | Branch protection, code review required | GitHub settings |

### A.10 - Cryptography
| Control | Implementation | Evidence |
|---------|---------------|----------|
| A.10.1.1 - Policy on use of cryptographic controls | TLS for all communications | Ingress TLS configuration |
| A.10.1.2 - Key management | Azure Key Vault with RBAC | `terraform/keyvault.tf` |

### A.12 - Operations Security
| Control | Implementation | Evidence |
|---------|---------------|----------|
| A.12.1.2 - Change management | Documented change control process | `/docs/change-control.md` |
| A.12.4.1 - Event logging | Centralized logging to Log Analytics | `terraform/monitoring.tf` |
| A.12.4.2 - Protection of log information | Log Analytics with RBAC | Diagnostic settings |
| A.12.4.3 - Administrator and operator logs | Audit logs for all admin actions | Azure Activity Log |
| A.12.6.1 - Management of technical vulnerabilities | Automated vulnerability scanning in pipeline | Jenkinsfile - Trivy, Semgrep |
| A.12.6.2 - Restrictions on software installation | Only approved images from ACR | Azure Policy |

### A.13 - Communications Security
| Control | Implementation | Evidence |
|---------|---------------|----------|
| A.13.1.1 - Network controls | Network Security Groups, Network Policies | `terraform/main.tf`, `/k8s/network-policies/` |
| A.13.1.2 - Security of network services | Azure CNI with network policies | `terraform/aks.tf` |
| A.13.2.1 - Information transfer policies | TLS encryption for all traffic | Ingress configuration |

### A.14 - System Acquisition, Development and Maintenance
| Control | Implementation | Evidence |
|---------|---------------|----------|
| A.14.2.1 - Secure development policy | DevSecOps pipeline with security gates | Jenkinsfile |
| A.14.2.2 - System change control procedures | CI/CD pipeline with approvals | Manual approval stage |
| A.14.2.3 - Technical review after platform changes | Post-deployment verification | DAST stage |
| A.14.2.5 - Secure system engineering principles | Defense in depth, least privilege | Architecture design |
| A.14.2.8 - System security testing | SAST, DAST, SCA, container scanning | All pipeline stages |
| A.14.2.9 - System acceptance testing | Staging environment testing | Deployment to staging |

### A.16 - Information Security Incident Management
| Control | Implementation | Evidence |
|---------|---------------|----------|
| A.16.1.1 - Responsibilities and procedures | Incident runbook documented | `/docs/incident-runbook.md` |
| A.16.1.2 - Reporting information security events | Azure Monitor alerts | `terraform/monitoring.tf` |
| A.16.1.4 - Assessment and decision on events | Severity-based alert routing | Action groups |
| A.16.1.5 - Response to incidents | Documented response procedures | Incident runbook |

### A.18 - Compliance
| Control | Implementation | Evidence |
|---------|---------------|----------|
| A.18.1.1 - Identification of applicable legislation | This compliance mapping | This document |
| A.18.2.2 - Compliance with security policies | Automated policy enforcement | Azure Policy |
| A.18.2.3 - Technical compliance review | Regular security scans | Pipeline execution |

---

## NIST Cybersecurity Framework (CSF)

### Identify
| Category | Subcategory | Implementation |
|----------|-------------|----------------|
| Asset Management | ID.AM-1: Physical devices and systems inventoried | Terraform state tracks all infrastructure |
| Asset Management | ID.AM-2: Software platforms inventoried | SBOM generated for all containers |
| Asset Management | ID.AM-3: Organizational communication flows mapped | Architecture diagram |
| Risk Assessment | ID.RA-1: Asset vulnerabilities identified | Trivy, Semgrep, Dependency-Check scans |
| Risk Assessment | ID.RA-5: Threats and vulnerabilities communicated | Risk matrix document |
| Governance | ID.GV-3: Legal and regulatory requirements understood | Compliance mapping (this doc) |

### Protect
| Category | Subcategory | Implementation |
|----------|-------------|----------------|
| Access Control | PR.AC-1: Identities and credentials managed | Azure AD integration, Key Vault |
| Access Control | PR.AC-3: Remote access managed | VPN/bastion for cluster access |
| Access Control | PR.AC-4: Access permissions managed | RBAC in AKS |
| Access Control | PR.AC-5: Network integrity protected | Network policies, NSGs |
| Awareness & Training | PR.AT-2: Privileged users understand roles | Documentation provided |
| Data Security | PR.DS-1: Data-at-rest protected | Azure encryption |
| Data Security | PR.DS-2: Data-in-transit protected | TLS everywhere |
| Data Security | PR.DS-5: Protections against data leaks | Gitleaks secrets scanning |
| Protective Technology | PR.PT-1: Audit/log records determined | Comprehensive logging |
| Protective Technology | PR.PT-3: Least functionality principle | Minimal container images |

### Detect
| Category | Subcategory | Implementation |
|----------|-------------|----------------|
| Anomalies & Events | DE.AE-1: Baseline of network operations established | Azure Monitor baseline |
| Anomalies & Events | DE.AE-3: Event data aggregated | Log Analytics workspace |
| Security Monitoring | DE.CM-1: Network monitored | Azure Monitor for containers |
| Security Monitoring | DE.CM-4: Malicious code detected | Container image scanning |
| Security Monitoring | DE.CM-7: Monitoring for unauthorized activity | Defender for Cloud |
| Detection Processes | DE.DP-4: Event detection communicated | Alert action groups |

### Respond
| Category | Subcategory | Implementation |
|----------|-------------|----------------|
| Response Planning | RS.RP-1: Response plan executed | Incident runbook |
| Communications | RS.CO-2: Events reported | Alerting to action groups |
| Analysis | RS.AN-1: Notifications investigated | Runbook procedures |
| Mitigation | RS.MI-2: Incidents mitigated | Documented mitigation steps |

### Recover
| Category | Subcategory | Implementation |
|----------|-------------|----------------|
| Recovery Planning | RC.RP-1: Recovery plan executed | Disaster recovery via IaC |
| Improvements | RC.IM-1: Lessons learned incorporated | Post-incident review process |

---

## CIS Controls v8

| Control | Title | Implementation |
|---------|-------|----------------|
| **CIS 1** | Inventory and Control of Enterprise Assets | Terraform state, Azure Resource Graph |
| **CIS 2** | Inventory and Control of Software Assets | SBOM generation, container registry |
| **CIS 3** | Data Protection | Encryption at rest/transit, Key Vault |
| **CIS 4** | Secure Configuration | Checkov IaC scanning, Azure Policy |
| **CIS 5** | Account Management | Azure AD, RBAC |
| **CIS 6** | Access Control Management | Least privilege RBAC, network policies |
| **CIS 7** | Continuous Vulnerability Management | Automated scanning in pipeline |
| **CIS 8** | Audit Log Management | Log Analytics, diagnostic settings |
| **CIS 9** | Email and Web Browser Protections | N/A (infrastructure focus) |
| **CIS 10** | Malware Defenses | Container image scanning, Defender |
| **CIS 11** | Data Recovery | Backup strategies (to be implemented) |
| **CIS 12** | Network Infrastructure Management | NSGs, network policies, Azure Firewall |
| **CIS 13** | Network Monitoring and Defense | Azure Monitor, Network Watcher |
| **CIS 14** | Security Awareness Training | Documentation provided |
| **CIS 15** | Service Provider Management | Azure as trusted provider |
| **CIS 16** | Application Software Security | SAST, DAST, SCA in pipeline |
| **CIS 17** | Incident Response Management | Incident runbook, alerting |
| **CIS 18** | Penetration Testing | DAST with OWASP ZAP |

---

## ISO 22301 - Business Continuity

| Requirement | Implementation |
|-------------|----------------|
| Business Impact Analysis | Risk matrix identifies critical assets |
| Continuity Strategy | Infrastructure as Code enables rapid rebuild |
| Incident Response | Documented in incident runbook |
| Recovery Procedures | Terraform can recreate entire infrastructure |
| Testing | Regular pipeline execution validates deployment |

---

## ISO 27701 - Privacy (GDPR Considerations)

| Requirement | Implementation |
|-------------|----------------|
| Data Minimization | Only necessary data collected |
| Purpose Limitation | Data used only for intended purpose |
| Storage Limitation | Retention policies in ACR, Log Analytics |
| Security of Processing | Encryption, access controls |
| Data Subject Rights | Procedures for data access/deletion (to be documented) |
| Data Protection by Design | Security built into architecture |

---

## OWASP Top 10 (2021)

| Risk | Mitigation |
|------|------------|
| A01:2021 - Broken Access Control | RBAC, network policies, least privilege |
| A02:2021 - Cryptographic Failures | TLS everywhere, Key Vault for secrets |
| A03:2021 - Injection | Input validation, parameterized queries, SAST |
| A04:2021 - Insecure Design | Threat modeling, security requirements |
| A05:2021 - Security Misconfiguration | Checkov scanning, Azure Policy |
| A06:2021 - Vulnerable Components | SCA with Dependency-Check |
| A07:2021 - Authentication Failures | Azure AD, no default credentials |
| A08:2021 - Software and Data Integrity | Image signing, SBOM |
| A09:2021 - Security Logging Failures | Comprehensive logging to Log Analytics |
| A10:2021 - SSRF | Network policies, egress filtering |

---

## Compliance Summary

### ✅ Fully Implemented
- Access control (RBAC)
- Secrets management (Key Vault)
- Vulnerability scanning (SAST, SCA, DAST, container)
- Logging and monitoring
- Network segmentation
- Encryption (TLS, at-rest)
- IaC security scanning

### ⚠️ Partially Implemented
- Backup and disaster recovery (IaC enables rebuild, but data backup needed)
- Privacy controls (framework in place, specific procedures needed)
- Penetration testing (DAST only, manual pentest recommended)

### 📋 Recommended Additions
- Regular third-party security audits
- Red team exercises
- Enhanced SIEM with Microsoft Sentinel
- Data loss prevention (DLP) policies
- Enhanced backup solution for stateful data

---

## Audit Trail

| Date | Reviewer | Changes | Version |
|------|----------|---------|---------|
| 2026-02-04 | DevSecOps Team | Initial compliance mapping | 1.0 |

---

**Next Review Date**: 2026-05-04 (Quarterly)
