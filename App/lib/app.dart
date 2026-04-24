import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mindiff_app/utils/theme.dart';
import 'package:mindiff_app/pages/login_page.dart';
import 'package:mindiff_app/navigation_menu.dart';
import 'package:mindiff_app/controllers/theme_controller.dart';
import 'package:mindiff_app/controllers/user_profile_controller.dart';
import 'package:mindiff_app/services/api_client.dart';
import 'package:mindiff_app/controllers/active_programme_controller.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.put(ThemeController(), permanent: true);
    Get.put(UserProfileController(), permanent: true);

    final isAuthenticated = Get.find<ApiClient>().isAuthenticated;

    return Obx(() => GetMaterialApp(
      title: 'Mindiff',
      themeMode: themeController.themeMode.value,
      theme: TAppTheme.LightTheme,
      darkTheme: TAppTheme.DarkTheme,
      home: isAuthenticated ? const NavigationMenu() : const LoginPage(),
    ));
  }
}