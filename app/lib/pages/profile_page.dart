import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mindiff_app/controllers/theme_controller.dart';
import 'package:mindiff_app/controllers/user_profile_controller.dart';
import 'package:mindiff_app/pages/login_page.dart';
import 'package:mindiff_app/services/auth_service.dart';
import 'package:mindiff_app/utils/theme.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshProfile();
  }

  Future<void> _refreshProfile() async {
    setState(() => _isLoading = true);
    try {
      final userData = await Get.find<AuthService>().getCurrentUser();
      Get.find<UserProfileController>().setFromApiResponse(userData);
    } catch (_) {
      // En cas d'erreur réseau, on garde les données locales
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UserProfileController>();
    final themeController = Get.find<ThemeController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshProfile,
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: Obx(() {
        final user = controller.profile.value;

        if (user == null) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_outline, size: 44),
                  SizedBox(height: 12),
                  Text(
                    "Profil non initialisé",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // --- Avatar ---
            _buildHeader(context, controller),
            const SizedBox(height: 24),

            // --- Infos personnelles ---
            _SectionTitle(title: 'Informations personnelles'),
            _InfoTile(label: 'Genre', value: _genderLabel(controller.gender.value), icon: Icons.person_outline),
            _InfoTile(label: 'Âge', value: controller.age.value != null ? '${controller.age.value} ans' : '--', icon: Icons.cake_outlined),
            _InfoTile(
              label: 'Poids',
              value: user.weightKg != null ? '${user.weightKg!.toStringAsFixed(1)} kg' : '--',
              icon: Icons.monitor_weight_outlined,
            ),
            _InfoTile(
              label: 'Taille',
              value: user.heightCm != null ? '${user.heightCm!.toStringAsFixed(0)} cm' : '--',
              icon: Icons.height,
            ),

            const SizedBox(height: 16),

            // --- Objectifs ---
            _SectionTitle(title: 'Mon programme'),
            _InfoTile(
              label: 'Objectif',
              value: _goalLabel(controller.primaryGoal.value),
              icon: Icons.flag_outlined,
            ),
            _InfoTile(
              label: 'Séances / semaine',
              value: controller.sessionsPerWeek.value != null ? '${controller.sessionsPerWeek.value} séances' : '--',
              icon: Icons.calendar_month_outlined,
            ),
            _InfoTile(
              label: 'Poids cible',
              value: controller.targetWeight.value != null ? '${controller.targetWeight.value!.toStringAsFixed(1)} kg' : '--',
              icon: Icons.track_changes_outlined,
            ),

            const SizedBox(height: 16),

            // --- Paramètres ---
            _SectionTitle(title: 'Paramètres'),
            Card(
              child: Obx(() {
                final isDark = themeController.themeMode.value == ThemeMode.dark;
                return ListTile(
                  leading: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: TColors.primary),
                  title: const Text('Mode Sombre'),
                  trailing: Switch(
                    value: isDark,
                    onChanged: (_) => themeController.toggleTheme(),
                  ),
                );
              }),
            ),

            const SizedBox(height: 24),

            // --- Logout ---
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () async {
                await Get.find<AuthService>().logout();
                await Get.find<UserProfileController>().clear();
                Get.offAll(() => const LoginPage());
              },
              icon: const Icon(Icons.logout),
              label: const Text('Déconnexion'),
            ),

            const SizedBox(height: 16),
          ],
        );
      }),
    );
  }

  Widget _buildHeader(BuildContext context, UserProfileController controller) {
    final user = controller.profile.value!;
    final initial = (user.firstName.isNotEmpty ? user.firstName[0] : '?').toUpperCase();
    return Column(
      children: [
        CircleAvatar(
          radius: 48,
          backgroundColor: TColors.primary.withOpacity(0.15),
          child: Text(initial, style: TextStyle(fontSize: 36, color: TColors.primary, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 12),
        Text(
          '${user.firstName} ${user.lastName}'.trim(),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(user.email, style: TextStyle(color: Colors.grey.shade600)),
      ],
    );
  }

  String _genderLabel(String? gender) {
    switch (gender) {
      case 'male': return 'Homme';
      case 'female': return 'Femme';
      case 'other': return 'Autre';
      default: return '--';
    }
  }

  String _goalLabel(String? goal) {
    switch (goal) {
      case 'lose_weight': return 'Perdre du poids';
      case 'build_muscle': return 'Prendre du muscle';
      case 'maintain': return 'Maintenir mon poids';
      case 'improve_endurance': return 'Améliorer l\'endurance';
      case 'increase_strength': return 'Augmenter la force';
      case 'general_fitness': return 'Forme générale';
      default: return '--';
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade500,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _InfoTile({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: TColors.primary),
        title: Text(label),
        trailing: Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ),
    );
  }
}
