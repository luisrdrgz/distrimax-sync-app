# Guía del Sistema de Logging - DistriMax Sync App

## Descripción

El sistema de logging implementado en la aplicación DistriMax Sync App proporciona un registro completo y detallado de todas las operaciones críticas de sincronización. Los logs se almacenan en archivos con rotación diaria automática y se mantienen organizados para facilitar el diagnóstico de problemas.

## Ubicación de los Logs

### Linux/macOS
```
~/Documents/DistriMax_SyncApp/logs/
```

### Windows
```
C:\Users\[usuario]\Documents\DistriMax_SyncApp\logs\
```

## Estructura de Archivos

Los archivos de log siguen el formato de nomenclatura:
```
sync_app_YYYY-MM-DD.log
```

Ejemplos:
- `sync_app_2025-06-30.log`
- `sync_app_2025-07-01.log`

## Características del Sistema

### 1. Rotación Automática
- **Diaria**: Nuevos archivos cada día a las 00:00
- **Por tamaño**: Rotación automática cuando un archivo supera 50MB
- **Limpieza**: Se mantienen solo los últimos 30 días de logs

### 2. Niveles de Log
- **INFO**: Información general de operaciones
- **WARNING**: Advertencias que no impiden el funcionamiento
- **SEVERE**: Errores críticos que requieren atención

### 3. Categorías de Log
- **Application**: Eventos de inicio/fin de aplicación
- **SyncService**: Operaciones de sincronización
- **Database**: Conexiones y consultas MySQL
- **API**: Llamadas HTTP y respuestas
- **Config**: Cambios de configuración
- **SyncOperation**: Detalles específicos de sincronización

## Formato de Entradas

Cada entrada de log sigue este formato:
```
[HH:mm:ss.SSS] NIVEL   [CATEGORIA          ] MENSAJE
```

Ejemplo:
```
[14:30:15.123] INFO    [Application        ] Iniciando Distrimax Sync App
[14:30:16.456] INFO    [Database           ] Connect: Conexión MySQL establecida exitosamente
[14:30:17.789] INFO    [API                ] BulkSync: Sincronización bulk exitosa de 150 productos
[14:30:18.012] ERROR   [SyncService        ] Error durante la sincronización
  Error: Connection timeout
  Stack trace: ...
```

## Uso del Visor de Logs

### Acceso
1. Abrir la aplicación DistriMax Sync App
2. Hacer clic en el botón **"Visor de Logs"** en la barra superior (ícono de documento)

### Funciones Disponibles
- **Selección de archivos**: Dropdown con todos los archivos de log disponibles
- **Actualizar**: Recargar la lista de archivos
- **Recargar**: Actualizar el contenido del archivo seleccionado
- **Copiar**: Copiar todo el contenido al portapapeles
- **Auto-scroll**: Desplazamiento automático al final del archivo
- **Información del sistema**: Estado del logging y estadísticas

### Estado del Sistema
El visor muestra:
- Estado de inicialización del logging
- Directorio de logs actual
- Archivo de log activo
- Tamaño del buffer en memoria
- Número total de archivos
- Plataforma del sistema

## Solución de Problemas

### Error: "Sistema de logging no inicializado"
1. Esperar unos segundos para que se complete la inicialización
2. Hacer clic en "Actualizar" en el visor de logs
3. Si persiste, hacer clic en "Inicializar" (botón naranja)

### No se muestran archivos de log
1. Verificar que la aplicación tenga permisos de escritura en el directorio Documents
2. Ejecutar una sincronización para generar logs
3. Verificar la ubicación del directorio en la información del sistema

### Error de permisos en Linux
```bash
# Dar permisos al directorio de logs
chmod 755 ~/Documents/DistriMax_SyncApp/
chmod 644 ~/Documents/DistriMax_SyncApp/logs/*.log
```

## Logs de Operaciones Importantes

### Inicio de Aplicación
```
[14:30:15.123] INFO    [Application        ] Iniciando Distrimax Sync App
[14:30:15.456] INFO    [LoggingService     ] Sistema de logging iniciado
[14:30:15.789] INFO    [Application        ] Ventana de aplicación inicializada
```

### Sincronización Exitosa
```
[14:30:16.123] INFO    [SyncService        ] Iniciando sincronización MANUAL
[14:30:16.456] INFO    [Database           ] Connect: Conectando a MySQL: localhost:3306
[14:30:17.789] INFO    [Database           ] Query: Obtenidos 150 productos de MySQL
[14:30:18.012] INFO    [API                ] BulkSync: Sincronización bulk exitosa de 150 productos
[14:30:19.345] INFO    [SyncOperation      ] Complete: Sincronización completada exitosamente
```

### Error de Conexión
```
[14:30:16.123] ERROR   [ApiService         ] Error en prueba de conexión API
  Error: Connection refused
[14:30:16.456] ERROR   [SyncService        ] Error en prueba de conexiones
```

## Configuración Avanzada

### Personalizar Directorio de Logs
```dart
// En main.dart, modificar la inicialización:
await LoggingService.instance.initialize(
  customLogPath: '/ruta/personalizada/logs'
);
```

### Ajustar Configuración
En `logging_service.dart`, modificar las constantes:
```dart
static const int maxLogFiles = 30;        // Días de logs a mantener
static const int maxLogFileSize = 50 * 1024 * 1024; // Tamaño máximo por archivo
static const int bufferFlushInterval = 5; // Segundos entre flush
```

## Monitoreo y Mantenimiento

### Limpieza Manual
Los logs se limpian automáticamente, pero se puede hacer manualmente:
```bash
# Eliminar logs de más de 30 días
find ~/Documents/DistriMax_SyncApp/logs/ -name "*.log" -mtime +30 -delete
```

### Análisis de Logs
Para analizar problemas específicos:
```bash
# Buscar errores en el día actual
grep "ERROR\|SEVERE" ~/Documents/DistriMax_SyncApp/logs/sync_app_$(date +%Y-%m-%d).log

# Buscar operaciones de sincronización
grep "SyncOperation" ~/Documents/DistriMax_SyncApp/logs/sync_app_*.log

# Contar sincronizaciones exitosas
grep "Sincronización completada exitosamente" ~/Documents/DistriMax_SyncApp/logs/sync_app_*.log | wc -l
```

## Mejores Prácticas

1. **Revisar logs regularmente** para detectar problemas tempranos
2. **Conservar logs de errores** para análisis posterior
3. **Monitorear el tamaño del directorio** de logs en sistemas con poco espacio
4. **Usar el visor integrado** para diagnóstico en tiempo real
5. **Documentar patrones de error** recurrentes para mejoras futuras

## Integración con Sistemas de Monitoreo

Para sistemas de producción, se recomienda:
- Configurar alertas automáticas para errores críticos
- Integrar con sistemas de log centralizados (ELK, Splunk, etc.)
- Configurar backup automático de logs importantes
- Implementar dashboards de monitoreo en tiempo real