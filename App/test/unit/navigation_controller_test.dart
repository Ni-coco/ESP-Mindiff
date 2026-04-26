import 'package:flutter_test/flutter_test.dart';
import 'package:mindiff_app/navigation_menu.dart';

void main() {
  group('NavigationController', () {
    test('initialise destinations et screens avec la même taille', () {
      final controller = NavigationController();
      expect(controller.destinations.length, controller.screens.length);
      expect(controller.screens, isNotEmpty);
    });

    test('onInit corrige un index invalide', () {
      final controller = NavigationController();
      controller.selectedIndex.value = -1;

      controller.onInit();

      expect(controller.selectedIndex.value, 0);
    });

    test('onReady corrige un index trop grand', () {
      final controller = NavigationController();
      controller.selectedIndex.value = 999;

      controller.onReady();

      expect(controller.selectedIndex.value, 0);
    });
  });
}
