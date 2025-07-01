import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import '../models/sync_config_model.dart';
import '../models/product_model.dart';

/// Servicio alternativo que usa HTTP/REST API en lugar de conexión directa MySQL
/// Para resolver problemas de compatibilidad con MySQL 8.0+
class HttpMySqlService {
  static final Logger _logger = Logger('HttpMySqlService');
  
  SyncConfig? _config;
  late http.Client _client;

  HttpMySqlService() {
    _client = http.Client();
  }

  void configure(SyncConfig config) {
    _config = config;
  }

  Future<bool> testConnection() async {
    if (_config == null) {
      throw Exception('HTTP MySQL service not configured');
    }

    try {
      final url = Uri.parse('${_config!.apiBaseUrl}/api/mysql-proxy/test');
      
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_config!.apiToken}',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'host': _config!.mysqlHost,
          'port': _config!.mysqlPort,
          'user': _config!.mysqlUser,
          'password': _config!.mysqlPassword,
          'database': _config!.mysqlDatabase,
          'table': _config!.mysqlTable,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logger.info('HTTP MySQL connection test successful: ${data['message']}');
        return true;
      } else {
        _logger.warning('HTTP MySQL connection test failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      _logger.severe('HTTP MySQL connection test failed: $e');
      return false;
    }
  }

  Future<void> connect() async {
    // Para HTTP service, "conectar" solo significa verificar configuración
    if (_config == null) {
      throw Exception('HTTP MySQL service not configured');
    }
    
    _logger.info('HTTP MySQL service configured for ${_config!.mysqlHost}:${_config!.mysqlPort}');
  }

  Future<void> disconnect() async {
    // No hay conexión persistente que cerrar en HTTP service
    _logger.info('HTTP MySQL service disconnected');
  }

  Future<List<AccountingProduct>> getAllProducts() async {
    if (_config == null) {
      throw Exception('HTTP MySQL service not configured');
    }

    try {
      _logger.info('Retrieving products via HTTP from MySQL table: ${_config!.mysqlTable}');
      
      final url = Uri.parse('${_config!.apiBaseUrl}/api/mysql-proxy/products');
      
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_config!.apiToken}',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'host': _config!.mysqlHost,
          'port': _config!.mysqlPort,
          'user': _config!.mysqlUser,
          'password': _config!.mysqlPassword,
          'database': _config!.mysqlDatabase,
          'table': _config!.mysqlTable,
          'limit': 1000,
        }),
      ).timeout(const Duration(seconds: 120));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final productsList = data['products'] as List;
        
        final products = <AccountingProduct>[];
        for (final productData in productsList) {
          try {
            final product = AccountingProduct.fromMap(productData.cast<String, dynamic>());
            products.add(product);
          } catch (e) {
            _logger.warning('Failed to parse product: $e');
            continue;
          }
        }

        _logger.info('Retrieved ${products.length} products via HTTP');
        return products;
      } else {
        throw Exception('Failed to retrieve products via HTTP: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _logger.severe('Failed to retrieve products via HTTP: $e');
      rethrow;
    }
  }

  Future<List<AccountingProduct>> getProductsUpdatedAfter(DateTime dateTime) async {
    if (_config == null) {
      throw Exception('HTTP MySQL service not configured');
    }

    try {
      final url = Uri.parse('${_config!.apiBaseUrl}/api/mysql-proxy/products/updated');
      
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_config!.apiToken}',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'host': _config!.mysqlHost,
          'port': _config!.mysqlPort,
          'user': _config!.mysqlUser,
          'password': _config!.mysqlPassword,
          'database': _config!.mysqlDatabase,
          'table': _config!.mysqlTable,
          'updated_after': dateTime.toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final productsList = data['products'] as List;
        
        final products = <AccountingProduct>[];
        for (final productData in productsList) {
          try {
            final product = AccountingProduct.fromMap(productData.cast<String, dynamic>());
            products.add(product);
          } catch (e) {
            _logger.warning('Failed to parse updated product: $e');
            continue;
          }
        }

        _logger.info('Retrieved ${products.length} updated products via HTTP');
        return products;
      } else {
        throw Exception('Failed to retrieve updated products via HTTP: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _logger.severe('Failed to retrieve updated products via HTTP: $e');
      rethrow;
    }
  }

  Future<AccountingProduct?> getProductByCode(int codigo) async {
    if (_config == null) {
      throw Exception('HTTP MySQL service not configured');
    }

    try {
      final url = Uri.parse('${_config!.apiBaseUrl}/api/mysql-proxy/products/$codigo');
      
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_config!.apiToken}',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'host': _config!.mysqlHost,
          'port': _config!.mysqlPort,
          'user': _config!.mysqlUser,
          'password': _config!.mysqlPassword,
          'database': _config!.mysqlDatabase,
          'table': _config!.mysqlTable,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AccountingProduct.fromMap(data['product'].cast<String, dynamic>());
      } else if (response.statusCode == 404) {
        return null; // Product not found
      } else {
        throw Exception('Failed to retrieve product by code via HTTP: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _logger.severe('Failed to retrieve product by code $codigo via HTTP: $e');
      rethrow;
    }
  }

  Future<int> getProductCount() async {
    if (_config == null) {
      throw Exception('HTTP MySQL service not configured');
    }

    try {
      final url = Uri.parse('${_config!.apiBaseUrl}/api/mysql-proxy/products/count');
      
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_config!.apiToken}',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'host': _config!.mysqlHost,
          'port': _config!.mysqlPort,
          'user': _config!.mysqlUser,
          'password': _config!.mysqlPassword,
          'database': _config!.mysqlDatabase,
          'table': _config!.mysqlTable,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['count'] as int;
      } else {
        throw Exception('Failed to get product count via HTTP: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _logger.severe('Failed to get product count via HTTP: $e');
      rethrow;
    }
  }

  Future<bool> updateProductStock(int codigo, int newStock) async {
    if (_config == null) {
      throw Exception('HTTP MySQL service not configured');
    }

    try {
      final url = Uri.parse('${_config!.apiBaseUrl}/api/mysql-proxy/products/$codigo/stock');
      
      final response = await _client.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_config!.apiToken}',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'host': _config!.mysqlHost,
          'port': _config!.mysqlPort,
          'user': _config!.mysqlUser,
          'password': _config!.mysqlPassword,
          'database': _config!.mysqlDatabase,
          'table': _config!.mysqlTable,
          'new_stock': newStock,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final success = data['success'] as bool;
        if (success) {
          _logger.info('Updated stock for product $codigo to $newStock via HTTP');
        }
        return success;
      } else {
        throw Exception('Failed to update stock via HTTP: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _logger.severe('Failed to update stock for product $codigo via HTTP: $e');
      rethrow;
    }
  }

  bool get isConnected => _config != null;

  void dispose() {
    _client.close();
  }
}