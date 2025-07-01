import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../services/sync_service.dart';
import '../config/app_theme.dart';
import 'config_screen.dart';
import 'sync_log_screen.dart';
import 'log_viewer_screen.dart';
import '../widgets/sync_status_widget.dart';
import '../widgets/desktop_app_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DesktopAppBar(
        title: 'Distrimax Sync App',
        actions: [
          DesktopIconButton(
            icon: Icons.settings_outlined,
            onPressed: () => _navigateToConfig(context),
            tooltip: 'Configuración',
          ),
          DesktopIconButton(
            icon: Icons.history_outlined,
            onPressed: () => _navigateToLogs(context),
            tooltip: 'Historial',
          ),
          DesktopIconButton(
            icon: Icons.description_outlined,
            onPressed: () => _navigateToLogViewer(context),
            tooltip: 'Visor de Logs',
          ),
        ],
      ),
      backgroundColor: AppTheme.backgroundLight,
      body: Consumer<SyncService>(
        builder: (context, syncService, child) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Configuration Status Card
                      _buildConfigStatusCard(context, syncService),
                      const SizedBox(height: 24),
                      
                      // Sync Status Widget
                      const SyncStatusWidget(),
                      const SizedBox(height: 24),
                      
                      // Action Buttons
                      _buildActionButtons(context, syncService),
                      const SizedBox(height: 24),
                      
                      // Info Cards Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildLastSyncInfo(context, syncService),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _buildNextSyncInfo(context, syncService),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildConfigStatusCard(BuildContext context, SyncService syncService) {
    final isConfigured = syncService.isConfigured;
    
    return Container(
      decoration: BoxDecoration(
        color: isConfigured ? AppTheme.statusCompletedBackground : AppTheme.warningOrangeLight.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isConfigured ? AppTheme.accentGreen.withOpacity(0.3) : AppTheme.warningOrange.withOpacity(0.3),
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
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isConfigured ? AppTheme.accentGreen : AppTheme.warningOrange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isConfigured ? Icons.check_circle_outline : Icons.warning_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isConfigured ? 'Configuración Completa' : 'Configuración Pendiente',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isConfigured 
                      ? 'La aplicación está lista para sincronizar productos con el backend'
                      : 'Complete la configuración de MySQL y API para comenzar la sincronización',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (!isConfigured)
            ElevatedButton.icon(
              onPressed: () => _navigateToConfig(context),
              icon: const Icon(Icons.settings_outlined, size: 18),
              label: const Text('Configurar Ahora'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, SyncService syncService) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Acciones Rápidas',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: syncService.isConfigured && !syncService.isSyncing
                      ? () => _performManualSync(context, syncService)
                      : null,
                  icon: syncService.isSyncing 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.sync_outlined, size: 20),
                  label: Text(syncService.isSyncing ? 'Sincronizando...' : 'Sincronizar Ahora'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: syncService.isConfigured
                      ? () => _testConnections(context, syncService)
                      : null,
                  icon: const Icon(Icons.wifi_protected_setup_outlined, size: 20),
                  label: const Text('Probar Conexiones'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    side: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLastSyncInfo(BuildContext context, SyncService syncService) {
    final lastResult = syncService.lastResult;
    final lastSyncTime = syncService.config.lastSyncTime;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.access_time_outlined,
                  color: AppTheme.primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Última Sincronización',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (lastSyncTime != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.cardBorder.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.schedule_outlined, size: 18, color: AppTheme.textSecondary),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(lastSyncTime),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  if (lastResult != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          lastResult.success ? Icons.check_circle_outline : Icons.error_outline,
                          size: 18,
                          color: lastResult.success ? AppTheme.accentGreen : AppTheme.errorRed,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            lastResult.summary,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ] else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.cardBorder.withOpacity(0.5)),
              ),
              child: Text(
                'No se ha realizado ninguna sincronización',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNextSyncInfo(BuildContext context, SyncService syncService) {
    if (!syncService.config.autoSyncEnabled) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.textMuted.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.timer_off_outlined,
                    color: AppTheme.textMuted,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Sincronización Automática',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.cardBorder.withOpacity(0.5)),
              ),
              child: Text(
                'La sincronización automática está deshabilitada',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final timeUntilNext = syncService.getTimeUntilNextSync();
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.timer_outlined,
                  color: AppTheme.accentGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Próxima Sincronización',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.cardBorder.withOpacity(0.5)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 18, color: AppTheme.textSecondary),
                    const SizedBox(width: 12),
                    Text(
                      timeUntilNext != null 
                          ? _formatDuration(timeUntilNext)
                          : 'Calculando...',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.settings_outlined, size: 16, color: AppTheme.textMuted),
                    const SizedBox(width: 12),
                    Text(
                      'Intervalo: ${syncService.config.syncIntervalMinutes} minutos',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inSeconds <= 0) {
      return 'En cualquier momento';
    }
    
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else {
      return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
    }
  }

  void _navigateToConfig(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ConfigScreen()),
    );
  }

  void _navigateToLogs(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SyncLogScreen()),
    );
  }

  void _navigateToLogViewer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const LogViewerScreen()),
    );
  }

  Future<void> _performManualSync(BuildContext context, SyncService syncService) async {
    try {
      await syncService.performSync(isManual: true);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sincronización completada'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error en sincronización: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _testConnections(BuildContext context, SyncService syncService) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      final success = await syncService.testConnections();
      
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            success 
                ? 'Todas las conexiones son exitosas'
                : 'Error en una o más conexiones',
          ),
          backgroundColor: success ? AppTheme.accentGreen : AppTheme.warningOrange,
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error probando conexiones: $e'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }
}