class AccountingProduct {
  final int codigo;
  final String? codigoBarras;
  final String producto;
  final String? pvp;
  final int? categoria;
  final String? tipo;
  final String? costo;
  final String? iva;
  final int? noIva;
  final int? irbp;
  final String? ice;
  final String? iceVenta;
  final int? iceSiNo;
  final String? codigoProducto;
  final String? codigoProducto2;
  final String? actualizada;
  final String? unidad;
  final String? observaciones;
  final int? clase;
  final int? contabilizar;
  final String? cantidad;
  final int? cantidadEnteraSiNo;

  AccountingProduct({
    required this.codigo,
    this.codigoBarras,
    required this.producto,
    this.pvp,
    this.categoria,
    this.tipo,
    this.costo,
    this.iva,
    this.noIva,
    this.irbp,
    this.ice,
    this.iceVenta,
    this.iceSiNo,
    this.codigoProducto,
    this.codigoProducto2,
    this.actualizada,
    this.unidad,
    this.observaciones,
    this.clase,
    this.contabilizar,
    this.cantidad,
    this.cantidadEnteraSiNo,
  });

  factory AccountingProduct.fromMap(Map<String, dynamic> map) {
    // Función auxiliar para obtener valores de forma segura
    T? _safeGet<T>(String key, T Function(dynamic) converter) {
      try {
        final value = map[key];
        if (value == null) return null;
        return converter(value);
      } catch (e) {
        return null;
      }
    }

    // Campos obligatorios con valores por defecto si fallan
    late int codigo;
    late String producto;
    
    try {
      codigo = map['CODIGO'] as int;
    } catch (e) {
      // Intentar como string y convertir
      try {
        codigo = int.parse(map['CODIGO'].toString());
      } catch (e2) {
        codigo = 0; // Valor por defecto
      }
    }
    
    try {
      producto = map['PRODUCTO'] as String;
    } catch (e) {
      producto = map['PRODUCTO']?.toString() ?? 'Producto sin nombre';
    }

    return AccountingProduct(
      codigo: codigo,
      codigoBarras: _safeGet('CODIGO_BARRAS', (v) => v.toString()),
      producto: producto,
      pvp: _safeGet('PVP', (v) => v.toString()),
      categoria: _safeGet<int>('CATEGORIA', (v) => v is int ? v : (int.tryParse(v.toString()) ?? 0)),
      tipo: _safeGet('TIPO', (v) => v.toString()),
      costo: _safeGet('COSTO', (v) => v.toString()),
      iva: _safeGet('IVA', (v) => v.toString()),
      noIva: _safeGet<int>('NO_IVA', (v) => v is int ? v : (int.tryParse(v.toString()) ?? 0)),
      irbp: _safeGet<int>('IRBP', (v) => v is int ? v : (int.tryParse(v.toString()) ?? 0)),
      ice: _safeGet('ICE', (v) => v.toString()),
      iceVenta: _safeGet('ICE_VENTA', (v) => v.toString()),
      iceSiNo: _safeGet<int>('ICE_SI_NO', (v) => v is int ? v : (int.tryParse(v.toString()) ?? 0)),
      codigoProducto: _safeGet('CODIGO_PRODUCTO', (v) => v.toString()),
      codigoProducto2: _safeGet('CODIGO_PRODUCTO2', (v) => v.toString()),
      actualizada: _safeGet('ACTUALIZADA', (v) => v.toString()),
      unidad: _safeGet('UNIDAD', (v) => v.toString()),
      observaciones: _safeGet('OBSERVACIONES', (v) => v.toString()),
      clase: _safeGet<int>('CLASE', (v) => v is int ? v : (int.tryParse(v.toString()) ?? 0)),
      contabilizar: _safeGet<int>('CONTABILIZAR', (v) => v is int ? v : (int.tryParse(v.toString()) ?? 1)),
      cantidad: _safeGet('CANTIDAD', (v) => v.toString()),
      cantidadEnteraSiNo: _safeGet<int>('CANTIDAD_ENTERA_SI_NO', (v) => v is int ? v : (int.tryParse(v.toString()) ?? 0)),
    );
  }

  // Convert to format expected by Distrimax API
  Map<String, dynamic> toApiFormat() {
    // Asegurar que los campos requeridos tengan valores válidos
    final name = producto.isNotEmpty ? producto : 'Producto ${codigo}';
    final price = _parseDecimal(pvp, defaultValue: 1.0) ?? 1.0; // Mínimo 1.0
    final stock = _parseInt(cantidad, defaultValue: 0) ?? 0;
    final categoryId = categoria ?? 1;
    
    // Log para depuración
    print('Product mapping: name=$name, price=$price, stock=$stock, external_code=${codigo}, category_id=$categoryId');
    
    return {
      'name': name,
      'external_code': codigo.toString(),
      'price': price, // Enviar como número
      'stock': stock, // Enviar como número
      'category_id': categoryId, // Enviar como número
      'description': observaciones ?? '',
      'is_active': (contabilizar ?? 1) == 1, // Enviar como boolean
      'barcode': codigoBarras ?? '',
      'cost': _parseDecimal(costo, defaultValue: 0.0) ?? 0.0,
      'tax_rate': _parseDecimal(iva, defaultValue: 12.0) ?? 12.0,
      'unit': unidad ?? 'UNIDAD',
      'notes': observaciones ?? '',
      'sync_source': 'accounting',
    };
  }

  double? _parseDecimal(String? value, {double? defaultValue}) {
    if (value == null || value.isEmpty) return defaultValue;
    try {
      return double.parse(value.replaceAll(',', '.'));
    } catch (e) {
      return defaultValue;
    }
  }

  int? _parseInt(String? value, {int? defaultValue}) {
    if (value == null || value.isEmpty) return defaultValue;
    try {
      return int.parse(value);
    } catch (e) {
      return defaultValue;
    }
  }

  @override
  String toString() {
    return 'AccountingProduct(codigo: $codigo, producto: $producto, stock: $cantidad)';
  }
}

class BackendProduct {
  final int id;
  final String? externalCode;
  final String name;
  final String? barcode;
  final double? price;
  final double? cost;
  final double? taxRate;
  final int? stock;
  final String? unit;
  final int? categoryId;
  final String syncSource;
  final bool isActive;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BackendProduct({
    required this.id,
    this.externalCode,
    required this.name,
    this.barcode,
    this.price,
    this.cost,
    this.taxRate,
    this.stock,
    this.unit,
    this.categoryId,
    required this.syncSource,
    required this.isActive,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory BackendProduct.fromJson(Map<String, dynamic> json) {
    return BackendProduct(
      id: json['id'] as int,
      externalCode: json['external_code'] as String?,
      name: json['name'] as String,
      barcode: json['barcode'] as String?,
      price: json['price']?.toDouble(),
      cost: json['cost']?.toDouble(),
      taxRate: json['tax_rate']?.toDouble(),
      stock: json['stock'] as int?,
      unit: json['unit'] as String?,
      categoryId: json['category_id'] as int?,
      syncSource: json['sync_source'] as String,
      isActive: json['is_active'] as bool,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  @override
  String toString() {
    return 'BackendProduct(id: $id, externalCode: $externalCode, name: $name)';
  }
}