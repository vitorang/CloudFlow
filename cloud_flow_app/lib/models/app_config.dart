class AppConfig {
  final String name;
  final String apiUrl;
  final String webSocketUrl;

  const AppConfig({
    required this.name,
    required this.apiUrl,
    required this.webSocketUrl,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      name: json['name'] as String? ?? '',
      apiUrl: json['apiUrl'] as String? ?? '',
      webSocketUrl: json['webSocketUrl'] as String? ?? '',
    );
  }
}
