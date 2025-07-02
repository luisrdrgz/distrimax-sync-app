# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

DistriMax Sync App is a Flutter desktop application for synchronizing product data between an accounting system's MySQL database and the DistriMax backend API. The app is designed for Windows, Linux, and macOS desktop platforms.

## Common Development Commands

```bash
# Install dependencies
flutter pub get

# Run the desktop app
flutter run -d linux      # Run on Linux
flutter run -d windows    # Run on Windows  
flutter run -d macos      # Run on macOS

# Build for production
flutter build linux --release    # Build Linux executable
flutter build windows --release  # Build Windows executable
flutter build macos --release    # Build macOS app

# Code quality
flutter analyze           # Run static analysis
flutter test              # Run unit tests

# Build all platforms (Linux only)
./build_all.sh

# Build for Windows (on Windows)
.\build_windows.bat              # Using batch script
.\build_windows.ps1              # Using PowerShell script

# Note: Uses FVM (Flutter Version Manager) if available
# Replace 'flutter' with 'fvm flutter' if using FVM
```

## Windows Build Requirements

### Development Environment
- Windows 10 (1803+) or Windows 11
- Visual Studio 2022 with "Desktop development with C++" workload
- Windows 10 SDK (10.0.18362 or higher)
- CMake (included with Visual Studio)

### Build Scripts
- `build_windows.bat`: Batch script for automated Windows build
- `build_windows.ps1`: PowerShell script with advanced options
- `WINDOWS_BUILD_GUIDE.md`: Comprehensive Windows build documentation

### Distribution
The Windows build creates:
- Executable: `build\windows\x64\runner\Release\sync_app.exe`
- Distribution folder: `dist\DistriMax_SyncApp_Windows\`
- ZIP package: `dist\DistriMax_SyncApp_Windows_v[version].zip`

End users need Visual C++ Redistributable 2019+.

## Architecture & Key Patterns

### Project Structure
```
lib/
├── config/          # App configuration and constants
├── models/          # Data models with MySQL ↔ API mapping
├── services/        # Business logic and external integrations
├── screens/         # UI screens/pages
├── widgets/         # Reusable UI components
└── main.dart        # Application entry point
```

### Service Architecture
- **adaptive_mysql_service.dart**: Intelligent selector between direct MySQL and HTTP proxy connections
- **mysql_service.dart**: Direct MySQL database connection using mysql1 package
- **http_mysql_service.dart**: HTTP-based MySQL access (fallback for restricted environments)
- **api_service.dart**: REST API client for DistriMax backend communication
- **sync_service.dart**: Orchestrates the synchronization process between MySQL and API
- **storage_service.dart**: Secure local storage for credentials and configuration
- **logging_service.dart**: Comprehensive logging system with file rotation and viewer

### Data Flow
1. **Configuration Loading**: App loads saved connection settings from secure storage
2. **MySQL Connection**: Connects to accounting system database (direct or via HTTP proxy)
3. **Data Retrieval**: Queries products table with configurable table name
4. **Data Mapping**: Converts MySQL fields to API format (see field mapping below)
5. **Bulk Sync**: Sends products to `/api/products/bulk-sync` endpoint
6. **Result Processing**: Stores sync results and updates UI
7. **Logging**: All operations logged to daily rotating files

### MySQL ↔ API Field Mapping
| MySQL Field | API Field | Type | Description |
|-------------|-----------|------|-------------|
| CODIGO | external_code | int → string | Unique ID from accounting system |
| CODIGO_BARRAS | barcode | string | Product barcode |
| PRODUCTO | name | string | Product name |
| PVP | price | string → number | Retail price |
| CATEGORIA | category_id | int | Category identifier |
| COSTO | cost | string → number | Product cost |
| IVA | tax_rate | string → number | Tax rate percentage |
| CANTIDAD | stock | string → number | Current inventory |
| UNIDAD | unit | string | Unit of measure |

## Configuration Management

### Storage Locations
- **Credentials**: Encrypted using `flutter_secure_storage`
- **Settings**: Plain text in `shared_preferences`
- **Logs**: `~/Documents/DistriMax_SyncApp/logs/` (platform-specific)

### Required Configuration
1. **MySQL Connection**
   - Host, port, username, password, database name
   - Table name (default: "productos")
   - Optional: Use HTTP proxy for restricted networks

2. **API Settings**
   - Base URL (e.g., https://api-distrimax.comptime.dev)
   - Authentication token (JWT format)

3. **Sync Options**
   - Auto-sync enabled/disabled
   - Interval in minutes (5-1440)

## Logging System

### Features
- **File Rotation**: Daily rotation and 50MB size limit
- **Retention**: 30 days of logs maintained
- **Buffer**: 5-second flush interval for performance
- **Viewer**: Built-in log viewer accessible from UI
- **Levels**: INFO, WARNING, SEVERE

### Log Categories
- `Application`: App lifecycle events
- `SyncService`: Sync operations
- `Database`: MySQL operations
- `API`: HTTP requests/responses
- `Config`: Configuration changes
- `SyncOperation`: Detailed sync progress

## Platform-Specific Considerations

### Linux
- Requires GTK and related dependencies
- Window management via `window_manager` package
- Build output: `build/linux/x64/release/bundle/`

### Windows
- Visual C++ redistributables required
- Window management via `window_manager` package
- Build output: `build/windows/runner/Release/`

### macOS
- Code signing may be required for distribution
- Build output: `build/macos/Build/Products/Release/`

## Testing Strategy

```bash
# Run all tests
flutter test

# Test with coverage
flutter test --coverage

# Specific test file
flutter test test/services/sync_service_test.dart
```

### Test Database Setup
For local testing with MySQL in a container:
```bash
# Start MySQL container
podman run -d \
  --name mysql-distrimax-test \
  -p 3307:3306 \
  -e MYSQL_ROOT_PASSWORD=rootpass \
  -e MYSQL_DATABASE=distrimax_sync_test \
  -e MYSQL_USER=sync_user \
  -e MYSQL_PASSWORD=sync_pass123 \
  mysql:8.0

# Load test data
mysql -h 127.0.0.1 -P 3307 -u sync_user -p'sync_pass123' distrimax_sync_test < test_data.sql
```

## Error Handling Patterns

### Connection Errors
- MySQL: Retry with exponential backoff, fallback to HTTP proxy
- API: Display user-friendly error with retry option
- Network: Check connectivity before operations

### Data Validation
- Empty product names are skipped
- Invalid numeric values default to 0
- Missing required fields logged but don't stop sync

### Sync Failures
- Partial success tracked (e.g., 145/150 products synced)
- Failed items logged with details
- Sync history maintained for debugging

## Security Considerations

- **No hardcoded credentials**: All sensitive data in secure storage
- **HTTPS only**: API connections require SSL/TLS
- **Token validation**: JWT tokens validated before use
- **Input sanitization**: SQL injection prevention in queries
- **Secure storage**: Platform-specific encryption for credentials

## Performance Optimization

- **Batch size**: Products synced in configurable batches
- **Async operations**: Non-blocking UI during sync
- **Connection pooling**: Reuse database connections
- **Log buffering**: Write logs in batches to reduce I/O
- **Memory management**: Stream large result sets