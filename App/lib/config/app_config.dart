import "package:flutter_dotenv/flutter_dotenv.dart";

class AppConfig {
  static const String _defaultApiBaseUrl = "http://localhost:8000/api";

  static String get apiBaseUrl {
    const valueFromDefine = String.fromEnvironment("API_BASE_URL");
    if (valueFromDefine.isNotEmpty) {
      return valueFromDefine.trim();
    }

    final valueFromDotEnv = dotenv.env["API_BASE_URL"]?.trim();
    if (valueFromDotEnv != null && valueFromDotEnv.isNotEmpty) {
      return valueFromDotEnv;
    }

    return _defaultApiBaseUrl;
  }
}
