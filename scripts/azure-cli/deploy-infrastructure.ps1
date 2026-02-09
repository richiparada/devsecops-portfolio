# Deploy DevSecOps Infrastructure using Azure CLI
# Alternative to Terraform for quick deployment

param(
    [string]$ProjectName = "devsecops",
    [string]$Environment = "dev",
    [string]$Location = "eastus"
)

$ErrorActionPreference = "Stop"

Write-Host "================================" -ForegroundColor Cyan
Write-Host "DevSecOps Infrastructure Deployment" -ForegroundColor Cyan
Write-Host "Using Azure CLI (Alternative to Terraform)" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Variables
$resourceGroup = "$ProjectName-$Environment-rg"
$acrName = "$ProjectName$Environment`acr"  # Must be alphanumeric
$aksName = "$ProjectName-$Environment-aks"
$kvName = "$ProjectName-$Environment-kv"
$vnetName = "$ProjectName-$Environment-vnet"
$logWorkspace = "$ProjectName-$Environment-logs"

Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  Resource Group: $resourceGroup" -ForegroundColor White
Write-Host "  Location: $Location" -ForegroundColor White
Write-Host "  ACR: $acrName" -ForegroundColor White
Write-Host "  AKS: $aksName" -ForegroundColor White
Write-Host "  Key Vault: $kvName" -ForegroundColor White
Write-Host ""

$confirm = Read-Host "Proceed with deployment? (yes/no)"
if ($confirm -ne "yes") {
    Write-Host "Deployment cancelled" -ForegroundColor Yellow
    exit 0
}

# Login check
Write-Host ""
Write-Host "Checking Azure login..." -ForegroundColor Yellow
$account = az account show 2>$null | ConvertFrom-Json
if (-not $account) {
    Write-Host "Not logged in. Please login..." -ForegroundColor Yellow
    az login
}

Write-Host "✓ Logged in as: $($account.user.name)" -ForegroundColor Green
Write-Host "✓ Subscription: $($account.name)" -ForegroundColor Green
Write-Host ""

# Create Resource Group
Write-Host "Creating Resource Group..." -ForegroundColor Yellow
az group create `
    --name $resourceGroup `
    --location $Location `
    --tags Project=$ProjectName Environment=$Environment ManagedBy=AzureCLI

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Resource Group created" -ForegroundColor Green
}
else {
    Write-Host "✗ Failed to create Resource Group" -ForegroundColor Red
    exit 1
}

# Create VNet
Write-Host ""
Write-Host "Creating Virtual Network..." -ForegroundColor Yellow
az network vnet create `
    --resource-group $resourceGroup `
    --name $vnetName `
    --address-prefix 10.0.0.0/16 `
    --subnet-name aks-subnet `
    --subnet-prefix 10.0.1.0/24

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ VNet created" -ForegroundColor Green
}
else {
    Write-Host "✗ Failed to create VNet" -ForegroundColor Red
}

# Create Log Analytics Workspace
Write-Host ""
Write-Host "Creating Log Analytics Workspace..." -ForegroundColor Yellow
az monitor log-analytics workspace create `
    --resource-group $resourceGroup `
    --workspace-name $logWorkspace `
    --location $Location

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Log Analytics Workspace created" -ForegroundColor Green
    $workspaceId = az monitor log-analytics workspace show `
        --resource-group $resourceGroup `
        --workspace-name $logWorkspace `
        --query id -o tsv
}
else {
    Write-Host "✗ Failed to create Log Analytics Workspace" -ForegroundColor Red
}

# Create ACR
Write-Host ""
Write-Host "Creating Azure Container Registry..." -ForegroundColor Yellow
az acr create `
    --resource-group $resourceGroup `
    --name $acrName `
    --sku Premium `
    --admin-enabled false

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ ACR created" -ForegroundColor Green
}
else {
    Write-Host "✗ Failed to create ACR" -ForegroundColor Red
}

# Create AKS
Write-Host ""
Write-Host "Creating AKS Cluster (this may take 10-15 minutes)..." -ForegroundColor Yellow
Write-Host "☕ Time for a coffee break!" -ForegroundColor Cyan

$subnetId = az network vnet subnet show `
    --resource-group $resourceGroup `
    --vnet-name $vnetName `
    --name aks-subnet `
    --query id -o tsv

az aks create `
    --resource-group $resourceGroup `
    --name $aksName `
    --node-count 2 `
    --enable-addons monitoring `
    --workspace-resource-id $workspaceId `
    --enable-managed-identity `
    --network-plugin azure `
    --vnet-subnet-id $subnetId `
    --enable-azure-rbac `
    --enable-aad `
    --kubernetes-version 1.28.3 `
    --node-vm-size Standard_D2s_v3 `
    --enable-cluster-autoscaler `
    --min-count 2 `
    --max-count 5

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ AKS Cluster created" -ForegroundColor Green
}
else {
    Write-Host "✗ Failed to create AKS Cluster" -ForegroundColor Red
}

# Attach ACR to AKS
Write-Host ""
Write-Host "Attaching ACR to AKS..." -ForegroundColor Yellow
az aks update `
    --resource-group $resourceGroup `
    --name $aksName `
    --attach-acr $acrName

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ ACR attached to AKS" -ForegroundColor Green
}
else {
    Write-Host "✗ Failed to attach ACR" -ForegroundColor Red
}

# Create Key Vault
Write-Host ""
Write-Host "Creating Key Vault..." -ForegroundColor Yellow
az keyvault create `
    --resource-group $resourceGroup `
    --name $kvName `
    --location $Location `
    --enable-rbac-authorization true `
    --enable-purge-protection true

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Key Vault created" -ForegroundColor Green
}
else {
    Write-Host "✗ Failed to create Key Vault" -ForegroundColor Red
}

# Enable Defender for Containers
Write-Host ""
Write-Host "Enabling Microsoft Defender for Containers..." -ForegroundColor Yellow
az security pricing create `
    --name Containers `
    --tier Standard

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Defender for Containers enabled" -ForegroundColor Green
}
else {
    Write-Host "⚠️  Failed to enable Defender (may require subscription permissions)" -ForegroundColor Yellow
}

# Get AKS credentials
Write-Host ""
Write-Host "Getting AKS credentials..." -ForegroundColor Yellow
az aks get-credentials `
    --resource-group $resourceGroup `
    --name $aksName `
    --overwrite-existing

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ AKS credentials configured" -ForegroundColor Green
}
else {
    Write-Host "✗ Failed to get AKS credentials" -ForegroundColor Red
}

# Verify kubectl access
Write-Host ""
Write-Host "Verifying kubectl access..." -ForegroundColor Yellow
kubectl get nodes

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ kubectl is working!" -ForegroundColor Green
}
else {
    Write-Host "✗ kubectl verification failed" -ForegroundColor Red
}

# Summary
Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Resources created:" -ForegroundColor Yellow
Write-Host "  ✓ Resource Group: $resourceGroup" -ForegroundColor Green
Write-Host "  ✓ VNet: $vnetName" -ForegroundColor Green
Write-Host "  ✓ ACR: $acrName" -ForegroundColor Green
Write-Host "  ✓ AKS: $aksName" -ForegroundColor Green
Write-Host "  ✓ Key Vault: $kvName" -ForegroundColor Green
Write-Host "  ✓ Log Analytics: $logWorkspace" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Verify cluster:" -ForegroundColor White
Write-Host "   kubectl get nodes" -ForegroundColor Cyan
Write-Host ""
Write-Host "2. View resources in Azure Portal:" -ForegroundColor White
Write-Host "   https://portal.azure.com/#@/resource/subscriptions/$($account.id)/resourceGroups/$resourceGroup" -ForegroundColor Cyan
Write-Host ""
Write-Host "3. Deploy application (see docs/deployment.md)" -ForegroundColor White
Write-Host ""

# Save deployment info
$deploymentInfo = @{
    DeployedAt    = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    ResourceGroup = $resourceGroup
    Location      = $Location
    ACR           = $acrName
    AKS           = $aksName
    KeyVault      = $kvName
    VNet          = $vnetName
    LogWorkspace  = $logWorkspace
} | ConvertTo-Json

$deploymentInfo | Out-File -FilePath "deployment-info.json" -Encoding UTF8

Write-Host "✓ Deployment info saved to deployment-info.json" -ForegroundColor Green
Write-Host ""
