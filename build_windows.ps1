# DistriMax Sync App - Build Script para Windows (PowerShell)
# Este script compila la aplicación para Windows usando Flutter

param(
    [switch]$SkipTests,
    [switch]$SkipAnalyze,
    [switch]$Debug,
    [switch]$NoZip
)

$ErrorActionPreference = "Stop"

Write-Host "========================================"
Write-Host "DistriMax Sync App - Build para Windows" -ForegroundColor Cyan
Write-Host "========================================"
Write-Host ""

# Función para mostrar mensajes con color
function Write-Info { param($Message) Write-Host "[INFO] $Message" -ForegroundColor Blue }
function Write-Success { param($Message) Write-Host "[SUCCESS] $Message" -ForegroundColor Green }
function Write-Warning { param($Message) Write-Host "[WARNING] $Message" -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }

# Verificar Flutter
Write-Info "Verificando instalación de Flutter..."
try {
    $flutterVersion = flutter --version
    Write-Host $flutterVersion
    Write-Host ""
} catch {
    Write-Error "Flutter no está instalado o no está en el PATH"
    Write-Host "Por favor instala Flutter desde: https://flutter.dev/docs/get-started/install/windows"
    Read-Host "Presiona Enter para salir"
    exit 1
}

# Verificar que estamos en el directorio correcto
if (!(Test-Path "pubspec.yaml")) {
    Write-Error "Este script debe ejecutarse desde el directorio raíz del proyecto Flutter"
    exit 1
}

# Limpiar builds anteriores
Write-Info "Limpiando builds anteriores..."
if (Test-Path "build\windows") {
    Remove-Item -Path "build\windows" -Recurse -Force
}

# Obtener dependencias
Write-Info "Instalando dependencias..."
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Error "Error al instalar dependencias"
    exit 1
}

# Habilitar soporte para Windows
Write-Info "Habilitando soporte para Windows desktop..."
flutter config --enable-windows-desktop

# Analizar código (opcional)
if (!$SkipAnalyze) {
    Write-Info "Analizando código..."
    flutter analyze
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Se encontraron problemas en el análisis de código"
        $response = Read-Host "¿Continuar con el build? (S/N)"
        if ($response -ne "S" -and $response -ne "s") {
            exit 1
        }
    }
}

# Ejecutar tests (opcional)
if (!$SkipTests) {
    Write-Info "Ejecutando tests..."
    flutter test
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Algunos tests fallaron"
        $response = Read-Host "¿Continuar con el build? (S/N)"
        if ($response -ne "S" -and $response -ne "s") {
            exit 1
        }
    }
}

# Determinar tipo de build
$buildType = if ($Debug) { "debug" } else { "release" }
$buildCommand = "flutter build windows --$buildType"

# Compilar aplicación
Write-Info "Compilando aplicación para Windows ($buildType)..."
Invoke-Expression $buildCommand
if ($LASTEXITCODE -ne 0) {
    Write-Error "Error al compilar la aplicación"
    exit 1
}

# Preparar distribución
Write-Info "Preparando distribución..."
$distDir = "dist\DistriMax_SyncApp_Windows"
if (Test-Path $distDir) {
    Remove-Item -Path $distDir -Recurse -Force
}
New-Item -ItemType Directory -Path $distDir -Force | Out-Null

# Copiar archivos compilados
$sourceDir = if ($Debug) { 
    "build\windows\x64\runner\Debug" 
} else { 
    "build\windows\x64\runner\Release" 
}

Write-Info "Copiando archivos desde $sourceDir..."
Copy-Item -Path "$sourceDir\*" -Destination $distDir -Recurse

# Crear README
Write-Info "Creando archivo README..."
@"
DistriMax Sync App para Windows
===============================

Versión: 1.0.0
Build: $buildType

Requisitos del Sistema:
- Windows 10 versión 1803 o superior
- Visual C++ Redistributable 2019 o superior

Instalación:
1. Extraer todos los archivos a una carpeta
2. Ejecutar sync_app.exe

Solución de Problemas:

Si aparece el error "VCRUNTIME140.dll no encontrado":
- Descargar e instalar Visual C++ Redistributable desde:
  https://aka.ms/vs/17/release/vc_redist.x64.exe

Si la aplicación no inicia:
- Verificar que Windows Defender no esté bloqueando la aplicación
- Ejecutar como administrador si es necesario
- Revisar los logs en: %USERPROFILE%\Documents\DistriMax_SyncApp\logs\

Características:
- Sincronización automática y manual de productos
- Conexión directa a MySQL o vía HTTP proxy
- Almacenamiento seguro de credenciales
- Historial completo de sincronizaciones
- Sistema de logging integrado

Soporte:
Para reportar problemas o solicitar ayuda, contactar al equipo de soporte de DistriMax.

"@ | Out-File -FilePath "$distDir\README.txt" -Encoding UTF8

# Obtener información de versión
$version = (Get-Content pubspec.yaml | Select-String "version:" | ForEach-Object { $_.Line.Split(":")[1].Trim() })

# Crear archivo ZIP (opcional)
if (!$NoZip) {
    $zipName = "DistriMax_SyncApp_Windows_v$version.zip"
    $zipPath = "dist\$zipName"
    
    Write-Info "Creando archivo ZIP..."
    
    # Intentar con Compress-Archive (PowerShell nativo)
    try {
        Compress-Archive -Path "$distDir\*" -DestinationPath $zipPath -Force
        Write-Success "Archivo ZIP creado: $zipPath"
    } catch {
        Write-Warning "No se pudo crear el archivo ZIP"
        Write-Host "Por favor, comprima manualmente la carpeta: $distDir"
    }
}

# Mostrar información del build
Write-Host ""
Write-Host "========================================"
Write-Success "Build completado exitosamente!"
Write-Host "========================================"
Write-Host ""
Write-Host "Información del Build:" -ForegroundColor Cyan
Write-Host "- Tipo: $buildType"
Write-Host "- Versión: $version"
Write-Host "- Plataforma: Windows x64"
Write-Host ""
Write-Host "Archivos generados:" -ForegroundColor Cyan
Write-Host "- Carpeta: $distDir\"
if (Test-Path "dist\$zipName") {
    Write-Host "- ZIP: dist\$zipName"
}
Write-Host ""
Write-Host "El ejecutable se encuentra en:"
Write-Host "$distDir\sync_app.exe" -ForegroundColor Green
Write-Host ""

# Preguntar si ejecutar la aplicación
$runApp = Read-Host "¿Desea ejecutar la aplicación ahora? (S/N)"
if ($runApp -eq "S" -or $runApp -eq "s") {
    Write-Info "Ejecutando aplicación..."
    Start-Process "$distDir\sync_app.exe"
}

Write-Host ""
Write-Host "Proceso completado." -ForegroundColor Green