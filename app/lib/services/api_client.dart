import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindiff_app/pages/login_page.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(String message) : super(401, message);
}

class ApiClient extends GetxService {
  static const String _tokenKey = 'jwt_token';

  // 10.0.2.2 pour émulateur Android, localhost pour iOS/web
  final String baseUrl;

  String? _token;

  ApiClient({this.baseUrl = 'http://localhost:8082'});

  bool get isAuthenticated => _token != null;
  String? get token => _token;

  Future<ApiClient> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    return this;
  }

  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<dynamic> _handleResponse(http.Response response) async {
    final body = utf8.decode(response.bodyBytes);
    final decoded = body.isNotEmpty ? jsonDecode(body) : null;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    final message = decoded is Map ? (decoded['detail'] ?? 'Erreur inconnue').toString() : 'Erreur inconnue';

    if (response.statusCode == 401) {
      await clearToken();
      Get.offAll(() => const LoginPage());
      throw UnauthorizedException(message);
    }
    throw ApiException(response.statusCode, message);
  }

  static const _timeout = Duration(seconds: 10);

  Future<dynamic> get(String path) async {
    final response = await http
        .get(Uri.parse('$baseUrl$path'), headers: _headers)
        .timeout(_timeout);
    return await _handleResponse(response);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final response = await http
        .post(Uri.parse('$baseUrl$path'), headers: _headers, body: jsonEncode(body))
        .timeout(_timeout);
    return await _handleResponse(response);
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final response = await http
        .put(Uri.parse('$baseUrl$path'), headers: _headers, body: jsonEncode(body))
        .timeout(_timeout);
    return await _handleResponse(response);
  }

  Future<dynamic> delete(String path) async {
    final response = await http
        .delete(Uri.parse('$baseUrl$path'), headers: _headers)
        .timeout(_timeout);
    return await _handleResponse(response);
  }
}
