import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/sync_service.dart';
import '../models/sync_result_model.dart';
import '../config/app_theme.dart';

class SyncStatusWidget extends StatelessWidget {
  const SyncStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncService>(
      builder: (context, syncService, child) {
        final statusColor = _getStatusColor(syncService.status);
        final statusBgColor = _getStatusBackgroundColor(syncService.status);
        
        return Container(
          decoration: BoxDecoration(
            color: statusBgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: statusColor.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _buildStatusIcon(syncService.status),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getStatusTitle(syncService.status),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          if (syncService.currentOperation.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              syncService.currentOperation,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (syncService.isSyncing) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.cardBorder.withOpacity(0.5)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progreso de sincronización',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              '${(syncService.progress * 100).toInt()}%',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: syncService.progress,
                            backgroundColor: AppTheme.backgroundDark,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                            minHeight: 6,
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
      },
    );
  }

  Widget _buildStatusIcon(SyncStatus status) {
    switch (status) {
      case SyncStatus.idle:
        return const Icon(
          Icons.pause_circle_outline,
          color: Colors.white,
          size: 24,
        );
      case SyncStatus.connecting:
        return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        );
      case SyncStatus.syncing:
        return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        );
      case SyncStatus.completed:
        return const Icon(
          Icons.check_circle_outline,
          color: Colors.white,
          size: 24,
        );
      case SyncStatus.error:
        return const Icon(
          Icons.error_outline,
          color: Colors.white,
          size: 24,
        );
    }
  }

  String _getStatusTitle(SyncStatus status) {
    switch (status) {
      case SyncStatus.idle:
        return 'Sistema en Espera';
      case SyncStatus.connecting:
        return 'Estableciendo Conexión';
      case SyncStatus.syncing:
        return 'Sincronización en Progreso';
      case SyncStatus.completed:
        return 'Sincronización Completada';
      case SyncStatus.error:
        return 'Error en Sincronización';
    }
  }

  Color _getStatusColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.idle:
        return AppTheme.statusIdle;
      case SyncStatus.connecting:
        return AppTheme.statusConnecting;
      case SyncStatus.syncing:
        return AppTheme.statusSyncing;
      case SyncStatus.completed:
        return AppTheme.statusCompleted;
      case SyncStatus.error:
        return AppTheme.statusError;
    }
  }

  Color _getStatusBackgroundColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.idle:
        return AppTheme.statusIdleBackground;
      case SyncStatus.connecting:
        return AppTheme.statusConnectingBackground;
      case SyncStatus.syncing:
        return AppTheme.statusSyncingBackground;
      case SyncStatus.completed:
        return AppTheme.statusCompletedBackground;
      case SyncStatus.error:
        return AppTheme.statusErrorBackground;
    }
  }
}