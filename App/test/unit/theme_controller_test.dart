import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindiff_app/controllers/theme_controller.dart';

void main() {
  group('ThemeController', () {
    test('toggleTheme alterne light -> dark -> light', () {
      final controller = ThemeController();
      controller.setThemeMode(ThemeMode.light);

      controller.toggleTheme();
      expect(controller.themeMode.value, ThemeMode.dark);

      controller.toggleTheme();
      expect(controller.themeMode.value, ThemeMode.light);
    });

    test('toggleTheme passe à dark depuis system', () {
      final controller = ThemeController();
      controller.setThemeMode(ThemeMode.system);

      controller.toggleTheme();

      expect(controller.themeMode.value, ThemeMode.dark);
    });
  });
}
