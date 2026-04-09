import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mindiff_app/utils/theme.dart';
import 'package:mindiff_app/pages/register_onboarding_page.dart';
import 'package:mindiff_app/controllers/theme_controller.dart';
import 'package:mindiff_app/controllers/user_profile_controller.dart';
import 'package:mindiff_app/controllers/active_programme_controller.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.put(ThemeController(), permanent: true);
    // Contrôleur global pour les données utilisateur (alimenté à la fin de l'onboarding)
    Get.put(UserProfileController(), permanent: true);
    Get.put(ActiveProgrammeController(), permanent: true);
    
    return Obx(() => GetMaterialApp(
      title: 'Mindiff',
      themeMode: themeController.themeMode.value,
      theme: TAppTheme.LightTheme,
      darkTheme: TAppTheme.DarkTheme,
      // For testing: show registration page initialement
      home: const RegisterOnboardingPage(),
      // home: const NavigationMenu(), // Uncomment this when you want to skip registration
    ));
  }
}