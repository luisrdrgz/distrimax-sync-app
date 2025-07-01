enum SyncStatus {
  idle,
  connecting,
  syncing,
  completed,
  error,
}

class SyncResult {
  final bool success;
  final String message;
  final int totalProducts;
  final int createdProducts;
  final int updatedProducts;
  final int errorProducts;
  final List<String> errors;
  final Duration duration;
  final DateTime timestamp;

  SyncResult({
    required this.success,
    required this.message,
    this.totalProducts = 0,
    this.createdProducts = 0,
    this.updatedProducts = 0,
    this.errorProducts = 0,
    this.errors = const [],
    required this.duration,
    required this.timestamp,
  });

  factory SyncResult.success({
    required int totalProducts,
    required int createdProducts,
    required int updatedProducts,
    required Duration duration,
  }) {
    return SyncResult(
      success: true,
      message: 'Sincronización completada exitosamente',
      totalProducts: totalProducts,
      createdProducts: createdProducts,
      updatedProducts: updatedProducts,
      duration: duration,
      timestamp: DateTime.now(),
    );
  }

  factory SyncResult.error({
    required String message,
    int totalProducts = 0,
    int errorProducts = 0,
    List<String> errors = const [],
    required Duration duration,
  }) {
    return SyncResult(
      success: false,
      message: message,
      totalProducts: totalProducts,
      errorProducts: errorProducts,
      errors: errors,
      duration: duration,
      timestamp: DateTime.now(),
    );
  }

  String get summary {
    if (!success) {
      return 'Error: $message';
    }
    
    return 'Total: $totalProducts, Creados: $createdProducts, '
           'Actualizados: $updatedProducts, Errores: $errorProducts';
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'totalProducts': totalProducts,
      'createdProducts': createdProducts,
      'updatedProducts': updatedProducts,
      'errorProducts': errorProducts,
      'errors': errors,
      'duration': duration.inMilliseconds,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SyncResult.fromJson(Map<String, dynamic> json) {
    return SyncResult(
      success: json['success'] as bool,
      message: json['message'] as String,
      totalProducts: json['totalProducts'] as int? ?? 0,
      createdProducts: json['createdProducts'] as int? ?? 0,
      updatedProducts: json['updatedProducts'] as int? ?? 0,
      errorProducts: json['errorProducts'] as int? ?? 0,
      errors: (json['errors'] as List<dynamic>?)?.cast<String>() ?? [],
      duration: Duration(milliseconds: json['duration'] as int? ?? 0),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

class ProductSyncResult {
  final String externalCode;
  final String productName;
  final bool success;
  final String action; // 'created', 'updated', 'error'
  final String? error;

  ProductSyncResult({
    required this.externalCode,
    required this.productName,
    required this.success,
    required this.action,
    this.error,
  });

  @override
  String toString() {
    return '$action: $productName (${success ? 'OK' : error})';
  }
}