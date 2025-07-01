-- Script SEGURO para agregar campos faltantes a la tabla products del backend
-- Estos campos son necesarios para la sincronización con el sistema contable
-- IMPORTANTE: Este script NO modifica ni elimina datos existentes

-- Verificar estructura actual antes de los cambios
SELECT 'ESTRUCTURA ACTUAL DE LA TABLA PRODUCTS:' as info;
DESCRIBE products;

-- Agregar campos solo si NO existen (evita errores si ya fueron agregados)
SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
     WHERE TABLE_SCHEMA = DATABASE() 
     AND TABLE_NAME = 'products' 
     AND COLUMN_NAME = 'external_code') = 0,
    'ALTER TABLE products ADD COLUMN external_code VARCHAR(100) NULL AFTER sku',
    'SELECT "Campo external_code ya existe" as info'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
     WHERE TABLE_SCHEMA = DATABASE() 
     AND TABLE_NAME = 'products' 
     AND COLUMN_NAME = 'barcode') = 0,
    'ALTER TABLE products ADD COLUMN barcode VARCHAR(100) NULL AFTER external_code',
    'SELECT "Campo barcode ya existe" as info'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
     WHERE TABLE_SCHEMA = DATABASE() 
     AND TABLE_NAME = 'products' 
     AND COLUMN_NAME = 'cost') = 0,
    'ALTER TABLE products ADD COLUMN cost DECIMAL(10,2) DEFAULT 0 AFTER price',
    'SELECT "Campo cost ya existe" as info'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
     WHERE TABLE_SCHEMA = DATABASE() 
     AND TABLE_NAME = 'products' 
     AND COLUMN_NAME = 'tax_rate') = 0,
    'ALTER TABLE products ADD COLUMN tax_rate DECIMAL(5,2) DEFAULT 12.0 AFTER cost',
    'SELECT "Campo tax_rate ya existe" as info'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
     WHERE TABLE_SCHEMA = DATABASE() 
     AND TABLE_NAME = 'products' 
     AND COLUMN_NAME = 'unit') = 0,
    'ALTER TABLE products ADD COLUMN unit VARCHAR(50) DEFAULT "UNIDAD" AFTER stock',
    'SELECT "Campo unit ya existe" as info'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
     WHERE TABLE_SCHEMA = DATABASE() 
     AND TABLE_NAME = 'products' 
     AND COLUMN_NAME = 'notes') = 0,
    'ALTER TABLE products ADD COLUMN notes TEXT NULL AFTER unit',
    'SELECT "Campo notes ya existe" as info'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
     WHERE TABLE_SCHEMA = DATABASE() 
     AND TABLE_NAME = 'products' 
     AND COLUMN_NAME = 'sync_source') = 0,
    'ALTER TABLE products ADD COLUMN sync_source VARCHAR(50) DEFAULT "manual" AFTER notes',
    'SELECT "Campo sync_source ya existe" as info'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Crear índice para búsquedas rápidas por external_code (solo si no existe)
SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS 
     WHERE TABLE_SCHEMA = DATABASE() 
     AND TABLE_NAME = 'products' 
     AND INDEX_NAME = 'idx_products_external_code') = 0,
    'CREATE INDEX idx_products_external_code ON products(external_code)',
    'SELECT "Índice idx_products_external_code ya existe" as info'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Mostrar estructura final
SELECT 'ESTRUCTURA FINAL DE LA TABLA PRODUCTS:' as info;
DESCRIBE products;

-- Mostrar productos existentes (para verificar que no se perdieron datos)
SELECT COUNT(*) as total_productos_existentes FROM products;
SELECT 'Primeros 5 productos para verificar integridad:' as info;
SELECT id, name, price, stock, is_active FROM products LIMIT 5;