import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';

import '../config/app_config.dart';
import '../models/sync_config_model.dart';
import '../models/sync_result_model.dart';

class StorageService {
  static final Logger _logger = Logger('StorageService');
  
  late SharedPreferences _prefs;
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    wOptions: WindowsOptions(),
    lOptions: LinuxOptions(),
  );

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _logger.info('Storage service initialized');
    } catch (e) {
      _logger.severe('Failed to initialize storage service: $e');
      rethrow;
    }
  }

  // Configuration methods
  Future<SyncConfig> loadSyncConfig() async {
    try {
      final config = SyncConfig(
        mysqlHost: _prefs.getString(AppConfig.keyMysqlHost) ?? 'localhost',
        mysqlPort: _prefs.getInt(AppConfig.keyMysqlPort) ?? AppConfig.defaultMysqlPort,
        mysqlUser: _prefs.getString(AppConfig.keyMysqlUser) ?? 'sync_user',
        mysqlPassword: await _getSecureString(AppConfig.keyMysqlPassword) ?? 'sync_pass123',
        mysqlDatabase: _prefs.getString(AppConfig.keyMysqlDatabase) ?? 'distrimax_sync_test',
        mysqlTable: _prefs.getString(AppConfig.keyMysqlTable) ?? AppConfig.defaultMysqlTable,
        apiBaseUrl: _prefs.getString(AppConfig.keyApiBaseUrl) ?? 'http://localhost:3000',
        apiToken: await _getSecureString(AppConfig.keyApiToken) ?? 'test_token_123',
        syncIntervalMinutes: _prefs.getInt(AppConfig.keySyncInterval) ?? AppConfig.defaultSyncInterval,
        autoSyncEnabled: _prefs.getBool(AppConfig.keyAutoSyncEnabled) ?? AppConfig.defaultAutoSyncEnabled,
        lastSyncTime: _getDateTime(AppConfig.keyLastSyncTime),
      );
      
      _logger.info('Sync config loaded');
      return config;
    } catch (e) {
      _logger.severe('Failed to load sync config: $e');
      return SyncConfig();
    }
  }

  Future<void> saveSyncConfig(SyncConfig config) async {
    try {
      await _prefs.setString(AppConfig.keyMysqlHost, config.mysqlHost);
      await _prefs.setInt(AppConfig.keyMysqlPort, config.mysqlPort);
      await _prefs.setString(AppConfig.keyMysqlUser, config.mysqlUser);
      await _setSecureString(AppConfig.keyMysqlPassword, config.mysqlPassword);
      await _prefs.setString(AppConfig.keyMysqlDatabase, config.mysqlDatabase);
      await _prefs.setString(AppConfig.keyMysqlTable, config.mysqlTable);
      await _prefs.setString(AppConfig.keyApiBaseUrl, config.apiBaseUrl);
      await _setSecureString(AppConfig.keyApiToken, config.apiToken);
      await _prefs.setInt(AppConfig.keySyncInterval, config.syncIntervalMinutes);
      await _prefs.setBool(AppConfig.keyAutoSyncEnabled, config.autoSyncEnabled);
      
      if (config.lastSyncTime != null) {
        await _setDateTime(AppConfig.keyLastSyncTime, config.lastSyncTime!);
      }
      
      _logger.info('Sync config saved');
    } catch (e) {
      _logger.severe('Failed to save sync config: $e');
      rethrow;
    }
  }

  Future<void> updateLastSyncTime(DateTime dateTime) async {
    try {
      await _setDateTime(AppConfig.keyLastSyncTime, dateTime);
      _logger.info('Last sync time updated: $dateTime');
    } catch (e) {
      _logger.severe('Failed to update last sync time: $e');
    }
  }

  DateTime? getLastSyncTime() {
    return _getDateTime(AppConfig.keyLastSyncTime);
  }

  // Sync history methods
  Future<void> saveSyncResult(SyncResult result) async {
    try {
      final history = await getSyncHistory();
      history.insert(0, result);
      
      // Keep only last 50 results
      if (history.length > 50) {
        history.removeRange(50, history.length);
      }
      
      final jsonList = history.map((r) => r.toJson()).toList();
      await _prefs.setString('sync_history', jsonEncode(jsonList));
      
      _logger.info('Sync result saved to history');
    } catch (e) {
      _logger.severe('Failed to save sync result: $e');
    }
  }

  Future<List<SyncResult>> getSyncHistory() async {
    try {
      final historyJson = _prefs.getString('sync_history');
      if (historyJson == null) return [];
      
      final List<dynamic> jsonList = jsonDecode(historyJson);
      return jsonList.map((json) => SyncResult.fromJson(json)).toList();
    } catch (e) {
      _logger.severe('Failed to load sync history: $e');
      return [];
    }
  }

  Future<void> clearSyncHistory() async {
    try {
      await _prefs.remove('sync_history');
      _logger.info('Sync history cleared');
    } catch (e) {
      _logger.severe('Failed to clear sync history: $e');
    }
  }

  // Test connection results
  Future<void> saveConnectionTestResults({
    required bool mysqlSuccess,
    required bool apiSuccess,
    String? mysqlError,
    String? apiError,
  }) async {
    try {
      final results = {
        'mysql_success': mysqlSuccess,
        'api_success': apiSuccess,
        'mysql_error': mysqlError,
        'api_error': apiError,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      await _prefs.setString('connection_test_results', jsonEncode(results));
      _logger.info('Connection test results saved');
    } catch (e) {
      _logger.severe('Failed to save connection test results: $e');
    }
  }

  Map<String, dynamic>? getConnectionTestResults() {
    try {
      final resultsJson = _prefs.getString('connection_test_results');
      if (resultsJson == null) return null;
      
      return jsonDecode(resultsJson);
    } catch (e) {
      _logger.severe('Failed to load connection test results: $e');
      return null;
    }
  }

  // Private helper methods
  Future<String?> _getSecureString(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (e) {
      _logger.warning('Failed to read secure string for key $key: $e');
      // Fallback: intentar leer de SharedPreferences con prefijo "fallback_"
      final fallbackKey = 'fallback_$key';
      final fallbackValue = _prefs.getString(fallbackKey);
      if (fallbackValue != null) {
        _logger.info('Using fallback storage for key $key');
      }
      return fallbackValue;
    }
  }

  Future<void> _setSecureString(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
      // Si funciona, eliminar cualquier valor fallback
      await _prefs.remove('fallback_$key');
    } catch (e) {
      _logger.severe('Failed to write secure string for key $key: $e');
      // Fallback: guardar en SharedPreferences con prefijo "fallback_"
      _logger.warning('Using fallback storage for key $key due to secure storage error');
      final fallbackKey = 'fallback_$key';
      await _prefs.setString(fallbackKey, value);
      // No lanzar excepción para permitir que la aplicación continúe
    }
  }

  DateTime? _getDateTime(String key) {
    try {
      final dateTimeString = _prefs.getString(key);
      if (dateTimeString == null) return null;
      return DateTime.parse(dateTimeString);
    } catch (e) {
      _logger.warning('Failed to parse datetime for key $key: $e');
      return null;
    }
  }

  Future<void> _setDateTime(String key, DateTime dateTime) async {
    try {
      await _prefs.setString(key, dateTime.toIso8601String());
    } catch (e) {
      _logger.severe('Failed to save datetime for key $key: $e');
      rethrow;
    }
  }

  // Clear all data
  Future<void> clearAllData() async {
    try {
      await _prefs.clear();
      try {
        await _secureStorage.deleteAll();
      } catch (secureStorageError) {
        _logger.warning('Failed to clear secure storage: $secureStorageError');
        // Continuar de todos modos - los datos fallback ya se limpiaron con _prefs.clear()
      }
      _logger.info('All data cleared');
    } catch (e) {
      _logger.severe('Failed to clear all data: $e');
      rethrow;
    }
  }
}