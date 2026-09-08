class AppConfig {
  final String name;
  final String apiUrl;
  final String webSocketUrl;
  final String username;
  final String environment;
  final bool demoModeEnabled;

  const AppConfig({
    required this.name,
    required this.apiUrl,
    required this.webSocketUrl,
    this.username = '',
    this.environment = '',
    this.demoModeEnabled = false,
  });

  factory AppConfig.fromJson(
    Map<String, dynamic> json, {
    String username = '',
    String environment = '',
  }) {
    return AppConfig(
      name: json['name'] as String? ?? '',
      apiUrl: json['apiUrl'] as String? ?? '',
      webSocketUrl: json['webSocketUrl'] as String? ?? '',
      username: username,
      environment: environment,
      demoModeEnabled: json['demoModeEnabled'] as bool? ?? false,
    );
  }

  AppConfig copyWith({
    String? name,
    String? apiUrl,
    String? webSocketUrl,
    String? username,
    String? environment,
    bool? demoModeEnabled,
  }) {
    return AppConfig(
      name: name ?? this.name,
      apiUrl: apiUrl ?? this.apiUrl,
      webSocketUrl: webSocketUrl ?? this.webSocketUrl,
      username: username ?? this.username,
      environment: environment ?? this.environment,
      demoModeEnabled: demoModeEnabled ?? this.demoModeEnabled,
    );
  }
}
