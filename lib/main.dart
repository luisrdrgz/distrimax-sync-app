import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:logging/logging.dart';

import 'config/app_config.dart';
import 'config/app_theme.dart';
import 'services/storage_service.dart';
import 'services/sync_service.dart';
import 'services/logging_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize logging service first
  try {
    print('Inicializando sistema de logging...');
    await LoggingService.instance.initialize();
    LoggingService.instance.logInfo('Application', 'Iniciando Distrimax Sync App');
    print('Sistema de logging inicializado correctamente');
  } catch (e) {
    print('Error inicializando sistema de logging: $e');
    print('Stack trace: ${StackTrace.current}');
    // Continue without logging if it fails
  }

  // Configure window for desktop
  if (AppConfig.isDesktop) {
    await windowManager.ensureInitialized();
    
    const windowOptions = WindowOptions(
      size: Size(1200, 800),
      minimumSize: Size(800, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      title: 'Distrimax Sync App',
    );
    
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      LoggingService.instance.logInfo('Application', 'Ventana de aplicación inicializada');
    });
  }

  // Initialize services
  try {
    LoggingService.instance.logInfo('Application', 'Inicializando servicios...');
    final storageService = StorageService();
    await storageService.init();
    LoggingService.instance.logInfo('Application', 'Servicios inicializados correctamente');
    
    runApp(MyApp(storageService: storageService));
  } catch (e) {
    LoggingService.instance.logError('Application', 'Error inicializando aplicación', e);
    rethrow;
  }
}

class MyApp extends StatelessWidget {
  final StorageService storageService;

  const MyApp({super.key, required this.storageService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storageService),
        ChangeNotifierProvider(
          create: (context) => SyncService(
            storageService: context.read<StorageService>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Distrimax Sync App',
        theme: AppTheme.lightTheme,
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}