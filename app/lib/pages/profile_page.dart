import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mindiff_app/controllers/theme_controller.dart';
import 'package:mindiff_app/utils/theme.dart';
import 'package:mindiff_app/pages/register_onboarding_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    
    return Scaffold(
      backgroundColor: THelperFunctions.backgroundColor(context),
      appBar: AppBar(
        title: const Text('Profil'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paramètres',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: THelperFunctions.textColor(context),
              ),
            ),
            const SizedBox(height: 24),
            Obx(() => Card(
              child: ListTile(
                leading: Icon(
                  themeController.isDarkMode(context)
                      ? Icons.dark_mode
                      : Icons.light_mode,
                  color: TColors.primary,
                ),
                title: Text(
                  'Thème',
                  style: TextStyle(
                    color: THelperFunctions.textColor(context),
                  ),
                ),
                subtitle: Text(
                  themeController.themeMode.value == ThemeMode.system
                      ? 'Système'
                      : themeController.themeMode.value == ThemeMode.dark
                          ? 'Sombre'
                          : 'Clair',
                  style: TextStyle(
                    color: THelperFunctions.isDarkMode(context)
                        ? Colors.grey[400]
                        : Colors.grey[600],
                  ),
                ),
                trailing: Switch(
                  value: themeController.isDarkMode(context),
                  onChanged: (value) {
                    themeController.toggleTheme();
                  },
                  activeColor: TColors.primary,
                ),
                onTap: () {
                  themeController.toggleTheme();
                },
              ),
            )),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.logout,
                  color: Colors.red,
                ),
                title: Text(
                  'Déconnexion',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  // Déconnexion sans confirmation
                  Get.offAll(() => const RegisterOnboardingPage());
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}