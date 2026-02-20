import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mindiff_app/controllers/user_profile_controller.dart';
import 'package:mindiff_app/utils/theme.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final userProfileController = Get.find<UserProfileController>();
    final isDark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: isDark ? TColors.darkBackground : Colors.white,
      body: SafeArea(
        child: Obx(() {
          final profile = userProfileController.profile.value;
          final name = profile?.firstName ?? 'Bienvenue';
          final goalKey = userProfileController.primaryGoal.value;
          final sessions = userProfileController.sessionsPerWeek.value;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, name, isDark),
                const SizedBox(height: 20),
                _buildTodaySummary(context, isDark, goalKey, sessions),
                const SizedBox(height: 20),
                _buildQuickMetricsRow(context, isDark, profile),
                const SizedBox(height: 20),
                _buildMealIdeas(context, isDark),
                const SizedBox(height: 20),
                _buildInspiration(context, isDark),
                const SizedBox(height: 16),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String name, bool isDark) {
    final greeting = _greeting();
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 14,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: THelperFunctions.textColor(context),
                  ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? Colors.grey[900] : Colors.grey[200],
          ),
          child: const Icon(Iconsax.notification, size: 20),
        ),
      ],
    );
  }

  Widget _buildTodaySummary(
    BuildContext context,
    bool isDark,
    String? goalKey,
    int? sessionsPerWeek,
  ) {
    final goal = _goalLabel(goalKey) ?? 'Rester en forme';
    final sessionsText =
        sessionsPerWeek != null ? '$sessionsPerWeek séances prévues cette semaine' : 'Fixe-toi un objectif de séances';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            TColors.primary,
            TColors.primary.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.activity, color: Colors.white.withOpacity(0.9), size: 20),
              const SizedBox(width: 8),
              Text(
                'Aujourd\'hui',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            goal,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            sessionsText,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickMetricsRow(
    BuildContext context,
    bool isDark,
    dynamic profile,
  ) {
    final weight = profile?.weightKg as double?;
    final height = profile?.heightCm as double?;
    final bmi = (weight != null && height != null)
        ? (weight / ((height / 100) * (height / 100)))
        : null;

    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            icon: Iconsax.weight,
            label: 'Poids',
            value: weight != null ? '${weight.toStringAsFixed(1)} kg' : '--',
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            icon: Iconsax.chart_2,
            label: 'IMC',
            value: bmi != null ? bmi.toStringAsFixed(1) : '--',
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildMealIdeas(BuildContext context, bool isDark) {
    final meals = [
      _MealIdea(
        title: 'Petit-déjeuner énergie',
        subtitle: 'Protéines + fibres pour bien démarrer',
        kcal: 420,
      ),
      _MealIdea(
        title: 'Déjeuner équilibré',
        subtitle: 'Poulet, quinoa, légumes verts',
        kcal: 650,
      ),
      _MealIdea(
        title: 'Dîner léger',
        subtitle: 'Poisson, légumes rôtis',
        kcal: 480,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Iconsax.health, size: 18, color: TColors.primary),
            const SizedBox(width: 6),
            Text(
              'Idées de repas',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: THelperFunctions.textColor(context),
                  ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: meals.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final meal = meals[index];
              return _MealCard(meal: meal, isDark: isDark);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInspiration(BuildContext context, bool isDark) {
    final quotes = [
      'Un petit pas chaque jour vaut mieux qu’un grand pas jamais fait.',
      'Ton corps entend tout ce que pense ton esprit.',
      'La constance bat toujours l’intensité.',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Iconsax.quote_down, size: 18, color: TColors.primary),
            const SizedBox(width: 6),
            Text(
              'Inspiration du jour',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: THelperFunctions.textColor(context),
                  ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...quotes.map(
          (q) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey[100],
              ),
              child: Text(
                q,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: THelperFunctions.textColor(context),
                    ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour';
    if (hour < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  String? _goalLabel(String? goal) {
    switch (goal) {
      case 'lose_weight':
        return 'Objectif: Perdre du poids';
      case 'build_muscle':
        return 'Objectif: Prendre du muscle';
      case 'maintain':
        return 'Objectif: Maintenir ton poids';
      case 'improve_endurance':
        return 'Objectif: Améliorer ton endurance';
      case 'increase_strength':
        return 'Objectif: Gagner en force';
      case 'general_fitness':
        return 'Objectif: Forme générale';
      default:
        return null;
    }
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isDark ? Colors.transparent : Colors.white,
        border: Border.all(
          color: Colors.grey.withOpacity(0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: TColors.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: THelperFunctions.textColor(context),
                ),
          ),
        ],
      ),
    );
  }
}

class _MealIdea {
  final String title;
  final String subtitle;
  final int kcal;

  _MealIdea({required this.title, required this.subtitle, required this.kcal});
}

class _MealCard extends StatelessWidget {
  final _MealIdea meal;
  final bool isDark;

  const _MealCard({required this.meal, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? Colors.transparent : Colors.white,
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                meal.title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: THelperFunctions.textColor(context),
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: TColors.primary.withValues(alpha: 0.08),
                ),
                child: Text(
                  '${meal.kcal} kcal',
                  style: TextStyle(
                    color: TColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            meal.subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Voir les détails',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: TColors.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}