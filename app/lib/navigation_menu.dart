import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mindiff_app/pages/home_page.dart';
import 'package:mindiff_app/pages/programme_page.dart';
import 'package:mindiff_app/pages/nutrition_page.dart';
import 'package:mindiff_app/pages/metrics_page.dart';
import 'package:mindiff_app/pages/profile_page.dart';
import 'package:mindiff_app/utils/theme.dart';

class NavigationMenu extends StatelessWidget {
  const NavigationMenu({super.key});

  @override
  Widget build(BuildContext context) {
    // Supprimer l'ancien contrôleur s'il existe pour éviter les problèmes de cache
    if (Get.isRegistered<NavigationController>()) {
      Get.delete<NavigationController>();
    }
    final controller = Get.put(NavigationController());
    final darkMode = THelperFunctions.isDarkMode(context);

    return Scaffold(
      bottomNavigationBar: Obx(() => NavigationBar(
        height: 80,
        elevation: 0,
        selectedIndex: controller.selectedIndex.value,
        onDestinationSelected: (index) => controller.selectedIndex.value = index,
        backgroundColor: darkMode ? Colors.black : Colors.white,
        indicatorColor: darkMode ? TColors.white.withValues(alpha: 0.1) : TColors.black.withValues(alpha: 0.1),

        destinations: const [
          NavigationDestination(icon: Icon(Iconsax.home), label: 'Home'),
          NavigationDestination(icon: Icon(Iconsax.activity), label: 'Programme'),
          NavigationDestination(icon: Icon(Iconsax.health), label: 'Nutrition'),
          NavigationDestination(icon: Icon(Iconsax.chart_2), label: 'Métriques'),
          NavigationDestination(icon: Icon(Iconsax.user), label: 'Profil'),
        ],
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

  final screens = [
    const HomePage(),
    const ProgrammePage(),
    const NutritionPage(),
    const MetricsPage(),
    const ProfilePage(),
  ];

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