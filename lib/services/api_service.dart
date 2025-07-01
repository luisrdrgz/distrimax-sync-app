import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import '../models/sync_config_model.dart';
import '../models/product_model.dart';
import 'logging_service.dart';

class ApiService {
  static final Logger _logger = Logger('ApiService');
  
  SyncConfig? _config;
  late http.Client _client;

  ApiService() {
    _client = http.Client();
  }

  void configure(SyncConfig config) {
    _config = config;
    LoggingService.instance.logConfig('API', 'Configurando API Service - URL: ${config.apiBaseUrl}');
  }

  Future<bool> testConnection() async {
    if (_config == null) {
      LoggingService.instance.logError('ApiService', 'Intento de conexión con servicio no configurado');
      throw Exception('API service not configured');
    }

    try {
      // Use sync token validation endpoint for connection test
      final url = Uri.parse('${_config!.apiBaseUrl}/api/sync-tokens/validate');
      final body = jsonEncode({'token': _config!.apiToken});
      
      // Log the request details
      _logger.info('Testing API connection...');
      LoggingService.instance.logApi('TestConnection', 'Probando conexión API - URL: $url');
      _logger.info('URL: $url');
      _logger.info('Token: ${_config!.apiToken.length > 10 ? '${_config!.apiToken.substring(0, 10)}...' : _config!.apiToken}');
      _logger.info('Request body: $body');
      
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: body,
      ).timeout(const Duration(seconds: 30));

      final success = response.statusCode == 200;
      if (success) {
        _logger.info('API connection test successful - sync token is valid');
        LoggingService.instance.logApi('TestConnection', 'Conexión API exitosa - Token válido');
      } else {
        _logger.warning('API connection test failed: ${response.statusCode} - ${response.body}');
        LoggingService.instance.logApi('TestConnection', 'Conexión API fallida: ${response.statusCode} - ${response.body}');
      }
      
      return success;
    } catch (e) {
      _logger.severe('API connection test failed: $e');
      LoggingService.instance.logError('ApiService', 'Error en prueba de conexión API', e);
      return false;
    }
  }

  Future<BackendProduct?> getProductByExternalCode(String externalCode) async {
    if (_config == null) {
      throw Exception('API service not configured');
    }

    try {
      final url = Uri.parse('${_config!.apiBaseUrl}/api/products/external/$externalCode');
      final response = await _client.get(
        url,
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 404) {
        return null; // Product not found
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return BackendProduct.fromJson(data);
      }

      throw Exception('Failed to get product: ${response.statusCode} - ${response.body}');
    } catch (e) {
      _logger.severe('Failed to get product by external code $externalCode: $e');
      rethrow;
    }
  }

  Future<BackendProduct> createProduct(AccountingProduct accountingProduct) async {
    if (_config == null) {
      throw Exception('API service not configured');
    }

    try {
      final url = Uri.parse('${_config!.apiBaseUrl}/api/products/bulk-sync');
      final productData = accountingProduct.toApiFormat();
      
      // Log para depuración
      _logger.info('Creating product with data: ${jsonEncode(productData)}');
      
      // El endpoint bulk-sync espera un array de productos
      final body = jsonEncode({'products': [productData]});
      
      final response = await _client.post(
        url,
        headers: _getHeaders(),
        body: body,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logger.info('Created product via bulk sync: ${accountingProduct.producto}');
        
        // El endpoint bulk-sync devuelve estadísticas, simular un BackendProduct
        return BackendProduct(
          id: 0, // Será actualizado por el backend
          externalCode: accountingProduct.codigo.toString(),
          name: accountingProduct.producto,
          price: double.tryParse(accountingProduct.pvp ?? '0') ?? 0.0,
          stock: int.tryParse(accountingProduct.cantidad ?? '0') ?? 0,
          categoryId: accountingProduct.categoria ?? 1,
          syncSource: 'accounting',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      throw Exception('Failed to create product: ${response.statusCode} - ${response.body}');
    } catch (e) {
      _logger.severe('Failed to create product ${accountingProduct.producto}: $e');
      rethrow;
    }
  }

  Future<BackendProduct> updateProduct(String externalCode, AccountingProduct accountingProduct) async {
    if (_config == null) {
      throw Exception('API service not configured');
    }

    try {
      final url = Uri.parse('${_config!.apiBaseUrl}/api/products/sync/$externalCode');
      final body = jsonEncode(accountingProduct.toApiFormat());
      
      final response = await _client.put(
        url,
        headers: _getHeaders(),
        body: body,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logger.info('Updated product: ${accountingProduct.producto}');
        return BackendProduct.fromJson(data);
      }

      throw Exception('Failed to update product: ${response.statusCode} - ${response.body}');
    } catch (e) {
      _logger.severe('Failed to update product ${accountingProduct.producto}: $e');
      rethrow;
    }
  }

  Future<void> bulkSyncProducts(List<AccountingProduct> products) async {
    if (_config == null) {
      LoggingService.instance.logError('ApiService', 'Intento de sync bulk con servicio no configurado');
      throw Exception('API service not configured');
    }

    try {
      final url = Uri.parse('${_config!.apiBaseUrl}/api/products/bulk-sync');
      final productsData = products.map((p) => p.toApiFormat()).toList();
      final body = jsonEncode({'products': productsData});
      
      LoggingService.instance.logApi('BulkSync', 'Iniciando bulk sync de ${products.length} productos a $url');
      
      final response = await _client.post(
        url,
        headers: _getHeaders(),
        body: body,
      ).timeout(const Duration(seconds: 120)); // Longer timeout for bulk operations

      if (response.statusCode != 200) {
        LoggingService.instance.logApi('BulkSync', 'Error en bulk sync: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to bulk sync products: ${response.statusCode} - ${response.body}');
      }

      _logger.info('Bulk synced ${products.length} products');
      LoggingService.instance.logApi('BulkSync', 'Bulk sync exitoso de ${products.length} productos');
    } catch (e) {
      _logger.severe('Failed to bulk sync products: $e');
      LoggingService.instance.logError('ApiService', 'Error en bulk sync de productos', e);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getPendingStockMovements() async {
    if (_config == null) {
      throw Exception('API service not configured');
    }

    try {
      final url = Uri.parse('${_config!.apiBaseUrl}/api/sync/movements/pending');
      final response = await _client.get(
        url,
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.cast<Map<String, dynamic>>();
      }

      throw Exception('Failed to get pending movements: ${response.statusCode} - ${response.body}');
    } catch (e) {
      _logger.severe('Failed to get pending stock movements: $e');
      rethrow;
    }
  }

  Future<void> markMovementsSynced(List<int> movementIds) async {
    if (_config == null) {
      throw Exception('API service not configured');
    }

    try {
      final url = Uri.parse('${_config!.apiBaseUrl}/api/sync/movements/mark-synced');
      final body = jsonEncode({'movement_ids': movementIds});
      
      final response = await _client.post(
        url,
        headers: _getHeaders(),
        body: body,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('Failed to mark movements as synced: ${response.statusCode} - ${response.body}');
      }

      _logger.info('Marked ${movementIds.length} movements as synced');
    } catch (e) {
      _logger.severe('Failed to mark movements as synced: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getSyncStatus() async {
    if (_config == null) {
      throw Exception('API service not configured');
    }

    try {
      final url = Uri.parse('${_config!.apiBaseUrl}/api/sync/status');
      final response = await _client.get(
        url,
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      throw Exception('Failed to get sync status: ${response.statusCode} - ${response.body}');
    } catch (e) {
      _logger.severe('Failed to get sync status: $e');
      rethrow;
    }
  }

  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${_config?.apiToken ?? ''}',
      'Accept': 'application/json',
    };
  }

  void dispose() {
    LoggingService.instance.logInfo('ApiService', 'Finalizando ApiService');
    _client.close();
    LoggingService.instance.logInfo('ApiService', 'ApiService finalizado');
  }
}