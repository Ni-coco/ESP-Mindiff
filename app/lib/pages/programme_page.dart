// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mindiff_app/controllers/user_profile_controller.dart';
import 'package:mindiff_app/controllers/active_programme_controller.dart';
import 'package:mindiff_app/navigation_menu.dart';
import 'package:mindiff_app/utils/theme.dart';

// ---------------------------------------------------------------------------
// Données des programmes avec exercices structurés
// ---------------------------------------------------------------------------

const _programmes = <Programme>[
  Programme(
    id: 1,
    nom: 'Perte de poids intensive',
    description:
        'Programme complet de 12 semaines pour perdre du poids de manière saine et durable',
    duree: '12 semaines',
    difficulte: 'Intermédiaire',
    caloriesParSeance: 450,
    image: '🔥',
    couleur: Color(0xFF4CAF50),
    exercices: [
      ProgrammeExercice(nom: 'Squat', emoji: '🏋️', analyzerKey: 'squat', series: 4, repsCible: 15),
      ProgrammeExercice(nom: 'Pompes', emoji: '💪', analyzerKey: 'pushup', series: 3, repsCible: 12),
      ProgrammeExercice(nom: 'Planche', emoji: '🧘', analyzerKey: 'plank', series: 3, repsCible: 30, isSeconds: true),
      ProgrammeExercice(nom: 'Dips', emoji: '🤸', analyzerKey: 'dips', series: 3, repsCible: 10),
    ],
  ),
  Programme(
    id: 2,
    nom: 'Gain de masse musculaire',
    description:
        'Programme de musculation pour développer votre masse musculaire efficacement',
    duree: '16 semaines',
    difficulte: 'Avancé',
    caloriesParSeance: 600,
    image: '💪',
    couleur: Color(0xFF2196F3),
    exercices: [
      ProgrammeExercice(nom: 'Squat', emoji: '🏋️', analyzerKey: 'squat', series: 4, repsCible: 12),
      ProgrammeExercice(nom: 'Développé couché', emoji: '🛋️', analyzerKey: 'bench', series: 4, repsCible: 10),
      ProgrammeExercice(nom: 'Tractions', emoji: '🧗', analyzerKey: 'pullup', series: 3, repsCible: 10),
      ProgrammeExercice(nom: 'Curl biceps', emoji: '💪', analyzerKey: 'curl', series: 3, repsCible: 12),
      ProgrammeExercice(nom: 'Développé épaules', emoji: '🏋️', analyzerKey: 'ohp', series: 3, repsCible: 10),
    ],
  ),
  Programme(
    id: 3,
    nom: 'Renforcement complet',
    description:
        'Programme équilibré pour renforcer l\'ensemble du corps',
    duree: '8 semaines',
    difficulte: 'Débutant',
    caloriesParSeance: 300,
    image: '⚡',
    couleur: Color(0xFF9C27B0),
    exercices: [
      ProgrammeExercice(nom: 'Squat', emoji: '🏋️', analyzerKey: 'squat', series: 3, repsCible: 10),
      ProgrammeExercice(nom: 'Pompes', emoji: '💪', analyzerKey: 'pushup', series: 3, repsCible: 8),
      ProgrammeExercice(nom: 'Rowing', emoji: '🚣', analyzerKey: 'row', series: 3, repsCible: 10),
      ProgrammeExercice(nom: 'Planche', emoji: '🧘', analyzerKey: 'plank', series: 3, repsCible: 20, isSeconds: true),
    ],
  ),
  Programme(
    id: 4,
    nom: 'Upper body',
    description:
        'Focalisé sur le haut du corps : pectoraux, dos, épaules et bras',
    duree: '10 semaines',
    difficulte: 'Intermédiaire',
    caloriesParSeance: 500,
    image: '🦾',
    couleur: Color(0xFFF44336),
    exercices: [
      ProgrammeExercice(nom: 'Développé couché', emoji: '🛋️', analyzerKey: 'bench', series: 4, repsCible: 10),
      ProgrammeExercice(nom: 'Tractions', emoji: '🧗', analyzerKey: 'pullup', series: 4, repsCible: 8),
      ProgrammeExercice(nom: 'Développé épaules', emoji: '🏋️', analyzerKey: 'ohp', series: 3, repsCible: 10),
      ProgrammeExercice(nom: 'Curl biceps', emoji: '💪', analyzerKey: 'curl', series: 3, repsCible: 12),
      ProgrammeExercice(nom: 'Dips', emoji: '🤸', analyzerKey: 'dips', series: 3, repsCible: 10),
    ],
  ),
  Programme(
    id: 5,
    nom: 'Renforcement du dos',
    description:
        'Programme spécialisé pour renforcer votre dos et prévenir les douleurs',
    duree: '6 semaines',
    difficulte: 'Débutant',
    caloriesParSeance: 250,
    image: '🔙',
    couleur: Color(0xFFFF9800),
    exercices: [
      ProgrammeExercice(nom: 'Rowing', emoji: '🚣', analyzerKey: 'row', series: 3, repsCible: 12),
      ProgrammeExercice(nom: 'Tractions', emoji: '🧗', analyzerKey: 'pullup', series: 3, repsCible: 8),
      ProgrammeExercice(nom: 'Planche', emoji: '🧘', analyzerKey: 'plank', series: 3, repsCible: 30, isSeconds: true),
    ],
  ),
  Programme(
    id: 6,
    nom: 'HIIT Express',
    description: 'Séances courtes et intenses pour des résultats rapides',
    duree: '4 semaines',
    difficulte: 'Avancé',
    caloriesParSeance: 400,
    image: '⚡',
    couleur: Color(0xFF00BCD4),
    exercices: [
      ProgrammeExercice(nom: 'Squat', emoji: '🏋️', analyzerKey: 'squat', series: 4, repsCible: 20),
      ProgrammeExercice(nom: 'Pompes', emoji: '💪', analyzerKey: 'pushup', series: 4, repsCible: 15),
      ProgrammeExercice(nom: 'Dips', emoji: '🤸', analyzerKey: 'dips', series: 3, repsCible: 12),
      ProgrammeExercice(nom: 'Planche', emoji: '🧘', analyzerKey: 'plank', series: 3, repsCible: 45, isSeconds: true),
    ],
  ),
];

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

class ProgrammePage extends StatelessWidget {
  const ProgrammePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);
    final userCtrl = Get.find<UserProfileController>();
    final activeCtrl = Get.find<ActiveProgrammeController>();

    return Obx(() {
      final goal = userCtrl.primaryGoal.value;
      final sessions = userCtrl.sessionsPerWeek.value;
      final recommendedIds = _recommendedProgrammeIds(goal, sessions);

      final orderedProgrammes = [
        ..._programmes.where((p) => recommendedIds.contains(p.id)),
        ..._programmes.where((p) => !recommendedIds.contains(p.id)),
      ];

      return Scaffold(
        backgroundColor: isDark ? TColors.darkBackground : Colors.white,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre
              Row(
                children: [
                  Icon(Iconsax.activity, color: TColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Programmes',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: THelperFunctions.textColor(context),
                          fontSize: 22,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ── Programme actif ────────────────────────────────────────
              if (activeCtrl.hasActive)
                _ActiveProgrammeBanner(
                  data: activeCtrl.activeProgramme.value!,
                  isDark: isDark,
                  onStop: () => _confirmStop(context, activeCtrl),
                  onNewSeance: () => activeCtrl.nouvelleSeance(),
                  onGoToCamera: () {
                    final navCtrl = Get.find<NavigationController>();
                    navCtrl.selectedIndex.value = 2;
                  },
                ),

              if (recommendedIds.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: _RecommendationBanner(
                    text: _recommendationText(goal, sessions),
                    isDark: isDark,
                  ),
                ),
              Text(
                '${_programmes.length} programmes disponibles',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 14,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Choisissez le programme qui correspond à vos objectifs',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 14,
                    ),
              ),
              const SizedBox(height: 24),

              // Liste des programmes
              ...orderedProgrammes.map((programme) => Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildProgrammeCard(
                      context,
                      programme,
                      isDark,
                      isRecommended: recommendedIds.contains(programme.id),
                      isActive: activeCtrl.activeProgramme.value
                              ?.programmeId ==
                          programme.id,
                    ),
                  )),
            ],
          ),
        ),
      );
    });
  }

  // ── Card programme ─────────────────────────────────────────────────────

  Widget _buildProgrammeCard(
    BuildContext context,
    Programme programme,
    bool isDark, {
    required bool isRecommended,
    required bool isActive,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.transparent : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? programme.couleur.withOpacity(0.5)
              : Colors.grey.withOpacity(0.15),
          width: isActive ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showProgrammeDetails(context, programme, isDark),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isActive)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: programme.couleur.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Programme actif',
                      style: TextStyle(
                        color: programme.couleur,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                )
              else if (isRecommended)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: TColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Recommandé pour toi',
                      style: TextStyle(
                        color: TColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: programme.couleur.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(programme.image,
                          style: const TextStyle(fontSize: 32)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          programme.nom,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: THelperFunctions.textColor(context),
                                fontSize: 18,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          programme.description,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                                fontSize: 13,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildInfoChip(
                      context, Iconsax.clock, programme.duree, isDark),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    context,
                    Iconsax.star,
                    programme.difficulte,
                    isDark,
                    color: _getDifficultyColor(programme.difficulte),
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    context,
                    Iconsax.flash,
                    '${programme.caloriesParSeance} kcal',
                    isDark,
                    color: Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Iconsax.document,
                      size: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${programme.exercices.length} exercices',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              isDark ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 12,
                        ),
                  ),
                  const Spacer(),
                  Icon(Iconsax.arrow_right_3,
                      size: 16, color: TColors.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bottom sheet détail ─────────────────────────────────────────────────

  void _showProgrammeDetails(
      BuildContext context, Programme programme, bool isDark) {
    final activeCtrl = Get.find<ActiveProgrammeController>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? TColors.darkBackground : Colors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: programme.couleur.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(programme.image,
                                  style: const TextStyle(fontSize: 48)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  programme.nom,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: THelperFunctions.textColor(
                                            context),
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  programme.description,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: isDark
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Stats
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(context, Iconsax.clock,
                                'Durée', programme.duree, isDark),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              Iconsax.star,
                              'Difficulté',
                              programme.difficulte,
                              isDark,
                              color: _getDifficultyColor(
                                  programme.difficulte),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                                context,
                                Iconsax.document,
                                'Exercices',
                                '${programme.exercices.length}',
                                isDark),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              Iconsax.flash,
                              'Calories',
                              '${programme.caloriesParSeance} kcal',
                              isDark,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Exercices
                      Text(
                        'Exercices inclus',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: THelperFunctions.textColor(context),
                            ),
                      ),
                      const SizedBox(height: 12),
                      ...programme.exercices.map((ex) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Text(ex.emoji,
                                    style: const TextStyle(fontSize: 20)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ex.nom,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  THelperFunctions.textColor(
                                                      context),
                                            ),
                                      ),
                                      Text(
                                        '${ex.series} séries × ${ex.repsCible} ${ex.isSeconds ? 'sec' : 'reps'}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: isDark
                                                  ? Colors.grey[400]
                                                  : Colors.grey[600],
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ),
              // Bouton démarrer
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Obx(() {
                  final isActive = activeCtrl.activeProgramme.value
                          ?.programmeId ==
                      programme.id;
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isActive
                          ? null
                          : () {
                              activeCtrl.demarrer(
                                programmeId: programme.id,
                                nom: programme.nom,
                                couleurValue: programme.couleur.value,
                                exercices: programme.exercices,
                              );
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Programme "${programme.nom}" démarré !'),
                                  backgroundColor: programme.couleur,
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: programme.couleur,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isActive
                            ? 'Programme en cours'
                            : 'Démarrer le programme',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Confirmation arrêt ─────────────────────────────────────────────────

  void _confirmStop(
      BuildContext context, ActiveProgrammeController ctrl) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Arrêter le programme ?'),
        content: const Text(
            'Ta progression sera perdue. Tu pourras redémarrer le programme plus tard.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              ctrl.arreter();
              Navigator.pop(ctx);
            },
            child:
                const Text('Arrêter', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  Widget _buildInfoChip(
    BuildContext context,
    IconData icon,
    String text,
    bool isDark, {
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (color ?? TColors.primary).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color ?? TColors.primary),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color ?? TColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    bool isDark, {
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.transparent : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color ?? TColors.primary),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 12,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color ?? THelperFunctions.textColor(context),
                ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String d) {
    switch (d) {
      case 'Débutant':
        return Colors.green;
      case 'Intermédiaire':
        return Colors.orange;
      case 'Avancé':
        return Colors.red;
      default:
        return TColors.primary;
    }
  }

  List<int> _recommendedProgrammeIds(String? goal, int? sessionsPerWeek) {
    final base = switch (goal) {
      'lose_weight' => <int>[1, 6],
      'build_muscle' => <int>[2],
      'increase_strength' => <int>[2],
      'improve_endurance' => <int>[4, 6],
      'general_fitness' => <int>[4, 1],
      'maintain' => <int>[4, 3],
      _ => <int>[],
    };
    final sessions = sessionsPerWeek ?? 0;
    if (sessions <= 2) {
      return [...<int>[3, 5], ...base].toSet().toList();
    }
    return [...base].toSet().toList();
  }

  String _recommendationText(String? goal, int? sessionsPerWeek) {
    final goalLabel = switch (goal) {
      'lose_weight' => 'Perdre du poids',
      'build_muscle' => 'Prendre du muscle',
      'maintain' => 'Maintenir',
      'improve_endurance' => 'Endurance',
      'increase_strength' => 'Force',
      'general_fitness' => 'Forme générale',
      _ => null,
    };
    final sessions = sessionsPerWeek;
    if (goalLabel == null && sessions == null) {
      return 'Sélection basée sur ton profil';
    }
    if (goalLabel != null && sessions != null) {
      return 'Sélection basée sur "$goalLabel" • $sessions séances/sem.';
    }
    if (goalLabel != null) return 'Sélection basée sur "$goalLabel"';
    return 'Sélection basée sur $sessions séances/sem.';
  }
}

// ---------------------------------------------------------------------------
// Banner programme actif
// ---------------------------------------------------------------------------

class _ActiveProgrammeBanner extends StatelessWidget {
  final ActiveProgrammeData data;
  final bool isDark;
  final VoidCallback onStop;
  final VoidCallback onNewSeance;
  final VoidCallback onGoToCamera;

  const _ActiveProgrammeBanner({
    required this.data,
    required this.isDark,
    required this.onStop,
    required this.onNewSeance,
    required this.onGoToCamera,
  });

  @override
  Widget build(BuildContext context) {
    final couleur = Color(data.couleurValue);
    final seance = data.seanceEnCours;
    final totalExos = data.exercices.length;
    final exosFaits = seance == null
        ? 0
        : data.exercices.where((ex) {
            final prog = seance.progressions[ex.analyzerKey];
            return prog != null && prog.estTermine(ex);
          }).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: couleur.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: couleur.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.play_circle, color: couleur, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  data.nom,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: THelperFunctions.textColor(context),
                  ),
                ),
              ),
              GestureDetector(
                onTap: onStop,
                child: Icon(Iconsax.close_circle,
                    color: Colors.red.withOpacity(0.7), size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progression séance
          Row(
            children: [
              Text(
                'Séance ${seance?.numero ?? data.seancesTerminees + 1}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
              const Spacer(),
              Text(
                '$exosFaits / $totalExos exercices',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Barre de progression
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: totalExos > 0 ? exosFaits / totalExos : 0,
              backgroundColor: couleur.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation(couleur),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),

          // Détail par exercice
          ...data.exercices.map((ex) {
            final prog = seance?.progressions[ex.analyzerKey];
            final fait = prog?.seriesCompletes ?? 0;
            final termine = prog != null && prog.estTermine(ex);
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    termine
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked,
                    size: 16,
                    color: termine ? couleur : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${ex.emoji} ${ex.nom}',
                    style: TextStyle(
                      fontSize: 13,
                      color: THelperFunctions.textColor(context),
                      decoration:
                          termine ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$fait / ${ex.series} séries',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 12),
          // Boutons action
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: seance != null && !seance.terminee
                      ? onGoToCamera
                      : onNewSeance,
                  icon: Icon(
                    seance != null && !seance.terminee
                        ? Iconsax.camera
                        : Iconsax.refresh,
                    size: 16,
                  ),
                  label: Text(
                    seance != null && !seance.terminee
                        ? 'Continuer la séance'
                        : 'Nouvelle séance',
                    style: const TextStyle(fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: couleur,
                    side: BorderSide(color: couleur),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),

          // Stats
          const SizedBox(height: 8),
          Text(
            '${data.seancesTerminees} séance${data.seancesTerminees > 1 ? 's' : ''} terminée${data.seancesTerminees > 1 ? 's' : ''}',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.grey[500] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recommendation banner
// ---------------------------------------------------------------------------

class _RecommendationBanner extends StatelessWidget {
  final String text;
  final bool isDark;

  const _RecommendationBanner({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.grey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(Iconsax.magic_star, size: 18, color: TColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: THelperFunctions.textColor(context),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Modèle Programme
// ---------------------------------------------------------------------------

class Programme {
  final int id;
  final String nom;
  final String description;
  final String duree;
  final String difficulte;
  final int caloriesParSeance;
  final String image;
  final Color couleur;
  final List<ProgrammeExercice> exercices;

  const Programme({
    required this.id,
    required this.nom,
    required this.description,
    required this.duree,
    required this.difficulte,
    required this.caloriesParSeance,
    required this.image,
    required this.couleur,
    required this.exercices,
  });
}
