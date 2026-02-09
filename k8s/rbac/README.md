# Kubernetes RBAC Configuration

## Developer Role (Read-Only in Production)

This role allows developers to view resources but not modify them in production.

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: developer-readonly
  namespace: production
rules:
- apiGroups: [""]
  resources: ["pods", "pods/log", "services", "configmaps"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets", "statefulsets"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["networking.k8s.io"]
  resources: ["ingresses", "networkpolicies"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developer-readonly-binding
  namespace: production
subjects:
- kind: Group
  name: "developers"  # Azure AD group
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: developer-readonly
  apiGroup: rbac.authorization.k8s.io
```

## Operator Role (Full Access in Staging)

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: operator-full
  namespace: staging
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["*"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: operator-full-binding
  namespace: staging
subjects:
- kind: Group
  name: "operators"  # Azure AD group
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: operator-full
  apiGroup: rbac.authorization.k8s.io
```

## Application Service Account

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: devsecops-app-sa
  namespace: production
automountServiceAccountToken: false  # Security: Don't auto-mount
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: app-role
  namespace: production
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get"]
  resourceNames: ["app-secrets"]  # Only specific secret
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: app-role-binding
  namespace: production
subjects:
- kind: ServiceAccount
  name: devsecops-app-sa
  namespace: production
roleRef:
  kind: Role
  name: app-role
  apiGroup: rbac.authorization.k8s.io
```

## Security Best Practices

1. **Least Privilege**: Grant minimum permissions needed
2. **Namespace Isolation**: Use Role (not ClusterRole) when possible
3. **No Auto-Mount**: Disable `automountServiceAccountToken` unless needed
4. **Azure AD Integration**: Use Azure AD groups for user management
5. **Regular Audits**: Review RBAC permissions quarterly
