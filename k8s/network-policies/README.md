# Network Policies for AKS

## Default Deny All

**Security Best Practice**: Start with deny-all and explicitly allow required traffic.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

## Allow API to Database

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-to-db
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: devsecops-api
  policyTypes:
  - Egress
  egress:
  # Allow DNS
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: UDP
      port: 53
  # Allow to database
  - to:
    - podSelector:
        matchLabels:
          app: postgresql
    ports:
    - protocol: TCP
      port: 5432
  # Allow to Azure services (Key Vault, etc.)
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 443
```

## Allow Ingress to API

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-ingress-to-api
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: devsecops-api
  policyTypes:
  - Ingress
  ingress:
  # Allow from ingress controller
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 8000
```

## Allow Frontend to API

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: frontend-to-api
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: devsecops-frontend
  policyTypes:
  - Egress
  egress:
  # Allow DNS
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: UDP
      port: 53
  # Allow to API
  - to:
    - podSelector:
        matchLabels:
          app: devsecops-api
    ports:
    - protocol: TCP
      port: 8000
```

## Allow Monitoring (Prometheus)

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-prometheus-scraping
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: devsecops-api
  policyTypes:
  - Ingress
  ingress:
  # Allow Prometheus to scrape metrics
  - from:
    - namespaceSelector:
        matchLabels:
          name: monitoring
      podSelector:
        matchLabels:
          app: prometheus
    ports:
    - protocol: TCP
      port: 8000  # Metrics endpoint
```

## Testing Network Policies

```bash
# Deploy test pod
kubectl run test-pod --image=busybox --rm -it --restart=Never -- sh

# Test connectivity (should fail with network policy)
wget -O- http://devsecops-api:8000/health

# Test DNS (should work)
nslookup kubernetes.default

# Check network policy
kubectl describe networkpolicy default-deny-all -n production
```

## Security Benefits

1. **Zero Trust**: No implicit trust between pods
2. **Micro-segmentation**: Isolate workloads
3. **Reduced Attack Surface**: Limit lateral movement
4. **Compliance**: Meet network isolation requirements
5. **Defense in Depth**: Additional security layer
