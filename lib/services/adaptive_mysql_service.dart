import 'package:logging/logging.dart';

import '../models/sync_config_model.dart';
import '../models/product_model.dart';
import 'mysql_service.dart';
import 'http_mysql_service.dart';

/// Servicio adaptivo que usa MySQL directo o HTTP según disponibilidad
/// Resuelve automáticamente problemas de compatibilidad MySQL
class AdaptiveMySqlService {
  static final Logger _logger = Logger('AdaptiveMySqlService');
  
  final MySqlService _directService = MySqlService();
  final HttpMySqlService _httpService = HttpMySqlService();
  
  SyncConfig? _config;
  bool _useHttpMode = false;
  bool _hasTestedDirect = false;

  Future<bool> testConnection(SyncConfig config) async {
    _config = config;
    
    // Probar MySQL directo primero (preferido para bases de datos locales)
    if (!_hasTestedDirect) {
      _logger.info('Testing direct MySQL connection first...');
      final directWorks = await _directService.testConnection(config);
      _hasTestedDirect = true;
      
      if (directWorks) {
        _logger.info('Direct MySQL connection successful');
        _useHttpMode = false;
        return true;
      } else {
        _logger.warning('Direct MySQL connection failed');
      }
    }
    
    // Si está configurado explícitamente para HTTP, usar HTTP
    if (config.useHttpMode) {
      _logger.info('Using HTTP mode as configured (fallback or explicit setting)');
      _httpService.configure(config);
      _useHttpMode = true;
      return await _httpService.testConnection();
    }
    
    // Si MySQL directo falló y no está en modo HTTP, devolver false
    _logger.severe('Both direct MySQL and HTTP mode failed or not configured');
    return false;
  }

  Future<void> connect(SyncConfig config) async {
    _config = config;
    
    if (_useHttpMode || config.useHttpMode) {
      _httpService.configure(config);
      await _httpService.connect();
      _logger.info('Connected using HTTP mode');
    } else {
      await _directService.connect(config);
      _logger.info('Connected using direct MySQL mode');
    }
  }

  Future<void> disconnect() async {
    if (_useHttpMode) {
      await _httpService.disconnect();
    } else {
      await _directService.disconnect();
    }
  }

  Future<List<AccountingProduct>> getAllProducts() async {
    if (_config == null) {
      throw Exception('Service not configured');
    }

    try {
      if (_useHttpMode || _config!.useHttpMode) {
        return await _httpService.getAllProducts();
      } else {
        return await _directService.getAllProducts();
      }
    } catch (e) {
      // Si falla MySQL directo, intentar HTTP como fallback automático
      if (!_useHttpMode && !_config!.useHttpMode) {
        _logger.warning('Direct MySQL failed, trying HTTP fallback: $e');
        _useHttpMode = true;
        _httpService.configure(_config!);
        await _httpService.connect();
        return await _httpService.getAllProducts();
      }
      rethrow;
    }
  }

  Future<List<AccountingProduct>> getProductsUpdatedAfter(DateTime dateTime) async {
    if (_config == null) {
      throw Exception('Service not configured');
    }

    try {
      if (_useHttpMode || _config!.useHttpMode) {
        return await _httpService.getProductsUpdatedAfter(dateTime);
      } else {
        return await _directService.getProductsUpdatedAfter(dateTime);
      }
    } catch (e) {
      if (!_useHttpMode && !_config!.useHttpMode) {
        _logger.warning('Direct MySQL failed, trying HTTP fallback: $e');
        _useHttpMode = true;
        _httpService.configure(_config!);
        await _httpService.connect();
        return await _httpService.getProductsUpdatedAfter(dateTime);
      }
      rethrow;
    }
  }

  Future<AccountingProduct?> getProductByCode(int codigo) async {
    if (_config == null) {
      throw Exception('Service not configured');
    }

    try {
      if (_useHttpMode || _config!.useHttpMode) {
        return await _httpService.getProductByCode(codigo);
      } else {
        return await _directService.getProductByCode(codigo);
      }
    } catch (e) {
      if (!_useHttpMode && !_config!.useHttpMode) {
        _logger.warning('Direct MySQL failed, trying HTTP fallback: $e');
        _useHttpMode = true;
        _httpService.configure(_config!);
        await _httpService.connect();
        return await _httpService.getProductByCode(codigo);
      }
      rethrow;
    }
  }

  Future<int> getProductCount() async {
    if (_config == null) {
      throw Exception('Service not configured');
    }

    try {
      if (_useHttpMode || _config!.useHttpMode) {
        return await _httpService.getProductCount();
      } else {
        return await _directService.getProductCount();
      }
    } catch (e) {
      if (!_useHttpMode && !_config!.useHttpMode) {
        _logger.warning('Direct MySQL failed, trying HTTP fallback: $e');
        _useHttpMode = true;
        _httpService.configure(_config!);
        await _httpService.connect();
        return await _httpService.getProductCount();
      }
      rethrow;
    }
  }

  Future<bool> updateProductStock(int codigo, int newStock) async {
    if (_config == null) {
      throw Exception('Service not configured');
    }

    try {
      if (_useHttpMode || _config!.useHttpMode) {
        return await _httpService.updateProductStock(codigo, newStock);
      } else {
        return await _directService.updateProductStock(codigo, newStock);
      }
    } catch (e) {
      if (!_useHttpMode && !_config!.useHttpMode) {
        _logger.warning('Direct MySQL failed, trying HTTP fallback: $e');
        _useHttpMode = true;
        _httpService.configure(_config!);
        await _httpService.connect();
        return await _httpService.updateProductStock(codigo, newStock);
      }
      rethrow;
    }
  }

  bool get isConnected {
    if (_useHttpMode || (_config?.useHttpMode ?? false)) {
      return _httpService.isConnected;
    } else {
      return _directService.isConnected;
    }
  }

  String get connectionMode {
    if (_useHttpMode || (_config?.useHttpMode ?? false)) {
      return 'HTTP';
    } else {
      return 'Direct MySQL';
    }
  }

  void dispose() {
    _directService.dispose();
    _httpService.dispose();
  }
}