import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/sync_service.dart';
import '../models/sync_config_model.dart';
import '../config/app_config.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  // Controllers
  late TextEditingController _mysqlHostController;
  late TextEditingController _mysqlPortController;
  late TextEditingController _mysqlUserController;
  late TextEditingController _mysqlPasswordController;
  late TextEditingController _mysqlDatabaseController;
  late TextEditingController _mysqlTableController;
  late TextEditingController _apiBaseUrlController;
  late TextEditingController _apiTokenController;
  late TextEditingController _syncIntervalController;
  
  bool _autoSyncEnabled = true;
  bool _useHttpMode = true;
  bool _showPasswords = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadCurrentConfig();
  }

  void _initializeControllers() {
    _mysqlHostController = TextEditingController();
    _mysqlPortController = TextEditingController();
    _mysqlUserController = TextEditingController();
    _mysqlPasswordController = TextEditingController();
    _mysqlDatabaseController = TextEditingController();
    _mysqlTableController = TextEditingController();
    _apiBaseUrlController = TextEditingController();
    _apiTokenController = TextEditingController();
    _syncIntervalController = TextEditingController();
  }

  void _loadCurrentConfig() {
    final syncService = context.read<SyncService>();
    final config = syncService.config;
    
    _mysqlHostController.text = config.mysqlHost;
    _mysqlPortController.text = config.mysqlPort.toString();
    _mysqlUserController.text = config.mysqlUser;
    _mysqlPasswordController.text = config.mysqlPassword;
    _mysqlDatabaseController.text = config.mysqlDatabase;
    _mysqlTableController.text = config.mysqlTable;
    _apiBaseUrlController.text = config.apiBaseUrl;
    _apiTokenController.text = config.apiToken;
    _syncIntervalController.text = config.syncIntervalMinutes.toString();
    _autoSyncEnabled = config.autoSyncEnabled;
    _useHttpMode = config.useHttpMode;
  }

  @override
  void dispose() {
    _mysqlHostController.dispose();
    _mysqlPortController.dispose();
    _mysqlUserController.dispose();
    _mysqlPasswordController.dispose();
    _mysqlDatabaseController.dispose();
    _mysqlTableController.dispose();
    _apiBaseUrlController.dispose();
    _apiTokenController.dispose();
    _syncIntervalController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(_showPasswords ? Icons.visibility_off : Icons.visibility),
            onPressed: () {
              setState(() {
                _showPasswords = !_showPasswords;
              });
            },
            tooltip: _showPasswords ? 'Ocultar contraseñas' : 'Mostrar contraseñas',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Scrollbar(
          controller: _scrollController,
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildMySqlSection(),
                const SizedBox(height: 24),
                _buildApiSection(),
                const SizedBox(height: 24),
                _buildSyncSection(),
                const SizedBox(height: 32),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMySqlSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configuración MySQL',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _mysqlHostController,
              decoration: const InputDecoration(
                labelText: 'Host/IP',
                hintText: 'localhost o 192.168.1.100',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.computer),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Host es requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _mysqlPortController,
              decoration: const InputDecoration(
                labelText: 'Puerto',
                hintText: '3306',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.settings_ethernet),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Puerto es requerido';
                }
                if (!AppConfig.isValidPort(value)) {
                  return 'Puerto inválido (1-65535)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _mysqlUserController,
                    decoration: const InputDecoration(
                      labelText: 'Usuario',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Usuario es requerido';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _mysqlPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: !_showPasswords,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Contraseña es requerida';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _mysqlDatabaseController,
                    decoration: const InputDecoration(
                      labelText: 'Base de Datos',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.storage),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Base de datos es requerida';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _mysqlTableController,
                    decoration: const InputDecoration(
                      labelText: 'Tabla',
                      hintText: 'productos',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.table_chart),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Tabla es requerida';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApiSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configuración API',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _apiBaseUrlController,
              decoration: const InputDecoration(
                labelText: 'URL Base del API',
                hintText: 'http://localhost:3000',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'URL del API es requerida';
                }
                if (!AppConfig.isValidUrl(value)) {
                  return 'URL inválida';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _apiTokenController,
              decoration: InputDecoration(
                labelText: 'Token de Autenticación',
                hintText: 'Bearer token o API key',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.key),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      onPressed: _apiTokenController.text.isNotEmpty 
                          ? () => _copyToClipboard(_apiTokenController.text, 'Token copiado al portapapeles') 
                          : null,
                      tooltip: 'Copiar token',
                    ),
                    IconButton(
                      icon: const Icon(Icons.info_outline, size: 20),
                      onPressed: _apiTokenController.text.isNotEmpty 
                          ? () => _showTokenInfo() 
                          : null,
                      tooltip: 'Información del token',
                    ),
                  ],
                ),
              ),
              obscureText: !_showPasswords,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Token es requerido';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configuración de Sincronización',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Sincronización Automática'),
              subtitle: const Text('Ejecutar sincronización de forma automática'),
              value: _autoSyncEnabled,
              onChanged: (value) {
                setState(() {
                  _autoSyncEnabled = value;
                });
              },
            ),
            if (_autoSyncEnabled) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _syncIntervalController,
                decoration: const InputDecoration(
                  labelText: 'Intervalo (minutos)',
                  hintText: '60',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.timer),
                  suffixText: 'min',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (_autoSyncEnabled && (value == null || value.isEmpty)) {
                    return 'Intervalo es requerido';
                  }
                  if (_autoSyncEnabled && !AppConfig.isValidInterval(value!)) {
                    return 'Intervalo inválido (5-1440 min)';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Modo HTTP'),
              subtitle: const Text('Usar API REST en lugar de conexión directa MySQL\n(Recomendado para MySQL 8.0+)'),
              value: _useHttpMode,
              onChanged: (value) {
                setState(() {
                  _useHttpMode = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _testConnections,
                icon: _isLoading 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.wifi_protected_setup),
                label: const Text('Probar Conexiones'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveConfiguration,
                icon: const Icon(Icons.save),
                label: const Text('Guardar'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: _resetToDefaults,
            icon: const Icon(Icons.restore),
            label: const Text('Restaurar Valores por Defecto'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _testConnections() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final config = _buildConfigFromForm();
      final syncService = context.read<SyncService>();
      
      // Temporarily update config for testing
      await syncService.updateConfiguration(config);
      
      final success = await syncService.testConnections();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success 
                  ? 'Todas las conexiones son exitosas'
                  : 'Error en una o más conexiones',
            ),
            backgroundColor: success ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error probando conexiones: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveConfiguration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final config = _buildConfigFromForm();
      final syncService = context.read<SyncService>();
      
      await syncService.updateConfiguration(config);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuración guardada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error guardando configuración: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _resetToDefaults() {
    setState(() {
      _mysqlHostController.text = '';
      _mysqlPortController.text = AppConfig.defaultMysqlPort.toString();
      _mysqlUserController.text = '';
      _mysqlPasswordController.text = '';
      _mysqlDatabaseController.text = '';
      _mysqlTableController.text = AppConfig.defaultMysqlTable;
      _apiBaseUrlController.text = '';
      _apiTokenController.text = '';
      _syncIntervalController.text = AppConfig.defaultSyncInterval.toString();
      _autoSyncEnabled = AppConfig.defaultAutoSyncEnabled;
      _useHttpMode = true; // HTTP por defecto para evitar problemas de compatibilidad
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Valores restaurados a configuración por defecto'),
      ),
    );
  }

  SyncConfig _buildConfigFromForm() {
    return SyncConfig(
      mysqlHost: _mysqlHostController.text.trim(),
      mysqlPort: int.parse(_mysqlPortController.text),
      mysqlUser: _mysqlUserController.text.trim(),
      mysqlPassword: _mysqlPasswordController.text,
      mysqlDatabase: _mysqlDatabaseController.text.trim(),
      mysqlTable: _mysqlTableController.text.trim(),
      apiBaseUrl: _apiBaseUrlController.text.trim(),
      apiToken: _apiTokenController.text.trim(),
      syncIntervalMinutes: int.parse(_syncIntervalController.text),
      autoSyncEnabled: _autoSyncEnabled,
      useHttpMode: _useHttpMode,
    );
  }

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showTokenInfo() {
    final token = _apiTokenController.text.trim();
    final tokenLength = token.length;
    final tokenPreview = token.length > 20 
        ? '${token.substring(0, 10)}...${token.substring(token.length - 10)}'
        : token;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Información del Token'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Longitud: $tokenLength caracteres'),
              const SizedBox(height: 8),
              const Text('Vista previa:'),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                child: SelectableText(
                  tokenPreview,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Token completo:'),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                child: SelectableText(
                  token,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                _copyToClipboard(token, 'Token completo copiado al portapapeles');
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copiar'),
            ),
          ],
        );
      },
    );
  }
}