# Distrimax Sync App

Aplicación Flutter para sincronizar productos entre un sistema contable MySQL y el backend de Distrimax.

## Características

- ✅ Conexión a base de datos MySQL
- ✅ Sincronización con API REST de Distrimax
- ✅ Sincronización automática programada
- ✅ Sincronización manual bajo demanda
- ✅ Almacenamiento seguro de credenciales
- ✅ Historial de sincronizaciones
- ✅ Soporte para Windows y Linux

## Requisitos del Sistema

- Flutter SDK 3.0 o superior
- Acceso a base de datos MySQL del sistema contable
- Acceso al API de Distrimax
- Windows 10+ o Linux (Ubuntu 20.04+)

## Instalación

1. Clonar el repositorio:
```bash
git clone <repository-url>
cd sync_app
```

2. Instalar dependencias:
```bash
flutter pub get
```

3. Compilar para la plataforma deseada:

**Windows:**
```bash
flutter build windows --release
```

**Linux:**
```bash
flutter build linux --release
```

## Configuración

### Primera Configuración

1. Abrir la aplicación
2. Ir a Configuración (ícono de engranaje)
3. Completar la información requerida:

**MySQL:**
- Host/IP: Dirección del servidor MySQL
- Puerto: Puerto de MySQL (por defecto 3306)
- Usuario: Usuario de base de datos
- Contraseña: Contraseña de base de datos
- Base de Datos: Nombre de la base de datos
- Tabla: Nombre de la tabla de productos (por defecto "productos")

**API:**
- URL Base del API: URL del backend de Distrimax
- Token de Autenticación: Token JWT para autenticación

**Sincronización:**
- Sincronización Automática: Habilitar/deshabilitar
- Intervalo: Frecuencia en minutos (5-1440)

4. Probar conexiones antes de guardar
5. Guardar configuración

### Estructura de la Base de Datos MySQL

La aplicación espera una tabla con la siguiente estructura:

```sql
CREATE TABLE productos (
  CODIGO int(10) unsigned NOT NULL AUTO_INCREMENT,
  CODIGO_BARRAS varchar(500),
  PRODUCTO varchar(500) NOT NULL,
  PVP varchar(15),
  CATEGORIA int(10) unsigned,
  TIPO varchar(100),
  COSTO varchar(45),
  IVA varchar(45),
  NO_IVA tinyint(1),
  IRBP tinyint(1),
  ICE varchar(50),
  ICE_VENTA varchar(50),
  ICE_SI_NO tinyint(1) unsigned,
  CODIGO_PRODUCTO varchar(150),
  CODIGO_PRODUCTO2 varchar(150),
  ACTUALIZADA varchar(50),
  UNIDAD varchar(45),
  OBSERVACIONES varchar(150),
  CLASE int(10) unsigned,
  CONTABILIZAR tinyint(1),
  CANTIDAD varchar(50),
  CANTIDAD_ENTERA_SI_NO tinyint(3) unsigned,
  PRIMARY KEY (CODIGO)
);
```

## Uso

### Sincronización Manual

1. Asegurarse de que la configuración esté completa
2. Presionar "Sincronizar Ahora" en la pantalla principal
3. Monitorear el progreso en tiempo real

### Sincronización Automática

- Se ejecuta automáticamente según el intervalo configurado
- El tiempo hasta la próxima sincronización se muestra en la pantalla principal
- Se puede habilitar/deshabilitar en la configuración

### Historial

- Ver todas las sincronizaciones anteriores
- Detalles de errores y estadísticas
- Limpiar historial cuando sea necesario

## Mapeo de Campos

| Campo MySQL | Campo Backend | Descripción |
|-------------|---------------|-------------|
| CODIGO | external_code | Identificador único del sistema contable |
| CODIGO_BARRAS | barcode | Código de barras del producto |
| PRODUCTO | name | Nombre del producto |
| PVP | price | Precio de venta al público |
| CATEGORIA | category_id | ID de categoría |
| COSTO | cost | Costo del producto |
| IVA | tax_rate | Tasa de impuesto |
| CANTIDAD | stock | Cantidad en inventario |
| UNIDAD | unit | Unidad de medida |

## Solución de Problemas

### Error de Conexión MySQL

1. Verificar host, puerto, usuario y contraseña
2. Asegurarse de que el servidor MySQL esté ejecutándose
3. Verificar permisos de usuario en la base de datos
4. Comprobar conectividad de red

### Error de Conexión API

1. Verificar URL del API
2. Comprobar token de autenticación
3. Verificar que el backend esté ejecutándose
4. Revisar configuración de red/firewall

### Productos No Sincronizados

1. Verificar que los productos existan en MySQL
2. Revisar logs de error en el historial
3. Comprobar formato de datos en MySQL
4. Verificar permisos del token API

### Performance Lenta

1. Reducir el tamaño del lote (código)
2. Optimizar consultas MySQL
3. Verificar conectividad de red
4. Considerar sincronización incremental

## Arquitectura

```
lib/
├── config/          # Configuración de la aplicación
├── models/          # Modelos de datos
├── services/        # Servicios (MySQL, API, Storage, Sync)
├── screens/         # Pantallas de la UI
├── widgets/         # Widgets reutilizables
└── main.dart        # Punto de entrada
```

## Logging

Los logs se muestran en la consola y incluyen:
- Eventos de sincronización
- Errores de conexión
- Estadísticas de rendimiento
- Operaciones de configuración

## Seguridad

- Credenciales almacenadas de forma segura usando `flutter_secure_storage`
- Comunicación HTTPS con el API
- Validación de entrada de datos
- Tokens de autenticación cifrados

## Desarrollo

### Agregar Nuevas Características

1. Crear modelos en `lib/models/`
2. Implementar servicios en `lib/services/`
3. Crear pantallas en `lib/screens/`
4. Actualizar configuración en `lib/config/`

### Testing

```bash
flutter test
flutter analyze
```

### Build para Distribución

**Windows:**
```bash
flutter build windows --release
# El ejecutable estará en build/windows/runner/Release/
```

**Linux:**
```bash
flutter build linux --release
# El ejecutable estará en build/linux/x64/release/bundle/
```

## Contribuir

1. Fork del repositorio
2. Crear rama de feature
3. Commit de cambios
4. Push a la rama
5. Crear Pull Request

## Licencia

[Especificar licencia]

## Soporte

Para reportar problemas o solicitar características, crear un issue en el repositorio.# distrimax-sync-app
