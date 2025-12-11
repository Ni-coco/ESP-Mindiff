import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mindiff_app/utils/theme.dart';

class ProgrammePage extends StatelessWidget {
  const ProgrammePage({super.key});

  // Données fictives des programmes
  final List<Programme> programmes = const [
    Programme(
      id: 1,
      nom: 'Perte de poids intensive',
      description: 'Programme complet de 12 semaines pour perdre du poids de manière saine et durable',
      duree: '12 semaines',
      difficulte: 'Intermédiaire',
      nombreExercices: 24,
      caloriesParSeance: 450,
      image: '',
      couleur: Color(0xFF4CAF50),
      exercices: [
        'Cardio HIIT - 20 min',
        'Renforcement musculaire - 30 min',
        'Étirements - 10 min',
      ],
    ),
    Programme(
      id: 2,
      nom: 'Gain de masse musculaire',
      description: 'Programme de musculation pour développer votre masse musculaire efficacement',
      duree: '16 semaines',
      difficulte: 'Avancé',
      nombreExercices: 32,
      caloriesParSeance: 600,
      image: '',
      couleur: Color(0xFF2196F3),
      exercices: [
        'Squats - 4 séries x 12',
        'Développé couché - 4 séries x 10',
        'Soulevé de terre - 4 séries x 8',
        'Tractions - 3 séries x 10',
      ],
    ),
    Programme(
      id: 3,
      nom: 'Yoga & Méditation',
      description: 'Programme doux pour améliorer votre flexibilité et réduire le stress',
      duree: '8 semaines',
      difficulte: 'Débutant',
      nombreExercices: 15,
      caloriesParSeance: 200,
      image: '',
      couleur: Color(0xFF9C27B0),
      exercices: [
        'Salutation au soleil - 10 min',
        'Postures debout - 15 min',
        'Postures assises - 10 min',
        'Méditation - 10 min',
      ],
    ),
    Programme(
      id: 4,
      nom: 'Cardio Endurance',
      description: 'Améliorez votre endurance cardiovasculaire avec ce programme progressif',
      duree: '10 semaines',
      difficulte: 'Intermédiaire',
      nombreExercices: 18,
      caloriesParSeance: 500,
      image: '',
      couleur: Color(0xFFF44336),
      exercices: [
        'Course à pied - 30 min',
        'Vélo - 20 min',
        'Corde à sauter - 15 min',
      ],
    ),
    Programme(
      id: 5,
      nom: 'Renforcement du dos',
      description: 'Programme spécialisé pour renforcer votre dos et prévenir les douleurs',
      duree: '6 semaines',
      difficulte: 'Débutant',
      nombreExercices: 12,
      caloriesParSeance: 250,
      image: '',
      couleur: Color(0xFFFF9800),
      exercices: [
        'Superman - 3 séries x 15',
        'Planche - 3 x 30 sec',
        'Extensions lombaires - 3 séries x 12',
        'Étirements du dos - 10 min',
      ],
    ),
    Programme(
      id: 6,
      nom: 'HIIT Express',
      description: 'Séances courtes et intenses pour des résultats rapides',
      duree: '4 semaines',
      difficulte: 'Avancé',
      nombreExercices: 8,
      caloriesParSeance: 400,
      image: '',
      couleur: Color(0xFF00BCD4),
      exercices: [
        'Burpees - 30 sec',
        'Mountain climbers - 30 sec',
        'Jumping jacks - 30 sec',
        'Squats sautés - 30 sec',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);
    
    return Scaffold(
      backgroundColor: isDark ? TColors.darkBackground : Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre avec icône
            Row(
              children: [
                Icon(
                  Iconsax.activity,
                  color: TColors.primary,
                  size: 20,
                ),
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
            Text(
              '${programmes.length} programmes disponibles',
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
            ...programmes.map((programme) => Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: _buildProgrammeCard(context, programme, isDark),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildProgrammeCard(BuildContext context, Programme programme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.transparent : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withOpacity(0.15),
          width: 1,
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
        onTap: () {
          _showProgrammeDetails(context, programme, isDark);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      child: Text(
                        programme.image,
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          programme.nom,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: THelperFunctions.textColor(context),
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          programme.description,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
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
                    context,
                    Iconsax.clock,
                    programme.duree,
                    isDark,
                  ),
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
                  Icon(
                    Iconsax.document,
                    size: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${programme.nombreExercices} exercices',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Iconsax.arrow_right_3,
                    size: 16,
                    color: TColors.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

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
          Icon(
            icon,
            size: 12,
            color: color ?? TColors.primary,
          ),
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

  Color _getDifficultyColor(String difficulte) {
    switch (difficulte) {
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

  void _showProgrammeDetails(BuildContext context, Programme programme, bool isDark) {
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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header avec image
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
                            child: Text(
                              programme.image,
                              style: const TextStyle(fontSize: 48),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                programme.nom,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: THelperFunctions.textColor(context),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                programme.description,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Statistiques
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            context,
                            Iconsax.clock,
                            'Durée',
                            programme.duree,
                            isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            Iconsax.star,
                            'Difficulté',
                            programme.difficulte,
                            isDark,
                            color: _getDifficultyColor(programme.difficulte),
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
                            '${programme.nombreExercices}',
                            isDark,
                          ),
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
                    // Liste des exercices
                    Text(
                      'Exercices inclus',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: THelperFunctions.textColor(context),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...programme.exercices.map((exercice) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: programme.couleur,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              exercice,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: THelperFunctions.textColor(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ),
            // Bouton de démarrage collé en bas
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Programme "${programme.nom}" démarré !'),
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
                  child: const Text(
                    'Démarrer le programme',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: color ?? TColors.primary,
          ),
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
}

class Programme {
  final int id;
  final String nom;
  final String description;
  final String duree;
  final String difficulte;
  final int nombreExercices;
  final int caloriesParSeance;
  final String image;
  final Color couleur;
  final List<String> exercices;

  const Programme({
    required this.id,
    required this.nom,
    required this.description,
    required this.duree,
    required this.difficulte,
    required this.nombreExercices,
    required this.caloriesParSeance,
    required this.image,
    required this.couleur,
    required this.exercices,
  });
}