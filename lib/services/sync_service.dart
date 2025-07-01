import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import '../config/app_config.dart';
import '../models/sync_config_model.dart';
import '../models/sync_result_model.dart';
import '../models/product_model.dart';
import 'storage_service.dart';
import 'adaptive_mysql_service.dart';
import 'api_service.dart';
import 'logging_service.dart';

class SyncService extends ChangeNotifier {
  static final Logger _logger = Logger('SyncService');

  final StorageService _storageService;
  final AdaptiveMySqlService _mysqlService = AdaptiveMySqlService();
  final ApiService _apiService = ApiService();

  SyncConfig _config = SyncConfig();
  SyncStatus _status = SyncStatus.idle;
  SyncResult? _lastResult;
  Timer? _autoSyncTimer;
  
  String _currentOperation = '';
  double _progress = 0.0;

  SyncService({required StorageService storageService}) 
      : _storageService = storageService {
    _loadConfiguration();
  }

  // Getters
  SyncConfig get config => _config;
  SyncStatus get status => _status;
  SyncResult? get lastResult => _lastResult;
  String get currentOperation => _currentOperation;
  double get progress => _progress;
  bool get isConfigured => _config.isValid;
  bool get isSyncing => _status == SyncStatus.syncing;

  Future<void> _loadConfiguration() async {
    try {
      LoggingService.instance.logInfo('SyncService', 'Cargando configuración de sincronización');
      _config = await _storageService.loadSyncConfig();
      _apiService.configure(_config);
      
      LoggingService.instance.logConfig('AutoSync', 'Configuración cargada - AutoSync: ${_config.autoSyncEnabled}, Válida: ${_config.isValid}');
      
      if (_config.autoSyncEnabled && _config.isValid) {
        _startAutoSync();
      }
      
      notifyListeners();
      _logger.info('Configuration loaded');
      LoggingService.instance.logInfo('SyncService', 'Configuración cargada exitosamente');
    } catch (e) {
      _logger.severe('Failed to load configuration: $e');
      LoggingService.instance.logError('SyncService', 'Error cargando configuración', e);
    }
  }

  Future<void> updateConfiguration(SyncConfig newConfig) async {
    try {
      LoggingService.instance.logConfig('Update', 'Actualizando configuración de sincronización');
      _config = newConfig;
      await _storageService.saveSyncConfig(_config);
      _apiService.configure(_config);
      
      LoggingService.instance.logConfig('AutoSync', 'Nueva configuración - Intervalo: ${_config.syncIntervalMinutes}min, AutoSync: ${_config.autoSyncEnabled}');
      
      // Restart auto sync with new interval
      _stopAutoSync();
      if (_config.autoSyncEnabled && _config.isValid) {
        _startAutoSync();
      }
      
      notifyListeners();
      _logger.info('Configuration updated');
      LoggingService.instance.logInfo('SyncService', 'Configuración actualizada exitosamente');
    } catch (e) {
      _logger.severe('Failed to update configuration: $e');
      LoggingService.instance.logError('SyncService', 'Error actualizando configuración', e);
      rethrow;
    }
  }

  Future<bool> testConnections() async {
    if (!_config.isValid) {
      LoggingService.instance.logWarning('SyncService', 'Configuración inválida para prueba de conexiones');
      return false;
    }

    try {
      LoggingService.instance.logInfo('SyncService', 'Iniciando prueba de conexiones');
      _setStatus(SyncStatus.connecting);
      _setOperation('Probando conexión MySQL...');
      
      LoggingService.instance.logDatabase('TestConnection', 'Probando conexión MySQL - Host: ${_config.mysqlHost}:${_config.mysqlPort}');
      final mysqlSuccess = await _mysqlService.testConnection(_config);
      LoggingService.instance.logDatabase('TestConnection', 'Resultado MySQL: ${mysqlSuccess ? 'EXITOSO' : 'FALLIDO'}');
      
      _setOperation('Probando conexión API...');
      LoggingService.instance.logApi('TestConnection', 'Probando conexión API - URL: ${_config.apiBaseUrl}');
      final apiSuccess = await _apiService.testConnection();
      LoggingService.instance.logApi('TestConnection', 'Resultado API: ${apiSuccess ? 'EXITOSO' : 'FALLIDO'}');

      await _storageService.saveConnectionTestResults(
        mysqlSuccess: mysqlSuccess,
        apiSuccess: apiSuccess,
        mysqlError: mysqlSuccess ? null : 'Error de conexión MySQL',
        apiError: apiSuccess ? null : 'Error de conexión API',
      );

      _setStatus(SyncStatus.idle);
      _setOperation('');
      
      final success = mysqlSuccess && apiSuccess;
      _logger.info('Connection test completed: MySQL=$mysqlSuccess, API=$apiSuccess');
      LoggingService.instance.logInfo('SyncService', 'Prueba de conexiones completada - MySQL: $mysqlSuccess, API: $apiSuccess');
      
      return success;
    } catch (e) {
      _setStatus(SyncStatus.error);
      _setOperation('Error en prueba de conexión');
      _logger.severe('Connection test failed: $e');
      LoggingService.instance.logError('SyncService', 'Error en prueba de conexiones', e);
      return false;
    }
  }

  Future<SyncResult> performSync({bool isManual = false}) async {
    if (!_config.isValid) {
      LoggingService.instance.logError('SyncService', 'Intento de sincronización con configuración inválida');
      throw Exception('Configuración inválida');
    }

    if (_status == SyncStatus.syncing) {
      LoggingService.instance.logWarning('SyncService', 'Intento de sincronización mientras otra ya está en progreso');
      throw Exception('Sincronización ya en progreso');
    }

    final stopwatch = Stopwatch()..start();
    LoggingService.instance.logSync('Start', 'Iniciando sincronización ${isManual ? 'MANUAL' : 'AUTOMÁTICA'}');
    
    try {
      _setStatus(SyncStatus.syncing);
      _setOperation('Iniciando sincronización...');
      _setProgress(0.0);

      // Connect to MySQL
      _setOperation('Conectando a MySQL...');
      LoggingService.instance.logDatabase('Connect', 'Conectando a MySQL: ${_config.mysqlHost}:${_config.mysqlPort}');
      await _mysqlService.connect(_config);
      _setProgress(0.1);
      LoggingService.instance.logDatabase('Connect', 'Conexión MySQL establecida exitosamente');

      // Get products from MySQL
      _setOperation('Obteniendo productos de MySQL...');
      LoggingService.instance.logDatabase('Query', 'Obteniendo todos los productos de la base de datos');
      final accountingProducts = await _mysqlService.getAllProducts();
      _setProgress(0.3);
      LoggingService.instance.logDatabase('Query', 'Obtenidos ${accountingProducts.length} productos de MySQL');

      if (accountingProducts.isEmpty) {
        LoggingService.instance.logWarning('SyncService', 'No se encontraron productos en MySQL para sincronizar');
        throw Exception('No se encontraron productos en MySQL');
      }

      // Process products in batches
      final results = <ProductSyncResult>[];
      final batchSize = AppConfig.maxBatchSize;
      final totalBatches = (accountingProducts.length / batchSize).ceil();
      LoggingService.instance.logSync('Batches', 'Procesando en $totalBatches lotes de máximo $batchSize productos cada uno');

      for (int i = 0; i < totalBatches; i++) {
        final start = i * batchSize;
        final end = (start + batchSize).clamp(0, accountingProducts.length);
        final batch = accountingProducts.sublist(start, end);

        _setOperation('Sincronizando lote ${i + 1} de $totalBatches...');
        LoggingService.instance.logSync('Batch', 'Procesando lote ${i + 1}/$totalBatches con ${batch.length} productos');
        
        final batchResults = await _syncProductBatch(batch);
        results.addAll(batchResults);

        final progress = 0.3 + (0.6 * (i + 1) / totalBatches);
        _setProgress(progress);
        LoggingService.instance.logSync('Progress', 'Completado lote ${i + 1}/$totalBatches - Progreso: ${(progress * 100).toStringAsFixed(1)}%');
      }

      // Update last sync time
      final now = DateTime.now();
      await _storageService.updateLastSyncTime(now);
      _config = _config.copyWith(lastSyncTime: now);
      LoggingService.instance.logSync('Timestamp', 'Tiempo de última sincronización actualizado: ${now.toIso8601String()}');

      stopwatch.stop();

      // Create result
      final syncedCount = results.where((r) => r.action == 'synced').length;
      final createdCount = results.where((r) => r.action == 'created').length;
      final updatedCount = results.where((r) => r.action == 'updated').length;
      final errorCount = results.where((r) => !r.success).length;
      final errors = results.where((r) => !r.success).map((r) => r.error ?? '').toList();
      
      // For bulk sync, all synced products count as "updated" in the summary
      final totalSuccessCount = syncedCount + createdCount + updatedCount;

      LoggingService.instance.logSync('Results', 'Resultados: Total=${accountingProducts.length}, Exitosos=$totalSuccessCount, Errores=$errorCount, Duración=${stopwatch.elapsed.inSeconds}s');

      // Crear el resultado con los errores si los hay
      final result = errorCount > 0 
        ? SyncResult(
            success: true,
            message: 'Sincronización completada con algunos errores',
            totalProducts: accountingProducts.length,
            createdProducts: 0, // Bulk sync no distingue entre creados y actualizados
            updatedProducts: totalSuccessCount, // Todos los exitosos se cuentan como actualizados
            errorProducts: errorCount,
            errors: errors,
            duration: stopwatch.elapsed,
            timestamp: DateTime.now(),
          )
        : SyncResult.success(
            totalProducts: accountingProducts.length,
            createdProducts: 0, // Bulk sync no distingue entre creados y actualizados
            updatedProducts: totalSuccessCount, // Todos los exitosos se cuentan como actualizados
            duration: stopwatch.elapsed,
          );

      await _storageService.saveSyncResult(result);
      _lastResult = result;

      _setStatus(SyncStatus.completed);
      _setOperation('Sincronización completada');
      _setProgress(1.0);

      _logger.info('Sync completed successfully: ${result.summary}');
      LoggingService.instance.logSync('Complete', 'Sincronización completada exitosamente: ${result.summary}');
      
      if (errorCount > 0) {
        LoggingService.instance.logWarning('SyncService', 'Sincronización completada con $errorCount errores');
        for (final error in errors.take(5)) { // Log solo los primeros 5 errores
          LoggingService.instance.logError('SyncBatch', 'Error en sincronización', error);
        }
      }
      
      // Reset to idle after a short delay
      Timer(const Duration(seconds: 3), () {
        if (_status == SyncStatus.completed) {
          _setStatus(SyncStatus.idle);
          _setOperation('');
          _setProgress(0.0);
        }
      });

      return result;

    } catch (e) {
      stopwatch.stop();
      LoggingService.instance.logError('SyncService', 'Error durante la sincronización', e);
      
      final result = SyncResult.error(
        message: e.toString(),
        duration: stopwatch.elapsed,
      );

      await _storageService.saveSyncResult(result);
      _lastResult = result;

      _setStatus(SyncStatus.error);
      _setOperation('Error: ${e.toString()}');
      
      _logger.severe('Sync failed: $e');
      LoggingService.instance.logSync('Failed', 'Sincronización fallida después de ${stopwatch.elapsed.inSeconds}s: $e');
      
      // Reset to idle after showing error
      Timer(const Duration(seconds: 5), () {
        if (_status == SyncStatus.error) {
          _setStatus(SyncStatus.idle);
          _setOperation('');
          _setProgress(0.0);
        }
      });

      return result;

    } finally {
      LoggingService.instance.logDatabase('Disconnect', 'Desconectando de MySQL');
      await _mysqlService.disconnect();
    }
  }

  Future<List<ProductSyncResult>> _syncProductBatch(List<AccountingProduct> products) async {
    final results = <ProductSyncResult>[];

    try {
      // Use bulk sync endpoint instead of individual calls
      _logger.info('Syncing batch of ${products.length} products using bulk sync');
      LoggingService.instance.logApi('BulkSync', 'Iniciando sincronización bulk de ${products.length} productos');
      
      await _apiService.bulkSyncProducts(products);
      
      // Since bulk sync doesn't return individual results, we assume all products were synced successfully
      for (final product in products) {
        results.add(ProductSyncResult(
          externalCode: product.codigo.toString(),
          productName: product.producto,
          success: true,
          action: 'synced', // We don't know if it was created or updated with bulk sync
        ));
      }
      
      _logger.info('Bulk sync completed successfully for ${products.length} products');
      LoggingService.instance.logApi('BulkSync', 'Sincronización bulk exitosa para ${products.length} productos');
      
    } catch (e) {
      // If bulk sync fails, mark all products in the batch as failed
      _logger.severe('Bulk sync failed: $e');
      LoggingService.instance.logError('SyncService', 'Error en sincronización bulk', e);
      
      for (final product in products) {
        results.add(ProductSyncResult(
          externalCode: product.codigo.toString(),
          productName: product.producto,
          success: false,
          action: 'error',
          error: 'Bulk sync failed: $e',
        ));
      }
    }

    return results;
  }

  void _startAutoSync() {
    _stopAutoSync();
    
    if (!_config.autoSyncEnabled || !_config.isValid) {
      LoggingService.instance.logConfig('AutoSync', 'Auto-sync no iniciado - Habilitado: ${_config.autoSyncEnabled}, Válido: ${_config.isValid}');
      return;
    }

    final interval = Duration(minutes: _config.syncIntervalMinutes);
    _autoSyncTimer = Timer.periodic(interval, (timer) {
      if (_status == SyncStatus.idle) {
        _logger.info('Starting automatic sync');
        LoggingService.instance.logSync('AutoStart', 'Iniciando sincronización automática');
        performSync(isManual: false).catchError((e) {
          _logger.warning('Auto sync failed: $e');
          LoggingService.instance.logError('SyncService', 'Error en sincronización automática', e);
          return SyncResult.error(
            message: 'Auto sync failed: $e',
            duration: Duration.zero,
          );
        });
      } else {
        LoggingService.instance.logWarning('SyncService', 'Auto-sync omitido - Estado actual: $_status');
      }
    });

    _logger.info('Auto sync started with interval: ${_config.syncIntervalMinutes} minutes');
    LoggingService.instance.logConfig('AutoSync', 'Auto-sync iniciado con intervalo de ${_config.syncIntervalMinutes} minutos');
  }

  void _stopAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
    _logger.info('Auto sync stopped');
    LoggingService.instance.logConfig('AutoSync', 'Auto-sync detenido');
  }

  Future<List<SyncResult>> getSyncHistory() async {
    return await _storageService.getSyncHistory();
  }

  DateTime? getNextSyncTime() {
    if (!_config.autoSyncEnabled || _config.lastSyncTime == null) {
      return null;
    }
    
    return _config.lastSyncTime!.add(Duration(minutes: _config.syncIntervalMinutes));
  }

  Duration? getTimeUntilNextSync() {
    final nextSync = getNextSyncTime();
    if (nextSync == null) return null;
    
    final now = DateTime.now();
    if (nextSync.isBefore(now)) return Duration.zero;
    
    return nextSync.difference(now);
  }

  void _setStatus(SyncStatus status) {
    _status = status;
    notifyListeners();
  }

  void _setOperation(String operation) {
    _currentOperation = operation;
    notifyListeners();
  }

  void _setProgress(double progress) {
    _progress = progress.clamp(0.0, 1.0);
    notifyListeners();
  }

  @override
  void dispose() {
    LoggingService.instance.logInfo('SyncService', 'Finalizando SyncService');
    _stopAutoSync();
    _mysqlService.disconnect();
    _apiService.dispose();
    super.dispose();
    LoggingService.instance.logInfo('SyncService', 'SyncService finalizado');
  }
}