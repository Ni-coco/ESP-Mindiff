import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mindiff_app/services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late HttpServer server;
  late String baseUrl;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Get.testMode = true;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    baseUrl = 'http://${server.address.host}:${server.port}';
  });

  tearDown(() async {
    await server.close(force: true);
  });

  test('get retourne le JSON sur réponse 200', () async {
    server.listen((request) async {
      expect(request.uri.path, '/ok');
      request.response.statusCode = 200;
      request.response.write(jsonEncode({'status': 'ok'}));
      await request.response.close();
    });

    final client = await ApiClient(baseUrl: baseUrl).init();
    final res = await client.get('/ok') as Map<String, dynamic>;

    expect(res['status'], 'ok');
  });

  test('setToken et clearToken mettent à jour l\'état d\'auth', () async {
    final client = await ApiClient(baseUrl: baseUrl).init();
    expect(client.isAuthenticated, isFalse);

    await client.setToken('jwt-token');
    expect(client.isAuthenticated, isTrue);
    expect(client.token, 'jwt-token');

    await client.clearToken();
    expect(client.isAuthenticated, isFalse);
    expect(client.token, isNull);
  });

  test('401 sans binding widget lève FlutterError de navigation GetX', () async {
    server.listen((request) async {
      request.response.statusCode = 401;
      request.response.write(jsonEncode({'detail': 'Token invalide'}));
      await request.response.close();
    });

    final client = await ApiClient(baseUrl: baseUrl).init();
    await client.setToken('expired');

    expect(
      () => client.get('/unauthorized'),
      throwsA(isA<FlutterError>()),
    );
  });

  test('réponse 500 lève ApiException', () async {
    server.listen((request) async {
      request.response.statusCode = 500;
      request.response.write(jsonEncode({'detail': 'Internal error'}));
      await request.response.close();
    });

    final client = await ApiClient(baseUrl: baseUrl).init();

    expect(
      () => client.post('/error', {'a': 1}),
      throwsA(isA<ApiException>()),
    );
  });
}
