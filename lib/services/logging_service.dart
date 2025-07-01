import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

enum LogLevel {
  fine,
  info,
  warning,
  severe,
}

class LoggingService {
  static LoggingService? _instance;
  static LoggingService get instance => _instance ??= LoggingService._();
  
  LoggingService._();

  late Directory _logDirectory;
  late File _currentLogFile;
  late StreamSubscription<LogRecord> _logSubscription;
  DateTime _currentLogDate = DateTime.now();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  final DateFormat _timeFormat = DateFormat('HH:mm:ss.SSS');
  final List<String> _logBuffer = [];
  Timer? _flushTimer;
  bool _isInitialized = false;

  static const int maxLogFiles = 30; // Mantener 30 días de logs
  static const int maxLogFileSize = 50 * 1024 * 1024; // 50MB por archivo
  static const int bufferFlushInterval = 5; // Flush cada 5 segundos

  /// Inicializa el servicio de logging
  Future<void> initialize({String? customLogPath}) async {
    if (_isInitialized) {
      if (kDebugMode) {
        print('LoggingService ya está inicializado');
      }
      return;
    }

    try {
      if (kDebugMode) {
        print('Iniciando LoggingService...');
      }
      
      await _setupLogDirectory(customLogPath);
      await _setupCurrentLogFile();
      _setupLogHandler();
      _startFlushTimer();
      await _cleanOldLogs();
      
      _isInitialized = true;
      
      // Log inicial del sistema
      logInfo('LoggingService', 'Sistema de logging iniciado');
      logInfo('LoggingService', 'Directorio de logs: ${_logDirectory.path}');
      logInfo('LoggingService', 'Archivo actual: ${_currentLogFile.path}');
      logInfo('LoggingService', 'Plataforma: ${Platform.operatingSystem}');
      
      if (kDebugMode) {
        print('LoggingService inicializado exitosamente');
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('Error inicializando LoggingService: $e');
        print('Stack trace: ${StackTrace.current}');
      }
      rethrow;
    }
  }

  /// Configura el directorio de logs
  Future<void> _setupLogDirectory(String? customPath) async {
    if (customPath != null) {
      _logDirectory = Directory(customPath);
    } else {
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final logPath = path.join(appDir.path, 'DistriMax_SyncApp', 'logs');
        _logDirectory = Directory(logPath);
      } catch (e) {
        // Fallback para sistemas donde no está disponible getApplicationDocumentsDirectory
        if (kDebugMode) {
          print('No se pudo obtener el directorio de documentos, usando fallback: $e');
        }
        
        String fallbackPath;
        if (Platform.isLinux || Platform.isMacOS) {
          final home = Platform.environment['HOME'] ?? '/tmp';
          fallbackPath = path.join(home, 'DistriMax_SyncApp', 'logs');
        } else if (Platform.isWindows) {
          final userProfile = Platform.environment['USERPROFILE'] ?? Platform.environment['TEMP'] ?? 'C:\\temp';
          fallbackPath = path.join(userProfile, 'Documents', 'DistriMax_SyncApp', 'logs');
        } else {
          // Fallback genérico
          fallbackPath = path.join(Directory.current.path, 'logs');
        }
        
        _logDirectory = Directory(fallbackPath);
        if (kDebugMode) {
          print('Usando directorio de logs fallback: $fallbackPath');
        }
      }
    }

    if (!await _logDirectory.exists()) {
      await _logDirectory.create(recursive: true);
    }
  }

  /// Configura el archivo de log actual
  Future<void> _setupCurrentLogFile() async {
    final dateStr = _dateFormat.format(_currentLogDate);
    final filename = 'sync_app_$dateStr.log';
    _currentLogFile = File(path.join(_logDirectory.path, filename));

    // Si el archivo no existe, crearlo con encabezado
    if (!await _currentLogFile.exists()) {
      await _currentLogFile.create();
      await _writeLogHeader();
    }
  }

  /// Escribe el encabezado del archivo de log
  Future<void> _writeLogHeader() async {
    final timestamp = DateTime.now().toIso8601String();
    final platform = Platform.operatingSystem;
    final version = Platform.version;
    
    final header = '''
================================================================================
DistriMax Sync App - Log File
================================================================================
Fecha de inicio: $timestamp
Plataforma: $platform
Versión del sistema: $version
Archivo: ${path.basename(_currentLogFile.path)}
================================================================================

''';
    
    await _currentLogFile.writeAsString(header, mode: FileMode.append);
  }

  /// Configura el manejador de logs
  void _setupLogHandler() {
    Logger.root.level = Level.ALL;
    
    _logSubscription = Logger.root.onRecord.listen((record) {
      _handleLogRecord(record);
    });
  }

  /// Procesa un registro de log
  void _handleLogRecord(LogRecord record) {
    try {
      final logEntry = _formatLogEntry(record);
      _addToBuffer(logEntry);
      
      // En modo debug, también imprimir en consola
      if (kDebugMode) {
        print(logEntry);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error procesando log: $e');
      }
    }
  }

  /// Formatea una entrada de log
  String _formatLogEntry(LogRecord record) {
    final time = _timeFormat.format(record.time);
    final level = record.level.name.padRight(7);
    final logger = record.loggerName.padRight(20);
    final message = record.message;
    
    String entry = '[$time] $level [$logger] $message';
    
    // Agregar información de error si existe
    if (record.error != null) {
      entry += '\n  Error: ${record.error}';
    }
    
    // Agregar stack trace si existe
    if (record.stackTrace != null) {
      entry += '\n  Stack trace:\n${record.stackTrace}';
    }
    
    return entry;
  }

  /// Agrega una entrada al buffer
  void _addToBuffer(String entry) {
    _logBuffer.add(entry);
    
    // Si el buffer es muy grande, forzar flush
    if (_logBuffer.length > 100) {
      _flushBuffer();
    }
  }

  /// Inicia el timer para flush automático
  void _startFlushTimer() {
    _flushTimer = Timer.periodic(
      Duration(seconds: bufferFlushInterval),
      (_) => _flushBuffer(),
    );
  }

  /// Escribe el buffer al archivo
  Future<void> _flushBuffer() async {
    if (_logBuffer.isEmpty || !_isInitialized) return;

    try {
      // Verificar si necesitamos rotar el archivo
      await _checkFileRotation();
      
      // Escribir entradas del buffer
      final entries = List<String>.from(_logBuffer);
      _logBuffer.clear();
      
      final content = entries.join('\n') + '\n';
      await _currentLogFile.writeAsString(content, mode: FileMode.append);
      
    } catch (e) {
      if (kDebugMode) {
        print('Error escribiendo logs: $e');
      }
    }
  }

  /// Verifica si necesitamos rotar el archivo de log
  Future<void> _checkFileRotation() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final currentDate = DateTime(_currentLogDate.year, _currentLogDate.month, _currentLogDate.day);
    
    // Rotar si cambió el día o si el archivo es muy grande
    if (today != currentDate || await _isFileTooLarge()) {
      await _rotateLogFile(now);
    }
  }

  /// Verifica si el archivo actual es muy grande
  Future<bool> _isFileTooLarge() async {
    try {
      final stat = await _currentLogFile.stat();
      return stat.size > maxLogFileSize;
    } catch (e) {
      return false;
    }
  }

  /// Rota el archivo de log
  Future<void> _rotateLogFile(DateTime newDate) async {
    try {
      // Flush buffer antes de rotar
      await _flushBuffer();
      
      _currentLogDate = newDate;
      await _setupCurrentLogFile();
      
      logInfo('LoggingService', 'Archivo de log rotado: ${_currentLogFile.path}');
      
    } catch (e) {
      if (kDebugMode) {
        print('Error rotando archivo de log: $e');
      }
    }
  }

  /// Limpia archivos de log antiguos
  Future<void> _cleanOldLogs() async {
    try {
      final files = await _logDirectory.list().toList();
      final logFiles = files
          .whereType<File>()
          .where((f) => path.basename(f.path).startsWith('sync_app_') && 
                       path.basename(f.path).endsWith('.log'))
          .toList();

      // Ordenar por fecha de modificación (más reciente primero)
      logFiles.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      // Eliminar archivos que excedan el límite
      if (logFiles.length > maxLogFiles) {
        final filesToDelete = logFiles.skip(maxLogFiles);
        for (final file in filesToDelete) {
          try {
            await file.delete();
            logInfo('LoggingService', 'Archivo de log eliminado: ${path.basename(file.path)}');
          } catch (e) {
            logWarning('LoggingService', 'No se pudo eliminar archivo: ${path.basename(file.path)} - $e');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error limpiando logs antiguos: $e');
      }
    }
  }

  // Métodos públicos para logging

  /// Log de información
  void logInfo(String source, String message, [Object? error]) {
    Logger(source).info(message, error);
  }

  /// Log de advertencia
  void logWarning(String source, String message, [Object? error]) {
    Logger(source).warning(message, error);
  }

  /// Log de error
  void logError(String source, String message, [Object? error, StackTrace? stackTrace]) {
    Logger(source).severe(message, error, stackTrace);
  }

  /// Log de depuración
  void logDebug(String source, String message, [Object? error]) {
    Logger(source).fine(message, error);
  }

  /// Log para operaciones de sincronización
  void logSync(String operation, String message, [Object? error]) {
    logInfo('SyncOperation', '$operation: $message', error);
  }

  /// Log para operaciones de base de datos
  void logDatabase(String operation, String message, [Object? error]) {
    logInfo('Database', '$operation: $message', error);
  }

  /// Log para operaciones de API
  void logApi(String endpoint, String message, [Object? error]) {
    logInfo('API', '$endpoint: $message', error);
  }

  /// Log para configuración
  void logConfig(String setting, String message, [Object? error]) {
    logInfo('Config', '$setting: $message', error);
  }

  /// Obtiene información del estado actual del logging
  Map<String, dynamic> getStatus() {
    if (!_isInitialized) {
      return {
        'initialized': false,
        'logDirectory': 'No inicializado',
        'currentLogFile': 'No inicializado',
        'currentDate': 'No inicializado',
        'bufferSize': 0,
        'platform': Platform.operatingSystem,
      };
    }
    
    return {
      'initialized': _isInitialized,
      'logDirectory': _logDirectory.path,
      'currentLogFile': _currentLogFile.path,
      'currentDate': _dateFormat.format(_currentLogDate),
      'bufferSize': _logBuffer.length,
      'platform': Platform.operatingSystem,
    };
  }

  /// Obtiene la lista de archivos de log disponibles
  Future<List<FileSystemEntity>> getLogFiles() async {
    if (!_isInitialized) {
      return [];
    }
    
    try {
      final files = await _logDirectory.list().toList();
      return files
          .whereType<File>()
          .where((f) => path.basename(f.path).startsWith('sync_app_') && 
                       path.basename(f.path).endsWith('.log'))
          .toList()
        ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    } catch (e) {
      logError('LoggingService', 'Error obteniendo archivos de log', e);
      return [];
    }
  }

  /// Lee el contenido de un archivo de log específico
  Future<String> readLogFile(String filename) async {
    if (!_isInitialized) {
      return 'Sistema de logging no inicializado';
    }
    
    try {
      final file = File(path.join(_logDirectory.path, filename));
      if (await file.exists()) {
        return await file.readAsString();
      }
      return 'Archivo no encontrado: $filename';
    } catch (e) {
      logError('LoggingService', 'Error leyendo archivo de log: $filename', e);
      return 'Error leyendo archivo: $e';
    }
  }

  /// Fuerza la escritura inmediata del buffer
  Future<void> flush() async {
    await _flushBuffer();
  }

  /// Finaliza el servicio de logging
  Future<void> dispose() async {
    try {
      await flush();
      _flushTimer?.cancel();
      await _logSubscription.cancel();
      _isInitialized = false;
      
      logInfo('LoggingService', 'Servicio de logging finalizado');
    } catch (e) {
      if (kDebugMode) {
        print('Error finalizando LoggingService: $e');
      }
    }
  }
}