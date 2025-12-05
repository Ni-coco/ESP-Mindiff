import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ThemeController extends GetxController {
  final Rx<ThemeMode> themeMode = ThemeMode.system.obs;

  bool isDarkMode(BuildContext? context) {
    if (themeMode.value == ThemeMode.system) {
      if (context != null) {
        return MediaQuery.of(context).platformBrightness == Brightness.dark;
      }
      return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
    return themeMode.value == ThemeMode.dark;
  }

  void toggleTheme() {
    if (themeMode.value == ThemeMode.light) {
      themeMode.value = ThemeMode.dark;
    } else if (themeMode.value == ThemeMode.dark) {
      themeMode.value = ThemeMode.light;
    } else {
      // If system, switch to dark
      themeMode.value = ThemeMode.dark;
    }
  }

  void setThemeMode(ThemeMode mode) {
    themeMode.value = mode;
  }
}

