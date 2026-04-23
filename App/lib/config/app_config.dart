import "package:flutter_dotenv/flutter_dotenv.dart";

class AppConfig {
  static const String _defaultApiBaseUrl = "http://localhost:8000/api";

  static String get apiBaseUrl {
    final value = dotenv.env["API_BASE_URL"]?.trim();
    if (value == null || value.isEmpty) {
      return _defaultApiBaseUrl;
    }
    return value;
  }
}
