# Guía de Compilación para Windows - DistriMax Sync App

## Requisitos Previos

### Sistema Operativo
- Windows 10 versión 1803 o superior
- Windows 11 (todas las versiones)

### Herramientas de Desarrollo
1. **Flutter SDK** (3.0 o superior)
   - Descargar desde: https://flutter.dev/docs/get-started/install/windows
   - Agregar al PATH del sistema

2. **Visual Studio 2022** (Community, Professional o Enterprise)
   - Descargar desde: https://visualstudio.microsoft.com/downloads/
   - Durante la instalación, seleccionar:
     - "Desarrollo para escritorio con C++"
     - Windows 10 SDK (10.0.18362 o superior)
     - CMake tools para Windows

3. **Git para Windows**
   - Descargar desde: https://git-scm.com/download/win

## Configuración del Entorno

### 1. Verificar Instalación de Flutter
```powershell
flutter doctor
```

Asegurarse de que no haya errores críticos, especialmente en:
- Flutter (Channel stable)
- Windows Version
- Visual Studio

### 2. Habilitar Soporte para Windows Desktop
```powershell
flutter config --enable-windows-desktop
```

### 3. Clonar el Repositorio
```powershell
git clone [URL_DEL_REPOSITORIO]
cd sync_app
```

## Proceso de Compilación

### Método 1: Script Automatizado (Recomendado)

#### Opción A: Usar PowerShell
```powershell
# Dar permisos de ejecución al script
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Ejecutar el script
.\build_windows.ps1

# Opciones disponibles:
.\build_windows.ps1 -Debug        # Build en modo debug
.\build_windows.ps1 -SkipTests    # Omitir tests
.\build_windows.ps1 -SkipAnalyze  # Omitir análisis
.\build_windows.ps1 -NoZip        # No crear archivo ZIP
```

#### Opción B: Usar Batch
```batch
build_windows.bat
```

### Método 2: Compilación Manual

1. **Instalar dependencias**
   ```powershell
   flutter pub get
   ```

2. **Analizar el código** (opcional)
   ```powershell
   flutter analyze
   ```

3. **Ejecutar tests** (opcional)
   ```powershell
   flutter test
   ```

4. **Compilar en modo Release**
   ```powershell
   flutter build windows --release
   ```

5. **Compilar en modo Debug** (para desarrollo)
   ```powershell
   flutter build windows --debug
   ```

## Ubicación de los Archivos Compilados

### Build Release
```
build\windows\x64\runner\Release\
├── sync_app.exe              # Ejecutable principal
├── flutter_windows.dll        # DLL de Flutter
├── flutter_secure_storage_windows_plugin.dll
├── window_manager_plugin.dll
└── data\                      # Recursos de la aplicación
    ├── app.so
    ├── icudtl.dat
    └── flutter_assets\
```

### Build Debug
```
build\windows\x64\runner\Debug\
└── [Misma estructura que Release]
```

## Distribución

### 1. Preparación Manual

1. Crear una carpeta para distribución
2. Copiar todos los archivos de `build\windows\x64\runner\Release\`
3. Incluir el archivo README con instrucciones

### 2. Distribución Automatizada

Los scripts de build crean automáticamente:
- Carpeta: `dist\DistriMax_SyncApp_Windows\`
- ZIP: `dist\DistriMax_SyncApp_Windows_v[version].zip`

### 3. Requisitos en el Sistema del Usuario

Los usuarios finales necesitan:
- **Visual C++ Redistributable 2019 o superior**
  - Descargar: https://aka.ms/vs/17/release/vc_redist.x64.exe
- **Windows 10 versión 1803 o superior**

## Firma Digital (Opcional)

Para evitar advertencias de Windows Defender:

1. **Obtener un certificado de firma de código**
   - De una autoridad certificadora reconocida
   - O crear un certificado auto-firmado para pruebas

2. **Firmar el ejecutable**
   ```powershell
   signtool sign /f certificado.pfx /p contraseña /t http://timestamp.digicert.com sync_app.exe
   ```

## Solución de Problemas

### Error: "flutter: command not found"
- Verificar que Flutter esté en el PATH
- Reiniciar la terminal después de instalar Flutter

### Error: "Visual Studio not found"
- Instalar Visual Studio 2022 con las cargas de trabajo correctas
- Ejecutar `flutter doctor` para verificar

### Error: "CMake not found"
- Instalar CMake desde Visual Studio Installer
- O descargar desde: https://cmake.org/download/

### Error al ejecutar: "VCRUNTIME140.dll not found"
- Instalar Visual C++ Redistributable
- Incluir el instalador con la distribución

### La aplicación no inicia
1. Verificar logs en: `%USERPROFILE%\Documents\DistriMax_SyncApp\logs\`
2. Ejecutar como administrador
3. Verificar que Windows Defender no esté bloqueando

## Optimización del Ejecutable

### Reducir Tamaño
```powershell
# Compilar con optimizaciones
flutter build windows --release --tree-shake-icons
```

### Configuración de UPX (Opcional)
1. Descargar UPX: https://upx.github.io/
2. Comprimir ejecutable:
   ```powershell
   upx --best --lzma sync_app.exe
   ```

## Integración Continua

### GitHub Actions
```yaml
name: Windows Build

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: windows-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.x'
        
    - name: Install dependencies
      run: flutter pub get
      
    - name: Build Windows
      run: flutter build windows --release
      
    - name: Upload artifacts
      uses: actions/upload-artifact@v3
      with:
        name: windows-release
        path: build/windows/x64/runner/Release/
```

## Actualizaciones

### Actualizar Versión
1. Modificar `pubspec.yaml`:
   ```yaml
   version: 1.0.1+2  # version+buildNumber
   ```

2. Recompilar la aplicación

### Auto-actualización (Futuro)
Considerar implementar:
- Squirrel.Windows para actualizaciones automáticas
- Microsoft Store para distribución y actualizaciones

## Notas Adicionales

- El ejecutable incluye el runtime de Flutter (~15MB)
- La primera ejecución puede ser más lenta mientras se inicializa
- Los logs se guardan en `Documents\DistriMax_SyncApp\logs\`
- La configuración se almacena de forma segura en el registro de Windows