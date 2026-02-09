# DevSecOps Portfolio Project

> **Plataforma Web Segura en Azure AKS con DevSecOps End-to-End**

[![Azure](https://img.shields.io/badge/Azure-AKS-0078D4?logo=microsoft-azure)](https://azure.microsoft.com/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.28-326CE5?logo=kubernetes)](https://kubernetes.io/)
[![Jenkins](https://img.shields.io/badge/Jenkins-CI%2FCD-D24939?logo=jenkins)](https://www.jenkins.io/)
[![Security](https://img.shields.io/badge/Security-DevSecOps-green)](https://www.devsecops.org/)

## 📋 Descripción del Proyecto

Este proyecto demuestra una implementación completa de **DevSecOps** en Microsoft Azure, integrando seguridad en cada etapa del ciclo de vida de desarrollo de software (SDLC). Incluye:

- ✅ **Infraestructura como Código (IaC)** con Terraform
- ✅ **Pipeline CI/CD** con Jenkins y múltiples gates de seguridad
- ✅ **Kubernetes (AKS)** con hardening y políticas de seguridad
- ✅ **Automatización de pruebas de seguridad**: SAST, SCA, DAST, Container Scanning
- ✅ **Gestión de secretos** con Azure Key Vault
- ✅ **Monitoreo y observabilidad** con Azure Monitor
- ✅ **Cumplimiento normativo**: ISO 27001, NIST CSF, CIS Benchmarks
- ✅ **Gestión de riesgos** siguiendo ISO 27005

## 🏗️ Arquitectura

```
┌─────────────────────────────────────────────────────────────────┐
│                         Azure Cloud                              │
│                                                                   │
│  ┌──────────────┐      ┌──────────────┐      ┌──────────────┐  │
│  │   Jenkins    │─────▶│     ACR      │─────▶│     AKS      │  │
│  │   (CI/CD)    │      │  (Registry)  │      │  (K8s Cluster)│  │
│  └──────────────┘      └──────────────┘      └──────────────┘  │
│         │                                              │          │
│         │              ┌──────────────┐               │          │
│         └─────────────▶│  Key Vault   │◀──────────────┘          │
│                        │  (Secrets)   │                          │
│                        └──────────────┘                          │
│                                                                   │
│  ┌──────────────┐      ┌──────────────┐      ┌──────────────┐  │
│  │ Log Analytics│◀─────│    Monitor   │◀─────│   Defender   │  │
│  │              │      │              │      │ for Containers│  │
│  └──────────────┘      └──────────────┘      └──────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## 🛡️ Security Gates en el Pipeline

| Etapa | Herramienta | Propósito |
|-------|-------------|-----------|
| **SAST** | Semgrep | Análisis estático de código (OWASP Top 10) |
| **Secrets Scanning** | Gitleaks | Detección de secretos hardcodeados |
| **SCA** | OWASP Dependency-Check | Vulnerabilidades en dependencias |
| **Container Scanning** | Trivy | Vulnerabilidades en imágenes Docker |
| **IaC Scanning** | Checkov | Validación de Terraform y K8s manifests |
| **SBOM** | Syft | Generación de Software Bill of Materials |
| **DAST** | OWASP ZAP | Pruebas dinámicas en staging |
| **Image Signing** | Cosign | Firma criptográfica de imágenes |

## 🚀 Stack Tecnológico

### Aplicación
- **Backend**: Python 3.11 + FastAPI
- **Frontend**: React 18 + TypeScript
- **Base de datos**: PostgreSQL (Azure Database)

### Infraestructura
- **Cloud**: Microsoft Azure
- **Orquestación**: Azure Kubernetes Service (AKS)
- **Registry**: Azure Container Registry (ACR)
- **Secrets**: Azure Key Vault
- **IaC**: Terraform 1.6+

### CI/CD & Security
- **CI/CD**: Jenkins
- **Security Tools**: Semgrep, Gitleaks, Trivy, OWASP ZAP, Checkov
- **Monitoring**: Azure Monitor, Log Analytics, Defender for Cloud

## 📁 Estructura del Proyecto

```
devsecops-portfolio/
├── app/
│   ├── api/                    # Backend API (Python/FastAPI)
│   │   ├── src/
│   │   ├── tests/
│   │   ├── Dockerfile
│   │   └── requirements.txt
│   └── frontend/               # Frontend (React)
│       ├── src/
│       ├── public/
│       ├── Dockerfile
│       └── package.json
├── terraform/                  # Infraestructura como código
│   ├── main.tf
│   ├── aks.tf
│   ├── acr.tf
│   ├── keyvault.tf
│   ├── monitoring.tf
│   └── security.tf
├── k8s/                        # Kubernetes manifests
│   ├── helm-chart/            # Helm chart de la aplicación
│   ├── rbac/                  # Roles y permisos
│   ├── network-policies/      # Políticas de red
│   ├── pod-security/          # Pod Security Standards
│   └── azure-policy/          # Azure Policy definitions
├── jenkins/
│   ├── Jenkinsfile            # Pipeline principal
│   └── scripts/               # Scripts auxiliares
├── monitoring/
│   ├── dashboards/            # Azure Monitor workbooks
│   ├── alerts/                # Reglas de alertas
│   └── queries/               # KQL queries
├── docs/
│   ├── ARCHITECTURE.md        # Arquitectura detallada
│   ├── compliance-mapping.md  # Mapeo ISO/NIST/CIS
│   ├── incident-runbook.md    # Procedimientos de incidentes
│   ├── change-control.md      # Control de cambios
│   └── release-checklist.md   # Checklist de release
├── evidence/                   # Evidencias para portafolio
│   ├── screenshots/
│   ├── reports/
│   ├── risk-matrix.xlsx
│   └── diagrams/
└── scripts/                    # Scripts de automatización
    ├── setup-azure.sh
    ├── deploy-jenkins.sh
    └── run-security-scans.sh
```

## 🎯 Quick Start

### Prerrequisitos

- Azure CLI instalado y configurado
- Terraform >= 1.6
- kubectl >= 1.28
- Helm >= 3.12
- Docker
- Git

### 1. Clonar el repositorio

```bash
git clone https://github.com/tu-usuario/devsecops-portfolio.git
cd devsecops-portfolio
```

### 2. Configurar Azure

```bash
# Login en Azure
az login

# Crear Service Principal para Terraform
az ad sp create-for-rbac --name "terraform-sp" --role="Contributor" --scopes="/subscriptions/YOUR_SUBSCRIPTION_ID"

# Guardar las credenciales en variables de entorno
export ARM_CLIENT_ID="<appId>"
export ARM_CLIENT_SECRET="<password>"
export ARM_SUBSCRIPTION_ID="<subscription>"
export ARM_TENANT_ID="<tenant>"
```

### 3. Desplegar infraestructura

```bash
cd terraform

# Inicializar Terraform
terraform init

# Revisar el plan
terraform plan

# Aplicar configuración
terraform apply
```

### 4. Configurar kubectl

```bash
# Obtener credenciales del cluster AKS
az aks get-credentials --resource-group devsecops-rg --name devsecops-aks

# Verificar conexión
kubectl get nodes
```

### 5. Desplegar Jenkins

```bash
cd ../scripts
./deploy-jenkins.sh
```

### 6. Configurar el pipeline

1. Acceder a Jenkins: `http://<jenkins-ip>:8080`
2. Crear un nuevo pipeline apuntando a `jenkins/Jenkinsfile`
3. Configurar credenciales de Azure (ACR, AKS)
4. Ejecutar el pipeline

## 🔒 Controles de Seguridad Implementados

### ISO 27001/27002
- **A.9** - Control de acceso (RBAC en AKS)
- **A.10** - Criptografía (Key Vault, TLS)
- **A.12** - Seguridad de operaciones (Logging, monitoring)
- **A.14** - Adquisición, desarrollo y mantenimiento (SAST, SCA, DAST)
- **A.16** - Gestión de incidentes (Runbooks, alertas)

### NIST Cybersecurity Framework
- **Identify**: Asset inventory, risk assessment
- **Protect**: Access control, secrets management, network segmentation
- **Detect**: Continuous monitoring, vulnerability scanning
- **Respond**: Incident runbooks, automated alerts
- **Recover**: Backup strategies, disaster recovery

### CIS Controls
- **CIS 1**: Inventory of assets (Terraform state)
- **CIS 3**: Secure configuration (Checkov, Azure Policy)
- **CIS 6**: Log management (Log Analytics)
- **CIS 8**: Audit logs (Azure Monitor)

## 📊 Gestión de Riesgos

Ver [evidence/risk-matrix.xlsx](evidence/risk-matrix.xlsx) para la matriz completa de riesgos siguiendo ISO 27005.

**Principales activos protegidos:**
- Código fuente (GitHub con branch protection)
- Imágenes de contenedores (ACR con scanning)
- Cluster Kubernetes (AKS con hardening)
- Secretos (Key Vault con rotación)
- Pipeline CI/CD (Jenkins con security gates)

## 📈 Monitoreo y Observabilidad

- **Métricas de aplicación**: Prometheus + Grafana
- **Logs centralizados**: Azure Log Analytics
- **Alertas**: Azure Monitor Alerts
- **Security posture**: Microsoft Defender for Cloud
- **Dashboards**: Azure Workbooks personalizados

## 🧪 Testing

```bash
# Unit tests
cd app/api
pytest --cov

# Security scans (local)
cd ../..
./scripts/run-security-scans.sh

# Integration tests
kubectl apply -f k8s/test/
```

## 📚 Documentación Adicional

- [Arquitectura Detallada](docs/ARCHITECTURE.md)
- [Mapeo de Cumplimiento](docs/compliance-mapping.md)
- [Runbook de Incidentes](docs/incident-runbook.md)
- [Control de Cambios](docs/change-control.md)
- [Checklist de Release](docs/release-checklist.md)

## 🎓 Aprendizajes y Mejores Prácticas

Este proyecto demuestra:

1. **Shift-Left Security**: Integración de seguridad desde las primeras etapas
2. **Defense in Depth**: Múltiples capas de seguridad
3. **Least Privilege**: RBAC estricto en todos los niveles
4. **Immutable Infrastructure**: IaC con Terraform
5. **Zero Trust**: Network policies y segmentación
6. **Continuous Monitoring**: Observabilidad en tiempo real
7. **Compliance as Code**: Políticas automatizadas

## 🤝 Contribuciones

Este es un proyecto de portafolio personal, pero sugerencias son bienvenidas vía Issues.

## 📄 Licencia

MIT License - ver [LICENSE](LICENSE) para detalles.

## 👤 Autor

**Tu Nombre**
- LinkedIn: [tu-perfil](https://linkedin.com/in/tu-perfil)
- Email: tu-email@example.com
- Portfolio: [tu-portfolio.com](https://tu-portfolio.com)

---

**Nota**: Este proyecto es con fines educativos y de demostración. Todas las herramientas de seguridad están configuradas para **uso defensivo únicamente**. No se realizan ataques ni explotación de vulnerabilidades en sistemas externos.
