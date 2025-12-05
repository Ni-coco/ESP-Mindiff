import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mindiff_app/utils/theme.dart';
import 'package:mindiff_app/pages/register_onboarding_page.dart';
import 'package:mindiff_app/controllers/theme_controller.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.put(ThemeController(), permanent: true);
    
    return Obx(() => GetMaterialApp(
      title: 'Mindiff',
      themeMode: themeController.themeMode.value,
      theme: TAppTheme.LightTheme,
      darkTheme: TAppTheme.DarkTheme,
      // For testing: show registration page initially
      home: const RegisterOnboardingPage(),
      // home: const NavigationMenu(), // Uncomment this when you want to skip registration
    ));
  }
}