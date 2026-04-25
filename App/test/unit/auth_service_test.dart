import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mindiff_app/services/api_client.dart';
import 'package:mindiff_app/services/auth_service.dart';

class FakeApiClient extends ApiClient {
  FakeApiClient() : super(baseUrl: 'http://fake');

  String? lastPath;
  Map<String, dynamic>? lastBody;
  dynamic response;
  String? storedToken;

  @override
  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    lastPath = path;
    lastBody = body;
    return response;
  }

  @override
  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    lastPath = path;
    lastBody = body;
    return response;
  }

  @override
  Future<dynamic> get(String path) async {
    lastPath = path;
    return response;
  }

  @override
  Future<void> setToken(String token) async {
    storedToken = token;
  }

  @override
  Future<void> clearToken() async {
    storedToken = null;
  }
}

void main() {
  late FakeApiClient apiClient;
  late AuthService authService;

  setUp(() {
    Get.testMode = true;
    Get.reset();
    apiClient = FakeApiClient();
    Get.put<ApiClient>(apiClient);
    authService = AuthService();
  });

  tearDown(Get.reset);

  test('register dérive username depuis le nom', () async {
    apiClient.response = {'id': 1, 'email': 'nico@example.com'};

    final res = await authService.register(
      email: 'nico@example.com',
      password: 'Password123!',
      name: 'Nicolas Garde',
    );

    expect(res['id'], 1);
    expect(apiClient.lastPath, '/auth/register');
    expect(apiClient.lastBody, {
      'email': 'nico@example.com',
      'username': 'nicolas_garde',
      'password': 'Password123!',
    });
  });

  test('login sauvegarde le token', () async {
    apiClient.response = {'access_token': 'jwt-token'};

    await authService.login(email: 'a@a.com', password: 'secret');

    expect(apiClient.lastPath, '/auth/login');
    expect(apiClient.lastBody, {
      'email': 'a@a.com',
      'password': 'secret',
    });
    expect(apiClient.storedToken, 'jwt-token');
  });

  test('updateUserProfile inclut metrics seulement si complet', () async {
    apiClient.response = {};

    await authService.updateUserProfile(
      7,
      email: 'u@example.com',
      username: 'user',
      weight: 80,
      height: 180,
      age: 25,
      healthConsiderations: '',
    );

    expect(apiClient.lastPath, '/user/7');
    expect(apiClient.lastBody, {
      'email': 'u@example.com',
      'username': 'user',
      'metrics': {
        'weight': 80.0,
        'actual_weight': 80.0,
        'height': 180,
        'age': 25,
      },
    });
  });

  test('getExercises construit la route de recherche textuelle', () async {
    apiClient.response = [];

    await authService.getExercises(q: 'bench press', limit: 10);

    expect(apiClient.lastPath, '/exercise/filter?q=bench%20press&limit=10');
  });
}
