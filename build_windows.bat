@echo off
setlocal EnableDelayedExpansion

echo ========================================
echo DistriMax Sync App - Build para Windows
echo ========================================
echo.

REM Verificar que Flutter está instalado
where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Flutter no está instalado o no está en el PATH
    echo Por favor instala Flutter desde: https://flutter.dev/docs/get-started/install/windows
    pause
    exit /b 1
)

REM Mostrar versión de Flutter
echo [INFO] Verificando versión de Flutter...
call flutter --version
echo.

REM Limpiar builds anteriores
echo [INFO] Limpiando builds anteriores...
if exist "build\windows" (
    rmdir /s /q "build\windows"
)
echo.

REM Obtener dependencias
echo [INFO] Instalando dependencias...
call flutter pub get
if %errorlevel% neq 0 (
    echo [ERROR] Error al instalar dependencias
    pause
    exit /b 1
)
echo.

REM Habilitar soporte para Windows
echo [INFO] Habilitando soporte para Windows desktop...
call flutter config --enable-windows-desktop
echo.

REM Analizar código
echo [INFO] Analizando código...
call flutter analyze
if %errorlevel% neq 0 (
    echo [WARNING] Se encontraron problemas en el análisis de código
    echo Continuando con el build...
    echo.
)

REM Ejecutar tests (opcional, continuar si fallan)
echo [INFO] Ejecutando tests...
call flutter test
if %errorlevel% neq 0 (
    echo [WARNING] Algunos tests fallaron
    echo Continuando con el build...
    echo.
)

REM Compilar aplicación
echo [INFO] Compilando aplicación para Windows (Release)...
call flutter build windows --release
if %errorlevel% neq 0 (
    echo [ERROR] Error al compilar la aplicación
    pause
    exit /b 1
)
echo.

REM Crear directorio de distribución
echo [INFO] Preparando distribución...
set DIST_DIR=dist\DistriMax_SyncApp_Windows
if exist "%DIST_DIR%" (
    rmdir /s /q "%DIST_DIR%"
)
mkdir "%DIST_DIR%"

REM Copiar archivos compilados
echo [INFO] Copiando archivos...
xcopy /E /I /Y "build\windows\x64\runner\Release" "%DIST_DIR%"

REM Crear archivo README para distribución
echo [INFO] Creando archivo README...
(
echo DistriMax Sync App para Windows
echo ===============================
echo.
echo Versión: 1.0.0
echo.
echo Requisitos:
echo - Windows 10 o superior
echo - Visual C++ Redistributable 2019 o superior
echo.
echo Instalación:
echo 1. Extraer todos los archivos a una carpeta
echo 2. Ejecutar distrimax_sync.exe
echo.
echo En caso de error "VCRUNTIME140.dll no encontrado":
echo - Descargar e instalar Visual C++ Redistributable desde:
echo   https://aka.ms/vs/17/release/vc_redist.x64.exe
echo.
echo Soporte:
echo Para reportar problemas, contactar al equipo de soporte de DistriMax.
) > "%DIST_DIR%\README.txt"

REM Crear archivo ZIP (si 7-Zip está instalado)
where 7z >nul 2>nul
if %errorlevel% equ 0 (
    echo [INFO] Creando archivo ZIP...
    cd dist
    7z a -tzip "DistriMax_SyncApp_Windows.zip" "DistriMax_SyncApp_Windows\*" -r
    cd ..
    echo [SUCCESS] Archivo ZIP creado: dist\DistriMax_SyncApp_Windows.zip
) else (
    REM Intentar con PowerShell
    echo [INFO] Creando archivo ZIP con PowerShell...
    powershell -Command "Compress-Archive -Path 'dist\DistriMax_SyncApp_Windows\*' -DestinationPath 'dist\DistriMax_SyncApp_Windows.zip' -Force"
    if exist "dist\DistriMax_SyncApp_Windows.zip" (
        echo [SUCCESS] Archivo ZIP creado: dist\DistriMax_SyncApp_Windows.zip
    ) else (
        echo [WARNING] No se pudo crear el archivo ZIP automáticamente
        echo Por favor, comprima manualmente la carpeta: dist\DistriMax_SyncApp_Windows
    )
)

echo.
echo ========================================
echo Build completado exitosamente!
echo ========================================
echo.
echo Archivos generados:
echo - Carpeta: dist\DistriMax_SyncApp_Windows\
if exist "dist\DistriMax_SyncApp_Windows.zip" (
    echo - ZIP: dist\DistriMax_SyncApp_Windows.zip
)
echo.
echo El ejecutable se encuentra en:
echo dist\DistriMax_SyncApp_Windows\distrimax_sync.exe
echo.

REM Preguntar si ejecutar la aplicación
set /p RUN_APP="¿Desea ejecutar la aplicación ahora? (S/N): "
if /i "%RUN_APP%"=="S" (
    echo.
    echo [INFO] Ejecutando aplicación...
    start "" "%DIST_DIR%\sync_app.exe"
)

echo.
pause