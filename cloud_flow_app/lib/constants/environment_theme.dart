import 'package:flutter/material.dart';

class EnvironmentTheme {
  static Color getPrimaryColor(String? environment) {
    return switch (environment) {
      'AWS' => Colors.green,
      'Azure' => Colors.blue,
      _ => Colors.grey,
    };
  }
}
