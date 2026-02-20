import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mindiff_app/controllers/theme_controller.dart';
import 'package:mindiff_app/controllers/user_profile_controller.dart';
import 'package:mindiff_app/features/user_profile/domain/entities/user.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final userProfileController = Get.find<UserProfileController>();
    final themeController = Get.find<ThemeController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Mon Profil'), centerTitle: true),
      body: Obx(() {
        final user = userProfileController.profile.value;

        if (user == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_outline, size: 44),
                  const SizedBox(height: 12),
                  const Text(
                    "Profil non initialisé",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Termine l'inscription pour enregistrer tes infos et débloquer les courbes de progression.",
                    style: TextStyle(color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final goalLabel = _goalLabel(userProfileController.primaryGoal.value);
        final sessions = userProfileController.sessionsPerWeek.value;
        final targetWeight = userProfileController.targetWeight.value;

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _buildHeader(user),
            const SizedBox(height: 32),

            Card(
              child: Obx(() {
                final isDark = themeController.themeMode.value == ThemeMode.dark;
                return ListTile(
                  leading: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: Colors.blue),
                  title: const Text('Mode Sombre'),
                  trailing: Switch(
                    value: isDark,
                    onChanged: (_) => themeController.toggleTheme(),
                  ),
                );
              }),
            ),

            const SizedBox(height: 16),

            _InfoTile(
              label: "Objectif",
              value: goalLabel ?? (user.sportObjective ?? '--'),
              icon: Icons.flag_outlined,
            ),
            _InfoTile(
              label: "Séances / semaine",
              value: sessions?.toString() ?? '--',
              icon: Icons.calendar_month_outlined,
            ),
            _InfoTile(
              label: "Poids",
              value: user.weightKg != null ? "${user.weightKg!.toStringAsFixed(1)} kg" : "--",
              icon: Icons.fitness_center,
            ),
            _InfoTile(
              label: "Taille",
              value: user.heightCm != null ? "${user.heightCm!.toStringAsFixed(0)} cm" : "--",
              icon: Icons.height,
            ),
            _InfoTile(
              label: "Poids cible",
              value: targetWeight != null ? "${targetWeight.toStringAsFixed(1)} kg" : "--",
              icon: Icons.track_changes_outlined,
            ),

            const SizedBox(height: 32),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red,
              ),
              onPressed: () => Get.offAllNamed('/login'),
              icon: const Icon(Icons.logout),
              label: const Text("Déconnexion"),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildHeader(UserProfile user) {
    final initial = (user.firstName.isNotEmpty ? user.firstName[0] : '?').toUpperCase();
    return Column(
      children: [
        CircleAvatar(radius: 45, child: Text(initial)),
        const SizedBox(height: 12),
        Text("${user.firstName} ${user.lastName}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(user.email, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  String? _goalLabel(String? goal) {
    switch (goal) {
      case 'lose_weight':
        return 'Perdre du poids';
      case 'build_muscle':
        return 'Prendre du muscle';
      case 'maintain':
        return 'Maintenir mon poids';
      case 'improve_endurance':
        return 'Améliorer l\'endurance';
      case 'increase_strength':
        return 'Augmenter la force';
      case 'general_fitness':
        return 'Forme générale';
      default:
        return null;
    }
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _InfoTile({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}