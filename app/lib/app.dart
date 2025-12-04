import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mindiff_app/utils/theme.dart';
import 'package:mindiff_app/pages/register_onboarding_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Mindiff',
      themeMode: ThemeMode.system,
      theme: TAppTheme.LightTheme,
      darkTheme: TAppTheme.DarkTheme,
      // For testing: show registration page initially
      home: const RegisterOnboardingPage(),
      // home: const NavigationMenu(), // Uncomment this when you want to skip registration
    );
  }
}