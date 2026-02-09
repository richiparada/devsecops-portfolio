# Install Terraform on Windows
# This script downloads and installs Terraform

Write-Host "================================" -ForegroundColor Cyan
Write-Host "Installing Terraform" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "⚠️  This script should be run as Administrator for best results" -ForegroundColor Yellow
    Write-Host "   However, we'll try to install for current user..." -ForegroundColor Yellow
    Write-Host ""
}

# Check if Terraform is already installed
try {
    $tfVersion = terraform version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Terraform is already installed: $tfVersion" -ForegroundColor Green
        exit 0
    }
}
catch {
    # Terraform not found, continue with installation
}

Write-Host "Installing Terraform..." -ForegroundColor Yellow
Write-Host ""

# Option 1: Try using Chocolatey (if available)
try {
    $chocoVersion = choco --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Found Chocolatey, using it to install Terraform..." -ForegroundColor Green
        choco install terraform -y
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Terraform installed successfully via Chocolatey" -ForegroundColor Green
            Write-Host ""
            Write-Host "Please close and reopen your terminal, then run:" -ForegroundColor Yellow
            Write-Host "  terraform version" -ForegroundColor Cyan
            exit 0
        }
    }
}
catch {
    # Chocolatey not available
}

# Option 2: Manual installation
Write-Host "Installing Terraform manually..." -ForegroundColor Yellow

# Create temp directory
$tempDir = "$env:TEMP\terraform-install"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

# Download Terraform
$terraformVersion = "1.7.0"
$downloadUrl = "https://releases.hashicorp.com/terraform/${terraformVersion}/terraform_${terraformVersion}_windows_amd64.zip"
$zipFile = "$tempDir\terraform.zip"

Write-Host "Downloading Terraform $terraformVersion..." -ForegroundColor Yellow
try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipFile -UseBasicParsing
    Write-Host "✓ Downloaded successfully" -ForegroundColor Green
}
catch {
    Write-Host "✗ Failed to download Terraform" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please download manually from: https://www.terraform.io/downloads" -ForegroundColor Yellow
    exit 1
}

# Extract
Write-Host "Extracting..." -ForegroundColor Yellow
Expand-Archive -Path $zipFile -DestinationPath $tempDir -Force

# Determine installation directory
if ($isAdmin) {
    $installDir = "C:\Program Files\Terraform"
}
else {
    $installDir = "$env:LOCALAPPDATA\Programs\Terraform"
}

# Create installation directory
New-Item -ItemType Directory -Path $installDir -Force | Out-Null

# Copy terraform.exe
Copy-Item -Path "$tempDir\terraform.exe" -Destination "$installDir\terraform.exe" -Force

Write-Host "✓ Terraform installed to: $installDir" -ForegroundColor Green

# Add to PATH
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -notlike "*$installDir*") {
    Write-Host "Adding Terraform to PATH..." -ForegroundColor Yellow
    [Environment]::SetEnvironmentVariable("Path", "$currentPath;$installDir", "User")
    $env:Path = "$env:Path;$installDir"
    Write-Host "✓ Added to PATH" -ForegroundColor Green
}

# Clean up
Remove-Item -Path $tempDir -Recurse -Force

Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host "Installation Complete!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Verify installation:" -ForegroundColor Yellow
Write-Host "  terraform version" -ForegroundColor Cyan
Write-Host ""
Write-Host "⚠️  Note: You may need to close and reopen your terminal" -ForegroundColor Yellow
Write-Host ""

# Try to verify
try {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    & "$installDir\terraform.exe" version
    Write-Host ""
    Write-Host "✓ Terraform is working!" -ForegroundColor Green
}
catch {
    Write-Host "Please restart your terminal to use Terraform" -ForegroundColor Yellow
}
