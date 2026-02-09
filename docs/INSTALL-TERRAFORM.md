# Instalación Manual de Terraform

## Opción 1: Descarga Directa (Recomendado)

### Paso 1: Descargar Terraform
1. Abre tu navegador y ve a: https://www.terraform.io/downloads
2. Descarga la versión para **Windows AMD64** (archivo .zip)
3. Guarda el archivo en tu carpeta de Descargas

### Paso 2: Extraer y Configurar
1. Extrae el archivo `terraform.zip`
2. Crea una carpeta: `C:\terraform`
3. Copia `terraform.exe` a `C:\terraform`

### Paso 3: Agregar al PATH
1. Abre "Variables de entorno":
   - Presiona `Win + R`
   - Escribe: `sysdm.cpl`
   - Ve a la pestaña "Opciones avanzadas"
   - Click en "Variables de entorno"

2. En "Variables de usuario":
   - Selecciona "Path"
   - Click "Editar"
   - Click "Nuevo"
   - Agrega: `C:\terraform`
   - Click "Aceptar" en todas las ventanas

3. **Cierra y reabre tu terminal**

### Paso 4: Verificar
```powershell
terraform version
```

---

## Opción 2: Usar winget (Windows 11)

```powershell
winget install HashiCorp.Terraform
```

---

## Opción 3: Instalar Chocolatey primero

### Instalar Chocolatey:
```powershell
# Ejecutar PowerShell como Administrador
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

### Luego instalar Terraform:
```powershell
choco install terraform -y
```

---

## Alternativa SIN Terraform

Si prefieres no instalar Terraform, puedes usar **Azure CLI** directamente.
He creado scripts alternativos en `scripts/azure-cli/` que hacen lo mismo.

Ver: `scripts/azure-cli/README.md`
