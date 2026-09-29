import 'package:flutter/foundation.dart';

abstract final class ApiConfig {
  static String get baseUrl {
    const configuredUrl = String.fromEnvironment('API_BASE_URL');

    if (configuredUrl.isNotEmpty) {
      return configuredUrl;
    }

    if (kIsWeb) {
      return 'http://localhost:8000';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://127.0.0.1:8000';
    }

    return 'http://localhost:8000';
  }
}
