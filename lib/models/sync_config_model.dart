class SyncConfig {
  String mysqlHost;
  int mysqlPort;
  String mysqlUser;
  String mysqlPassword;
  String mysqlDatabase;
  String mysqlTable;
  String apiBaseUrl;
  String apiToken;
  int syncIntervalMinutes;
  bool autoSyncEnabled;
  bool useHttpMode; // true = HTTP API, false = direct MySQL
  DateTime? lastSyncTime;

  SyncConfig({
    this.mysqlHost = '',
    this.mysqlPort = 3306,
    this.mysqlUser = '',
    this.mysqlPassword = '',
    this.mysqlDatabase = '',
    this.mysqlTable = 'productos',
    this.apiBaseUrl = '',
    this.apiToken = '',
    this.syncIntervalMinutes = 60,
    this.autoSyncEnabled = true,
    this.useHttpMode = false, // Usar conexión directa MySQL por defecto
    this.lastSyncTime,
  });

  bool get isValid {
    return mysqlHost.isNotEmpty &&
        mysqlUser.isNotEmpty &&
        mysqlPassword.isNotEmpty &&
        mysqlDatabase.isNotEmpty &&
        mysqlTable.isNotEmpty &&
        apiBaseUrl.isNotEmpty &&
        apiToken.isNotEmpty;
  }

  String get mysqlConnectionString {
    return 'mysql://$mysqlUser:$mysqlPassword@$mysqlHost:$mysqlPort/$mysqlDatabase';
  }

  Map<String, dynamic> toJson() {
    return {
      'mysqlHost': mysqlHost,
      'mysqlPort': mysqlPort,
      'mysqlUser': mysqlUser,
      'mysqlPassword': mysqlPassword,
      'mysqlDatabase': mysqlDatabase,
      'mysqlTable': mysqlTable,
      'apiBaseUrl': apiBaseUrl,
      'apiToken': apiToken,
      'syncIntervalMinutes': syncIntervalMinutes,
      'autoSyncEnabled': autoSyncEnabled,
      'useHttpMode': useHttpMode,
      'lastSyncTime': lastSyncTime?.toIso8601String(),
    };
  }

  factory SyncConfig.fromJson(Map<String, dynamic> json) {
    return SyncConfig(
      mysqlHost: json['mysqlHost'] ?? '',
      mysqlPort: json['mysqlPort'] ?? 3306,
      mysqlUser: json['mysqlUser'] ?? '',
      mysqlPassword: json['mysqlPassword'] ?? '',
      mysqlDatabase: json['mysqlDatabase'] ?? '',
      mysqlTable: json['mysqlTable'] ?? 'productos',
      apiBaseUrl: json['apiBaseUrl'] ?? '',
      apiToken: json['apiToken'] ?? '',
      syncIntervalMinutes: json['syncIntervalMinutes'] ?? 60,
      autoSyncEnabled: json['autoSyncEnabled'] ?? true,
      useHttpMode: json['useHttpMode'] ?? false,
      lastSyncTime: json['lastSyncTime'] != null
          ? DateTime.parse(json['lastSyncTime'])
          : null,
    );
  }

  SyncConfig copyWith({
    String? mysqlHost,
    int? mysqlPort,
    String? mysqlUser,
    String? mysqlPassword,
    String? mysqlDatabase,
    String? mysqlTable,
    String? apiBaseUrl,
    String? apiToken,
    int? syncIntervalMinutes,
    bool? autoSyncEnabled,
    bool? useHttpMode,
    DateTime? lastSyncTime,
  }) {
    return SyncConfig(
      mysqlHost: mysqlHost ?? this.mysqlHost,
      mysqlPort: mysqlPort ?? this.mysqlPort,
      mysqlUser: mysqlUser ?? this.mysqlUser,
      mysqlPassword: mysqlPassword ?? this.mysqlPassword,
      mysqlDatabase: mysqlDatabase ?? this.mysqlDatabase,
      mysqlTable: mysqlTable ?? this.mysqlTable,
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      apiToken: apiToken ?? this.apiToken,
      syncIntervalMinutes: syncIntervalMinutes ?? this.syncIntervalMinutes,
      autoSyncEnabled: autoSyncEnabled ?? this.autoSyncEnabled,
      useHttpMode: useHttpMode ?? this.useHttpMode,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }
}