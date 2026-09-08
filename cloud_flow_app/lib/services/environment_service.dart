import 'dart:convert';
import 'package:flutter/services.dart';

class EnvironmentService {
  static const String assetPath = 'assets/env.json';

  static Future<Map<String, String>> loadEnvironments() async {
    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final dynamic decoded = jsonDecode(jsonString);

      if (decoded is! Map<String, dynamic>) {
        return const {};
      }

      final Map<String, String> environments = {};

      final aws = decoded['AWS_API_URL'] as String?;
      if (aws != null && aws.trim().isNotEmpty) {
        environments['AWS'] = aws.trim();
      }

      final azure = decoded['AZURE_API_URL'] as String?;
      if (azure != null && azure.trim().isNotEmpty) {
        environments['Azure'] = azure.trim();
      }

      return environments;
    } catch (_) {
      return const {};
    }
  }
}
