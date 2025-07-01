import 'dart:io';

class AppConfig {
  static const String appName = 'Distrimax Sync App';
  static const String version = '1.0.0';
  
  // Platform detection
  static bool get isDesktop => Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  static bool get isWindows => Platform.isWindows;
  static bool get isLinux => Platform.isLinux;
  
  // Storage keys
  static const String keyMysqlHost = 'mysql_host';
  static const String keyMysqlPort = 'mysql_port';
  static const String keyMysqlUser = 'mysql_user';
  static const String keyMysqlPassword = 'mysql_password';
  static const String keyMysqlDatabase = 'mysql_database';
  static const String keyMysqlTable = 'mysql_table';
  static const String keyApiBaseUrl = 'api_base_url';
  static const String keyApiToken = 'api_token';
  static const String keySyncInterval = 'sync_interval';
  static const String keyAutoSyncEnabled = 'auto_sync_enabled';
  static const String keyLastSyncTime = 'last_sync_time';
  
  // Default values
  static const int defaultMysqlPort = 3306;
  static const String defaultMysqlTable = 'productos'; // From tabla.png
  static const int defaultSyncInterval = 60; // minutes
  static const bool defaultAutoSyncEnabled = true;
  
  // Sync settings
  static const int maxBatchSize = 100;
  static const int maxRetries = 3;
  static const int retryDelaySeconds = 5;
  static const int connectionTimeoutSeconds = 30;
  
  // Validation
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }
  
  static bool isValidPort(String port) {
    try {
      final portNumber = int.parse(port);
      return portNumber > 0 && portNumber <= 65535;
    } catch (e) {
      return false;
    }
  }
  
  static bool isValidInterval(String interval) {
    try {
      final intervalNumber = int.parse(interval);
      return intervalNumber >= 5 && intervalNumber <= 1440; // 5 min to 24 hours
    } catch (e) {
      return false;
    }
  }
}