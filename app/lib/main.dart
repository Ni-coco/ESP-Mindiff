import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mindiff_app/app.dart';
import 'package:mindiff_app/services/api_client.dart';
import 'package:mindiff_app/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Get.putAsync(() => ApiClient().init(), permanent: true);
  Get.put(AuthService(), permanent: true);
  runApp(const App());
}
