#!/bin/bash

# Script para compilar la aplicación para múltiples plataformas
set -e

echo "=== DistriMax Sync App - Compilación Multi-Plataforma ==="

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para imprimir con color
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar que estamos en el directorio correcto
if [ ! -f "pubspec.yaml" ]; then
    print_error "Este script debe ejecutarse desde el directorio raíz del proyecto Flutter"
    exit 1
fi

# Crear directorio de builds
mkdir -p builds

print_status "Instalando dependencias..."
fvm flutter pub get

print_status "Analizando código..."
fvm flutter analyze

print_status "Ejecutando tests..."
fvm flutter test || print_warning "Algunos tests fallaron, continuando..."

# Compilar para Linux (si estamos en Linux)
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    print_status "Compilando para Linux..."
    fvm flutter build linux --release
    
    if [ -d "build/linux/x64/release/bundle" ]; then
        print_status "Creando paquete Linux..."
        cd build/linux/x64/release/bundle
        tar -czf ../../../../../builds/distrimax-sync-app-linux-x64.tar.gz *
        cd - > /dev/null
        print_success "Build Linux creado: builds/distrimax-sync-app-linux-x64.tar.gz"
    fi
fi

# Compilar para Web
print_status "Compilando para Web..."
fvm flutter build web --release

if [ -d "build/web" ]; then
    print_status "Creando paquete Web..."
    cd build/web
    tar -czf ../../builds/distrimax-sync-app-web.tar.gz *
    cd - > /dev/null
    print_success "Build Web creado: builds/distrimax-sync-app-web.tar.gz"
fi

# Información sobre Windows
print_warning "Para compilar para Windows:"
print_warning "1. Usa GitHub Actions (recomendado): git push y ve a Actions tab"
print_warning "2. Usa una máquina Windows con Flutter instalado"
print_warning "3. Usa Docker con Windows containers (complejo)"

# Crear script de Windows para referencia
cat > builds/build-windows.bat << 'EOF'
@echo off
echo Compilando DistriMax Sync App para Windows...
flutter config --enable-windows-desktop
flutter pub get
flutter analyze
flutter test
flutter build windows --release

echo Creando paquete portable...
cd build\windows\x64\runner\Release
powershell Compress-Archive -Path * -DestinationPath ..\..\..\..\..\builds\distrimax-sync-app-windows.zip -Force
cd ..\..\..\..\..\

echo Build completado: builds\distrimax-sync-app-windows.zip
pause
EOF

print_success "Script de Windows creado: builds/build-windows.bat"

# Mostrar información de builds
echo ""
print_status "Builds disponibles:"
ls -la builds/ || print_warning "No hay builds disponibles"

echo ""
print_status "Información de la aplicación:"
echo "Nombre: DistriMax Sync App"
echo "Versión: $(grep version pubspec.yaml | cut -d' ' -f2)"
echo "Plataformas soportadas: Linux, Windows, Web"

echo ""
print_success "Compilación completada!"

# Instrucciones de distribución
echo ""
print_status "Instrucciones de distribución:"
echo "1. Linux: Extrae el tar.gz y ejecuta el binario"
echo "2. Web: Sirve el contenido del tar.gz con un servidor web"
echo "3. Windows: Ejecuta build-windows.bat en una máquina Windows"