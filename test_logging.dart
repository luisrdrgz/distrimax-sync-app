import 'dart:io';
import 'lib/services/logging_service.dart';

void main() async {
  print('=== Prueba del Sistema de Logging ===');
  
  try {
    print('1. Inicializando LoggingService...');
    await LoggingService.instance.initialize();
    print('2. LoggingService inicializado correctamente');
    
    print('3. Obteniendo estado...');
    final status = LoggingService.instance.getStatus();
    print('   Estado: ${status['initialized']}');
    print('   Directorio: ${status['logDirectory']}');
    print('   Archivo actual: ${status['currentLogFile']}');
    
    print('4. Escribiendo logs de prueba...');
    LoggingService.instance.logInfo('TestApp', 'Esta es una prueba de logging');
    LoggingService.instance.logWarning('TestApp', 'Esta es una advertencia de prueba');
    LoggingService.instance.logError('TestApp', 'Este es un error de prueba');
    
    print('5. Esperando flush...');
    await Future.delayed(Duration(seconds: 2));
    await LoggingService.instance.flush();
    
    print('6. Obteniendo archivos de log...');
    final files = await LoggingService.instance.getLogFiles();
    print('   Archivos encontrados: ${files.length}');
    for (final file in files) {
      print('   - ${file.path}');
    }
    
    if (files.isNotEmpty) {
      print('7. Leyendo contenido del primer archivo...');
      final fileName = files.first.path.split('/').last;
      final content = await LoggingService.instance.readLogFile(fileName);
      print('   Contenido (primeras 500 chars):');
      print('   ${content.length > 500 ? content.substring(0, 500) + '...' : content}');
    }
    
    print('8. Finalizando...');
    await LoggingService.instance.dispose();
    print('=== Prueba completada exitosamente ===');
    
  } catch (e, stackTrace) {
    print('ERROR en la prueba: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}