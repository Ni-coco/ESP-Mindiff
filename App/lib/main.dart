import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:mindiff_app/app.dart';
import 'package:mindiff_app/config/app_config.dart';
import 'package:mindiff_app/services/api_client.dart';
import 'package:mindiff_app/services/auth_service.dart';
// 👉 AJOUT DE L'IMPORT DU CONSENT SERVICE
import 'package:mindiff_app/services/consent_service.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    // Keep defaults when no local .env exists.
  }
  
  await Get.putAsync(
    () => ApiClient(baseUrl: AppConfig.apiBaseUrl).init(),
    permanent: true,
  );
  
  // 👉 C'est parfait ici !
  await Get.putAsync(() => ConsentService().init());
  
  Get.put(AuthService(), permanent: true);
  runApp(const App());
}