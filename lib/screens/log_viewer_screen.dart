import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;

import '../services/logging_service.dart';

class LogViewerScreen extends StatefulWidget {
  const LogViewerScreen({Key? key}) : super(key: key);

  @override
  State<LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends State<LogViewerScreen> {
  List<FileSystemEntity> _logFiles = [];
  String? _selectedLogFile;
  String _logContent = '';
  bool _isLoading = false;
  bool _autoScroll = true;
  final ScrollController _scrollController = ScrollController();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    // Cargar los archivos después de que el widget esté completamente inicializado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLogFiles();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadLogFiles() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Verificar si el logging está inicializado
      final status = LoggingService.instance.getStatus();
      if (!status['initialized']) {
        if (mounted) {
          _showError('Sistema de logging no inicializado. Espera un momento e intenta de nuevo.');
          setState(() => _isLoading = false);
        }
        return;
      }
      
      final files = await LoggingService.instance.getLogFiles();
      if (mounted) {
        setState(() {
          _logFiles = files;
          if (files.isNotEmpty && _selectedLogFile == null) {
            _selectedLogFile = path.basename(files.first.path);
            _loadLogContent();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        _showError('Error cargando archivos de log: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadLogContent() async {
    if (_selectedLogFile == null || !mounted) return;

    setState(() => _isLoading = true);
    
    try {
      final content = await LoggingService.instance.readLogFile(_selectedLogFile!);
      if (mounted) {
        setState(() => _logContent = content);
        
        if (_autoScroll && _scrollController.hasClients) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Error cargando contenido del log: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _copyToClipboard() {
    if (_logContent.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _logContent));
      _showSuccess('Contenido del log copiado al portapapeles');
    }
  }

  void _exportLog() async {
    if (_selectedLogFile == null || _logContent.isEmpty) return;

    try {
      // En una aplicación real, aquí podrías usar file_picker o similar
      // para permitir al usuario elegir dónde guardar el archivo
      _showSuccess('Funcionalidad de exportación disponible');
    } catch (e) {
      _showError('Error exportando log: $e');
    }
  }

  Widget _buildLogFileDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedLogFile,
          hint: const Text('Seleccionar archivo de log'),
          isExpanded: true,
          items: _logFiles.map((file) {
            final filename = path.basename(file.path);
            final stat = file.statSync();
            final size = (stat.size / 1024).toStringAsFixed(1);
            final modified = _dateFormat.format(stat.modified);
            
            return DropdownMenuItem<String>(
              value: filename,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    filename,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Tamaño: ${size}KB - Modificado: $modified',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedLogFile = newValue;
                _logContent = '';
              });
              _loadLogContent();
            }
          },
        ),
      ),
    );
  }

  Widget _buildLogContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando logs...'),
          ],
        ),
      );
    }

    if (_logContent.isEmpty) {
      return const Center(
        child: Text(
          'No hay contenido en el log seleccionado',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Scrollbar(
        controller: _scrollController,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(12),
          child: SelectableText(
            _logContent,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: Colors.green,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    final status = LoggingService.instance.getStatus();
    final isInitialized = status['initialized'] as bool;
    
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: _loadLogFiles,
          icon: const Icon(Icons.refresh),
          label: const Text('Actualizar'),
        ),
        const SizedBox(width: 8),
        if (!isInitialized) ...[
          ElevatedButton.icon(
            onPressed: () async {
              try {
                await LoggingService.instance.initialize();
                _showSuccess('Sistema de logging inicializado');
                _loadLogFiles();
              } catch (e) {
                _showError('Error inicializando logging: $e');
              }
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Inicializar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
        ],
        ElevatedButton.icon(
          onPressed: _selectedLogFile != null ? _loadLogContent : null,
          icon: const Icon(Icons.file_open),
          label: const Text('Recargar'),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: _logContent.isNotEmpty ? _copyToClipboard : null,
          icon: const Icon(Icons.copy),
          label: const Text('Copiar'),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: _logContent.isNotEmpty ? _exportLog : null,
          icon: const Icon(Icons.download),
          label: const Text('Exportar'),
        ),
        const Spacer(),
        Row(
          children: [
            Checkbox(
              value: _autoScroll,
              onChanged: (bool? value) {
                setState(() => _autoScroll = value ?? false);
              },
            ),
            const Text('Auto-scroll'),
          ],
        ),
      ],
    );
  }

  Widget _buildLogInfo() {
    final status = LoggingService.instance.getStatus();
    final isInitialized = status['initialized'] as bool;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Información del Sistema de Logs',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Icon(
                  isInitialized ? Icons.check_circle : Icons.error,
                  color: isInitialized ? Colors.green : Colors.red,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Estado', isInitialized ? 'Inicializado' : 'No inicializado'),
            _buildInfoRow('Directorio', status['logDirectory']),
            if (isInitialized) ...[
              _buildInfoRow('Archivo actual', path.basename(status['currentLogFile'])),
              _buildInfoRow('Fecha actual', status['currentDate']),
              _buildInfoRow('Buffer size', '${status['bufferSize']} entradas'),
            ],
            _buildInfoRow('Plataforma', status['platform']),
            _buildInfoRow('Total archivos', '${_logFiles.length} archivos'),
            if (!isInitialized) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'El sistema de logging se está inicializando. Espera un momento.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visor de Logs'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLogInfo(),
            const SizedBox(height: 16),
            const Text(
              'Seleccionar Archivo de Log:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildLogFileDropdown(),
            const SizedBox(height: 16),
            _buildControls(),
            const SizedBox(height: 16),
            const Text(
              'Contenido del Log:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _buildLogContent(),
            ),
          ],
        ),
      ),
    );
  }
}