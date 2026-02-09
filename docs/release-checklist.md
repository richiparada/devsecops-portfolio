# Release Checklist

## Pre-Release Checklist

### Code Quality
- [ ] All unit tests passing
- [ ] Code coverage meets threshold (>80%)
- [ ] Code review completed and approved
- [ ] Linting checks passed
- [ ] No TODO or FIXME comments in critical code

### Security Scans
- [ ] **SAST (Semgrep)**: No high/critical findings
- [ ] **Secrets Scanning (Gitleaks)**: No secrets detected
- [ ] **SCA (Dependency-Check)**: All critical vulnerabilities addressed
- [ ] **Container Scan (Trivy)**: No high/critical vulnerabilities
- [ ] **IaC Scan (Checkov)**: All critical issues resolved
- [ ] **DAST (OWASP ZAP)**: No high-risk findings in staging

### Software Bill of Materials (SBOM)
- [ ] SBOM generated for all container images
- [ ] SBOM archived in artifact repository
- [ ] SBOM reviewed for unexpected dependencies

### Image Security
- [ ] Container images built from approved base images
- [ ] Images scanned and approved
- [ ] Images signed with Cosign (if enabled)
- [ ] Images pushed to ACR with proper tags
- [ ] No images running as root user

### Configuration
- [ ] Environment variables configured correctly
- [ ] Secrets stored in Key Vault (not in code/manifests)
- [ ] Resource limits defined for all containers
- [ ] Health check endpoints configured
- [ ] Logging configured properly

### Infrastructure
- [ ] Terraform plan reviewed
- [ ] Infrastructure changes approved
- [ ] Backup taken (if applicable)
- [ ] Capacity planning reviewed
- [ ] Network policies updated if needed

### Documentation
- [ ] README updated
- [ ] API documentation updated
- [ ] Architecture diagrams current
- [ ] Runbooks updated
- [ ] Change log updated

### Compliance
- [ ] Compliance requirements reviewed
- [ ] Audit logs enabled
- [ ] Data protection measures in place
- [ ] Privacy requirements met

---

## Deployment Checklist

### Pre-Deployment
- [ ] Change request approved (see [Change Control](change-control.md))
- [ ] Deployment window scheduled
- [ ] Stakeholders notified
- [ ] Rollback plan documented and tested
- [ ] On-call engineer identified

### Staging Deployment
- [ ] Deploy to staging environment
- [ ] Run smoke tests
- [ ] Verify health endpoints
- [ ] Check application logs
- [ ] Run integration tests
- [ ] Perform manual testing
- [ ] DAST scan completed

### Production Deployment
- [ ] Final approval obtained
- [ ] Announce deployment window
- [ ] Take snapshot/backup (if applicable)
- [ ] Deploy to production
- [ ] Verify deployment success
  ```bash
  kubectl rollout status deployment/devsecops-api -n production
  kubectl get pods -n production
  ```
- [ ] Run smoke tests
  ```bash
  curl https://api.example.com/health
  curl https://api.example.com/api/items
  ```
- [ ] Check monitoring dashboards
- [ ] Review application logs
- [ ] Verify no alerts triggered

### Post-Deployment
- [ ] Monitor for 30 minutes
- [ ] Announce deployment completion
- [ ] Update documentation
- [ ] Close change request
- [ ] Archive deployment artifacts

---

## Rollback Checklist

### When to Rollback
- [ ] Critical functionality broken
- [ ] Performance degradation >20%
- [ ] Error rate increased significantly
- [ ] Security vulnerability introduced
- [ ] Data integrity issues

### Rollback Steps
1. [ ] Announce rollback decision
2. [ ] Execute rollback procedure
   ```bash
   helm rollback devsecops-app -n production
   ```
3. [ ] Verify rollback success
4. [ ] Run smoke tests
5. [ ] Monitor system stability
6. [ ] Announce rollback completion
7. [ ] Schedule post-mortem

---

## Security Verification

### Runtime Security
- [ ] Pods running with security context
- [ ] No privileged containers
- [ ] Read-only root filesystem where possible
- [ ] Network policies enforced
- [ ] Service mesh configured (if applicable)

### Access Control
- [ ] RBAC roles properly assigned
- [ ] Service accounts configured
- [ ] No default service account tokens mounted
- [ ] Azure AD integration working

### Secrets Management
- [ ] All secrets in Key Vault
- [ ] Key Vault CSI driver working
- [ ] Secret rotation configured
- [ ] No secrets in environment variables (use Key Vault references)

### Network Security
- [ ] TLS enabled for all ingress
- [ ] Certificate valid and not expiring soon
- [ ] Network policies restrict pod-to-pod traffic
- [ ] NSG rules reviewed

### Monitoring & Logging
- [ ] Application logs flowing to Log Analytics
- [ ] Metrics being collected
- [ ] Alerts configured and tested
- [ ] Defender for Containers active

---

## Performance Verification

### Application Performance
- [ ] Response time within SLA (<500ms for API)
- [ ] Throughput meets requirements
- [ ] No memory leaks detected
- [ ] CPU usage within normal range

### Infrastructure Performance
- [ ] Node CPU usage <70%
- [ ] Node memory usage <80%
- [ ] Disk I/O within limits
- [ ] Network latency acceptable

---

## Compliance Verification

### Audit Requirements
- [ ] All changes logged
- [ ] Approval trail documented
- [ ] Deployment artifacts archived
- [ ] SBOM available

### Data Protection
- [ ] Data encrypted at rest
- [ ] Data encrypted in transit
- [ ] Backup verified
- [ ] Retention policies applied

### Regulatory Compliance
- [ ] ISO 27001 controls met
- [ ] NIST CSF requirements addressed
- [ ] CIS benchmarks followed
- [ ] Privacy requirements met (GDPR, etc.)

---

## Communication Checklist

### Pre-Deployment
- [ ] Deployment announcement sent
- [ ] Expected downtime communicated
- [ ] Contact information provided

### During Deployment
- [ ] Status updates every 30 minutes (for major changes)
- [ ] Issues communicated immediately

### Post-Deployment
- [ ] Completion announcement sent
- [ ] Summary of changes provided
- [ ] Known issues documented

---

## Metrics to Collect

### Deployment Metrics
- Deployment duration
- Time to first successful request
- Number of pods restarted
- Rollback required? (Yes/No)

### Application Metrics
- Request rate
- Error rate
- Response time (p50, p95, p99)
- Availability

### Security Metrics
- Vulnerabilities found in scans
- Security gates passed/failed
- Time to remediate vulnerabilities

---

## Post-Release Review

### Within 24 Hours
- [ ] Review deployment metrics
- [ ] Check for any issues
- [ ] Verify monitoring and alerts
- [ ] Update documentation

### Within 1 Week
- [ ] Conduct retrospective
- [ ] Document lessons learned
- [ ] Update processes if needed
- [ ] Share knowledge with team

---

## Emergency Hotfix Checklist

For critical production issues requiring immediate fix:

- [ ] Incident declared (see [Incident Runbook](incident-runbook.md))
- [ ] Hotfix branch created from production
- [ ] Minimal fix implemented
- [ ] Security scans run (cannot skip)
- [ ] Deploy to staging first (if time permits)
- [ ] Deploy to production
- [ ] Verify fix
- [ ] Post-implementation review scheduled

---

## Tools and Commands

### Verify Deployment
```bash
# Check deployment status
kubectl get deployments -n production

# Check pod status
kubectl get pods -n production

# Check rollout status
kubectl rollout status deployment/devsecops-api -n production

# View recent events
kubectl get events -n production --sort-by='.lastTimestamp'

# Check logs
kubectl logs -f deployment/devsecops-api -n production
```

### Health Checks
```bash
# API health
curl -i https://api.example.com/health

# Check all endpoints
curl https://api.example.com/ready
curl https://api.example.com/metrics
```

### Monitoring
```bash
# View metrics in Azure
az monitor metrics list \
  --resource <resource-id> \
  --metric-names "node_cpu_usage_percentage" \
  --start-time <start> \
  --end-time <end>

# Query logs
az monitor log-analytics query \
  --workspace <workspace-id> \
  --analytics-query "ContainerLog | where TimeGenerated > ago(1h)"
```

---

## Sign-Off

### Deployment Sign-Off

| Role | Name | Signature | Date |
|------|------|-----------|------|
| Developer | | | |
| Team Lead | | | |
| Security Team | | | |
| Operations | | | |

---

## References

- [Change Control Process](change-control.md)
- [Incident Response Runbook](incident-runbook.md)
- [Architecture Documentation](ARCHITECTURE.md)
- [Compliance Mapping](compliance-mapping.md)

---

**Last Updated**: 2026-02-04  
**Version**: 1.0
