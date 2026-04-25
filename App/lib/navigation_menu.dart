import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mindiff_app/pages/home_page.dart';
import 'package:mindiff_app/pages/programme_page.dart';
import 'package:mindiff_app/pages/camera_page.dart';
import 'package:mindiff_app/pages/nutrition_page.dart';
import 'package:mindiff_app/pages/metrics_page.dart';
import 'package:mindiff_app/pages/profile_page.dart';
import 'package:mindiff_app/utils/theme.dart';

class NavigationMenu extends StatelessWidget {
  const NavigationMenu({super.key});

  @override
  Widget build(BuildContext context) {
    if (Get.isRegistered<NavigationController>()) {
      Get.delete<NavigationController>();
    }
    final controller = Get.put(NavigationController());
    final darkMode = THelperFunctions.isDarkMode(context);

    final destinations = controller.destinations;

    return Scaffold(
      bottomNavigationBar: Obx(() => Container(
        decoration: BoxDecoration(
          border: darkMode 
              ? null 
              : Border(
                  top: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
        ),
        child: NavigationBar(
          height: 80,
          elevation: 0,
          selectedIndex: controller.selectedIndex.value,
          onDestinationSelected: (index) => controller.selectedIndex.value = index,
          backgroundColor: darkMode ? Colors.black : Colors.white,
          indicatorColor: darkMode ? TColors.white.withValues(alpha: 0.1) : TColors.black.withValues(alpha: 0.1),

          destinations: destinations,
        ),
      )),
      body: Obx(() {
        final index = controller.selectedIndex.value;
        // Protection contre les index invalides
        if (index >= 0 && index < controller.screens.length) {
          return controller.screens[index];
        }
        return controller.screens[0];
      }),
    );
  }
}

class NavigationController extends GetxController {
  final Rx<int> selectedIndex = 0.obs;
  static bool get isPoseDetectionSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  late final List<Widget> screens;
  late final List<NavigationDestination> destinations;

  NavigationController() {
    destinations = [
      const NavigationDestination(icon: Icon(Iconsax.home), label: 'Home'),
      const NavigationDestination(
          icon: Icon(Iconsax.activity), label: 'Programme'),
      if (isPoseDetectionSupported)
        const NavigationDestination(icon: Icon(Iconsax.camera), label: 'Caméra'),
      const NavigationDestination(icon: Icon(Iconsax.health), label: 'Nutrition'),
      const NavigationDestination(
          icon: Icon(Iconsax.chart_2), label: 'Métriques'),
      const NavigationDestination(icon: Icon(Iconsax.user), label: 'Profil'),
    ];

    screens = [
      const HomePage(),
      const ProgrammePage(),
      if (isPoseDetectionSupported) const CameraPage(),
      const NutritionPage(),
      const MetricsPage(),
      const ProfilePage(),
    ];
  }

  @override
  void onInit() {
    super.onInit();
    // S'assurer que l'index est valide au démarrage
    if (selectedIndex.value >= screens.length || selectedIndex.value < 0) {
      selectedIndex.value = 0;
    }
  }

  @override
  void onReady() {
    super.onReady();
    // Vérifier à nouveau que l'index est valide
    if (selectedIndex.value >= screens.length || selectedIndex.value < 0) {
      selectedIndex.value = 0;
    }
  }
}