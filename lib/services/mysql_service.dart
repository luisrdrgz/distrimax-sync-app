import 'package:mysql1/mysql1.dart';
import 'package:logging/logging.dart';

import '../models/sync_config_model.dart';
import '../models/product_model.dart';

class MySqlService {
  static final Logger _logger = Logger('MySqlService');
  
  MySqlConnection? _connection;
  SyncConfig? _config;
  ConnectionSettings? _workingSettings;

  Future<bool> testConnection(SyncConfig config) async {
    // Intentar con diferentes configuraciones para máxima compatibilidad
    final configurations = [
      // Configuración moderna (MySQL 8.0+)
      ConnectionSettings(
        host: config.mysqlHost,
        port: config.mysqlPort,
        user: config.mysqlUser,
        password: config.mysqlPassword,
        db: config.mysqlDatabase,
        timeout: const Duration(seconds: 30),
        useCompression: false,
        useSSL: false,
        maxPacketSize: 1024 * 1024, // 1MB
      ),
      // Configuración legacy (MySQL 5.x)
      ConnectionSettings(
        host: config.mysqlHost,
        port: config.mysqlPort,
        user: config.mysqlUser,
        password: config.mysqlPassword,
        db: config.mysqlDatabase,
        timeout: const Duration(seconds: 15),
        useCompression: false,
        useSSL: false,
        maxPacketSize: 512 * 1024, // 512KB
      ),
      // Configuración mínima (para versiones muy antiguas)
      ConnectionSettings(
        host: config.mysqlHost,
        port: config.mysqlPort,
        user: config.mysqlUser,
        password: config.mysqlPassword,
        db: config.mysqlDatabase,
        timeout: const Duration(seconds: 10),
        useCompression: false,
        useSSL: false,
      ),
    ];

    for (int i = 0; i < configurations.length; i++) {
      try {
        _logger.info('Testing MySQL connection (attempt ${i + 1}/${configurations.length}) to ${config.mysqlHost}:${config.mysqlPort}');
        final connection = await MySqlConnection.connect(configurations[i]);
        
        // Verificar con consulta simple
        await connection.query('SELECT 1 as test_value');
        await connection.close();
        
        // Guardar la configuración que funciona
        _workingSettings = configurations[i];
        _logger.info('MySQL connection test successful with configuration ${i + 1}');
        return true;
      } catch (e) {
        _logger.warning('MySQL connection attempt ${i + 1} failed: $e');
        if (i == configurations.length - 1) {
          _logger.severe('All connection attempts failed. Last error: $e');
          
          // Intentar una configuración mínima como último recurso
          try {
            _logger.info('Trying minimal configuration as last resort...');
            final minimalSettings = ConnectionSettings(
              host: config.mysqlHost,
              port: config.mysqlPort,
              user: config.mysqlUser,
              password: config.mysqlPassword,
              db: config.mysqlDatabase,
            );
            final connection = await MySqlConnection.connect(minimalSettings);
            await connection.query('SELECT 1');
            await connection.close();
            _workingSettings = minimalSettings;
            _logger.info('Minimal configuration successful!');
            return true;
          } catch (minimalError) {
            _logger.severe('Even minimal configuration failed: $minimalError');
          }
        }
      }
    }
    
    return false;
  }

  Future<void> connect(SyncConfig config) async {
    try {
      if (_connection != null) {
        await disconnect();
      }

      ConnectionSettings? settingsToUse = _workingSettings;
      
      // Si no tenemos una configuración que sabemos que funciona, probar automáticamente
      if (settingsToUse == null) {
        _logger.info('No working configuration found, testing connection first...');
        if (!await testConnection(config)) {
          throw Exception('Unable to establish connection with any configuration');
        }
        settingsToUse = _workingSettings!;
      }

      _logger.info('Connecting to MySQL database at ${config.mysqlHost}:${config.mysqlPort}');
      _logger.info('Using credentials: user=${config.mysqlUser}, database=${config.mysqlDatabase}');
      _connection = await MySqlConnection.connect(settingsToUse);
      _config = config;
      
      _logger.info('Connected to MySQL database successfully');
    } catch (e) {
      _logger.severe('Failed to connect to MySQL: $e');
      rethrow;
    }
  }

  Future<void> disconnect() async {
    try {
      if (_connection != null) {
        await _connection!.close();
        _connection = null;
        _config = null;
        _logger.info('Disconnected from MySQL database');
      }
    } catch (e) {
      _logger.warning('Error disconnecting from MySQL: $e');
    }
  }

  Future<List<AccountingProduct>> getAllProducts() async {
    if (_connection == null || _config == null) {
      throw Exception('Not connected to MySQL database');
    }

    try {
      _logger.info('Starting to retrieve products from MySQL table: ${_config!.mysqlTable}');
      
      // Asegurar que tenemos una conexión válida
      if (_connection == null) {
        await connect(_config!);
      }

      // Consulta completa sin ORDER BY que estaba causando problemas
      final query = '''
        SELECT 
          CODIGO, CODIGO_BARRAS, PRODUCTO, PVP, CATEGORIA, TIPO, 
          COSTO, IVA, NO_IVA, IRBP, ICE, ICE_VENTA, ICE_SI_NO,
          CODIGO_PRODUCTO, CODIGO_PRODUCTO2, ACTUALIZADA, UNIDAD,
          OBSERVACIONES, CLASE, CONTABILIZAR, CANTIDAD, CANTIDAD_ENTERA_SI_NO
        FROM ${_config!.mysqlTable}
      ''';

      _logger.info('Executing query for all products from ${_config!.mysqlTable}');
      _logger.info('Query: ${query.replaceAll(RegExp(r'\s+'), ' ').trim()}');
      
      final results = await _connection!.query(query);
      final products = <AccountingProduct>[];

      _logger.info('Query executed successfully, processing ${results.length} rows');
      _logger.info('Results type: ${results.runtimeType}');
      
      // El problema es que MySQL está devolviendo resultados pero como OK packet
      // en lugar de ResultSet packet. Vamos a intentar una consulta diferente.
      if (results.isEmpty) {
        _logger.warning('Main query returned empty results, trying simplified query...');
        
        try {
          // Usar una consulta más simple que force un ResultSet
          final simpleQuery = '''SELECT * FROM ${_config!.mysqlTable}''';
          _logger.info('Trying simplified query: $simpleQuery');
          final simpleResults = await _connection!.query(simpleQuery);
          _logger.info('Simplified query returned: ${simpleResults.length} rows');
          
          if (simpleResults.isNotEmpty) {
            _logger.info('Using simplified query results');
            // Procesar los resultados de la consulta simple
            return _processQueryResults(simpleResults);
          }
        } catch (e) {
          _logger.severe('Simplified query failed: $e');
        }
        
        return products; // Retornar lista vacía si todo falla
      }

      return _processQueryResults(results);
    } catch (e) {
      _logger.severe('Failed to retrieve products from MySQL: $e');
      
      // Intentar reconectar en caso de error
      try {
        await disconnect();
        await connect(_config!);
        _logger.info('Reconnected to MySQL after error');
      } catch (reconnectError) {
        _logger.severe('Failed to reconnect: $reconnectError');
      }
      
      rethrow;
    }
  }

  Future<List<AccountingProduct>> getProductsUpdatedAfter(DateTime dateTime) async {
    if (_connection == null || _config == null) {
      throw Exception('Not connected to MySQL database');
    }

    try {
      // Note: This assumes ACTUALIZADA field contains a proper timestamp
      // You might need to adjust this based on the actual format
      // Removed ORDER BY CODIGO to avoid the same issue as in getAllProducts
      final query = '''
        SELECT 
          CODIGO, CODIGO_BARRAS, PRODUCTO, PVP, CATEGORIA, TIPO, 
          COSTO, IVA, NO_IVA, IRBP, ICE, ICE_VENTA, ICE_SI_NO,
          CODIGO_PRODUCTO, CODIGO_PRODUCTO2, ACTUALIZADA, UNIDAD,
          OBSERVACIONES, CLASE, CONTABILIZAR, CANTIDAD, CANTIDAD_ENTERA_SI_NO
        FROM ${_config!.mysqlTable}
        WHERE ACTUALIZADA > ?
      ''';

      final results = await _connection!.query(query, [dateTime]);
      final products = <AccountingProduct>[];

      for (final row in results) {
        try {
          // Crear mapa con nombres de columnas de la consulta
          final Map<String, dynamic> productMap = {
            'CODIGO': row[0],
            'CODIGO_BARRAS': row[1],
            'PRODUCTO': row[2],
            'PVP': row[3],
            'CATEGORIA': row[4],
            'TIPO': row[5],
            'COSTO': row[6],
            'IVA': row[7],
            'NO_IVA': row[8],
            'IRBP': row[9],
            'ICE': row[10],
            'ICE_VENTA': row[11],
            'ICE_SI_NO': row[12],
            'CODIGO_PRODUCTO': row[13],
            'CODIGO_PRODUCTO2': row[14],
            'ACTUALIZADA': row[15],
            'UNIDAD': row[16],
            'OBSERVACIONES': row[17],
            'CLASE': row[18],
            'CONTABILIZAR': row[19],
            'CANTIDAD': row[20],
            'CANTIDAD_ENTERA_SI_NO': row[21],
          };
          
          final product = AccountingProduct.fromMap(productMap);
          products.add(product);
        } catch (e) {
          _logger.warning('Failed to parse product row: $e');
          continue;
        }
      }

      _logger.info('Retrieved ${products.length} updated products from MySQL');
      return products;
    } catch (e) {
      _logger.severe('Failed to retrieve updated products from MySQL: $e');
      rethrow;
    }
  }

  Future<AccountingProduct?> getProductByCode(int codigo) async {
    if (_connection == null || _config == null) {
      throw Exception('Not connected to MySQL database');
    }

    try {
      final query = '''
        SELECT 
          CODIGO, CODIGO_BARRAS, PRODUCTO, PVP, CATEGORIA, TIPO, 
          COSTO, IVA, NO_IVA, IRBP, ICE, ICE_VENTA, ICE_SI_NO,
          CODIGO_PRODUCTO, CODIGO_PRODUCTO2, ACTUALIZADA, UNIDAD,
          OBSERVACIONES, CLASE, CONTABILIZAR, CANTIDAD, CANTIDAD_ENTERA_SI_NO
        FROM ${_config!.mysqlTable}
        WHERE CODIGO = ?
      ''';

      final results = await _connection!.query(query, [codigo]);
      
      if (results.isEmpty) {
        return null;
      }

      // Crear mapa con nombres de columnas de la consulta
      final row = results.first;
      final Map<String, dynamic> productMap = {
        'CODIGO': row[0],
        'CODIGO_BARRAS': row[1],
        'PRODUCTO': row[2],
        'PVP': row[3],
        'CATEGORIA': row[4],
        'TIPO': row[5],
        'COSTO': row[6],
        'IVA': row[7],
        'NO_IVA': row[8],
        'IRBP': row[9],
        'ICE': row[10],
        'ICE_VENTA': row[11],
        'ICE_SI_NO': row[12],
        'CODIGO_PRODUCTO': row[13],
        'CODIGO_PRODUCTO2': row[14],
        'ACTUALIZADA': row[15],
        'UNIDAD': row[16],
        'OBSERVACIONES': row[17],
        'CLASE': row[18],
        'CONTABILIZAR': row[19],
        'CANTIDAD': row[20],
        'CANTIDAD_ENTERA_SI_NO': row[21],
      };

      return AccountingProduct.fromMap(productMap);
    } catch (e) {
      _logger.severe('Failed to retrieve product by code $codigo: $e');
      rethrow;
    }
  }

  Future<int> getProductCount() async {
    if (_connection == null || _config == null) {
      throw Exception('Not connected to MySQL database');
    }

    try {
      final query = 'SELECT COUNT(*) as count FROM ${_config!.mysqlTable}';
      final results = await _connection!.query(query);
      
      if (results.isNotEmpty) {
        return results.first['count'] as int;
      }
      
      return 0;
    } catch (e) {
      _logger.severe('Failed to get product count: $e');
      rethrow;
    }
  }

  Future<bool> updateProductStock(int codigo, int newStock) async {
    if (_connection == null || _config == null) {
      throw Exception('Not connected to MySQL database');
    }

    try {
      final query = '''
        UPDATE ${_config!.mysqlTable} 
        SET CANTIDAD = ?, ACTUALIZADA = NOW()
        WHERE CODIGO = ?
      ''';

      final result = await _connection!.query(query, [newStock.toString(), codigo]);
      
      final success = result.affectedRows! > 0;
      if (success) {
        _logger.info('Updated stock for product $codigo to $newStock');
      } else {
        _logger.warning('No rows affected when updating stock for product $codigo');
      }
      
      return success;
    } catch (e) {
      _logger.severe('Failed to update stock for product $codigo: $e');
      rethrow;
    }
  }

  List<AccountingProduct> _processQueryResults(results) {
    final products = <AccountingProduct>[];
    int rowCount = 0;
    
    for (final row in results) {
      try {
        rowCount++;
        // Log detallado de cada fila para depuración
        _logger.info('Processing row $rowCount: length=${row.length}');
        if (rowCount <= 3) { // Log primeras 3 filas
          _logger.info('Row $rowCount data: ${row.fields}');
          _logger.info('Row $rowCount values: ${row.values}');
        }
        
        // Verificar que la fila tiene los datos esperados (22 campos completos)
        if (row.length < 22) {
          _logger.warning('Row $rowCount has insufficient data: length=${row.length}, expected=22, data=$row');
          continue;
        }
        
        // Mapeo completo de todos los campos de la consulta
        final Map<String, dynamic> productMap = {
          'CODIGO': row[0],
          'CODIGO_BARRAS': row[1],
          'PRODUCTO': row[2],
          'PVP': row[3],
          'CATEGORIA': row[4],
          'TIPO': row[5],
          'COSTO': row[6],
          'IVA': row[7],
          'NO_IVA': row[8],
          'IRBP': row[9],
          'ICE': row[10],
          'ICE_VENTA': row[11],
          'ICE_SI_NO': row[12],
          'CODIGO_PRODUCTO': row[13],
          'CODIGO_PRODUCTO2': row[14],
          'ACTUALIZADA': row[15],
          'UNIDAD': row[16],
          'OBSERVACIONES': row[17],
          'CLASE': row[18],
          'CONTABILIZAR': row[19],
          'CANTIDAD': row[20],
          'CANTIDAD_ENTERA_SI_NO': row[21],
        };
        
        // Log del mapa creado para el primer producto
        if (products.isEmpty) {
          _logger.info('Product map created: $productMap');
        }
        
        final product = AccountingProduct.fromMap(productMap);
        products.add(product);
        
        // Log del primer producto procesado
        if (products.length == 1) {
          _logger.info('First product parsed successfully: ${product.producto}');
        }
      } catch (e) {
        _logger.severe('Failed to parse product row $rowCount: $e');
        _logger.warning('Row data: ${row.fields}');
        _logger.warning('Row values: ${row.values}');
        continue;
      }
    }

    _logger.info('FINAL RESULT: Retrieved ${products.length} products from MySQL from $rowCount total rows processed');
    return products;
  }

  bool get isConnected => _connection != null;

  void dispose() {
    // No hay recursos adicionales que limpiar en MySqlService
    // La conexión se maneja en el método disconnect()
  }
}