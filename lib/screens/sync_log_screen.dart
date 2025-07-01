import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../services/sync_service.dart';
import '../models/sync_result_model.dart';

class SyncLogScreen extends StatefulWidget {
  const SyncLogScreen({super.key});

  @override
  State<SyncLogScreen> createState() => _SyncLogScreenState();
}

class _SyncLogScreenState extends State<SyncLogScreen> {
  List<SyncResult> _syncHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSyncHistory();
  }

  Future<void> _loadSyncHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final syncService = context.read<SyncService>();
      final history = await syncService.getSyncHistory();
      
      setState(() {
        _syncHistory = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando historial: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Sincronización'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSyncHistory,
            tooltip: 'Actualizar',
          ),
          if (_syncHistory.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _showClearHistoryDialog,
              tooltip: 'Limpiar historial',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _syncHistory.isEmpty
              ? _buildEmptyState()
              : _buildHistoryList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay historial de sincronización',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Las sincronizaciones aparecerán aquí',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return RefreshIndicator(
      onRefresh: _loadSyncHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _syncHistory.length,
        itemBuilder: (context, index) {
          final result = _syncHistory[index];
          return _buildHistoryItem(result, index);
        },
      ),
    );
  }

  Widget _buildHistoryItem(SyncResult result, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: result.success ? Colors.green : Colors.red,
          foregroundColor: Colors.white,
          child: Icon(
            result.success ? Icons.check : Icons.error,
            size: 20,
          ),
        ),
        title: Text(
          result.success ? 'Sincronización Exitosa' : 'Error de Sincronización',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: result.success ? Colors.green.shade700 : Colors.red.shade700,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('dd/MM/yyyy HH:mm:ss').format(result.timestamp),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              result.summary,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Mensaje', result.message),
                if (result.success) ...[
                  _buildDetailRow('Total de productos', result.totalProducts.toString()),
                  _buildDetailRow('Productos creados', result.createdProducts.toString()),
                  _buildDetailRow('Productos actualizados', result.updatedProducts.toString()),
                  if (result.errorProducts > 0)
                    _buildDetailRow('Productos con error', result.errorProducts.toString()),
                ],
                _buildDetailRow('Duración', _formatDuration(result.duration)),
                if (result.errors.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Errores:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...result.errors.take(5).map((error) => Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text(
                      '• $error',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.red.shade600,
                      ),
                    ),
                  )),
                  if (result.errors.length > 5)
                    Text(
                      '... y ${result.errors.length - 5} errores más',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.red.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Limpiar Historial'),
          content: const Text(
            '¿Estás seguro de que quieres eliminar todo el historial de sincronización? '
            'Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _clearHistory();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearHistory() async {
    try {
      // Note: For now, just reload the history as clearing is not implemented
      // This would need a clearSyncHistory method exposed in SyncService
      await _loadSyncHistory();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Función pendiente de implementar'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}