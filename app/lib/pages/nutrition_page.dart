import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mindiff_app/utils/theme.dart';

class NutritionPage extends StatefulWidget {
  const NutritionPage({super.key});

  @override
  State<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage> {
  // Données de nutrition simulées
  final double calorieObjectif = 2000.0; // Objectif quotidien en kcal
  final double caloriesConsommees = 1450.0; // Calories consommées aujourd'hui
  
  // Macronutriments (en grammes)
  final double proteinesConsommees = 120.0;
  final double proteinesObjectif = 150.0;
  final double glucidesConsommes = 180.0;
  final double glucidesObjectif = 250.0;
  final double lipidesConsommes = 45.0;
  final double lipidesObjectif = 65.0;

  // Repas de la journée
  final List<Repas> repas = [
    Repas(
      id: 1,
      nom: 'Petit-déjeuner complet',
      type: TypeRepas.petitDejeuner,
      calories: 450,
      proteines: 25,
      glucides: 60,
      lipides: 15,
      heure: '08:30',
      aliments: [
        'Œufs brouillés (2)',
        'Pain complet (2 tranches)',
        'Avocat (1/2)',
        'Café',
      ],
    ),
    Repas(
      id: 2,
      nom: 'Salade de poulet',
      type: TypeRepas.dejeuner,
      calories: 550,
      proteines: 45,
      glucides: 50,
      lipides: 20,
      heure: '13:15',
      aliments: [
        'Poulet grillé (150g)',
        'Salade verte',
        'Tomates cerises',
        'Vinaigrette légère',
        'Quinoa (80g)',
      ],
    ),
    Repas(
      id: 3,
      nom: 'Yaourt et fruits',
      type: TypeRepas.collation,
      calories: 200,
      proteines: 15,
      glucides: 30,
      lipides: 5,
      heure: '16:00',
      aliments: [
        'Yaourt grec (150g)',
        'Myrtilles (100g)',
        'Miel (1 cuillère)',
      ],
    ),
    Repas(
      id: 4,
      nom: 'Saumon et légumes',
      type: TypeRepas.diner,
      calories: 250,
      proteines: 35,
      glucides: 40,
      lipides: 5,
      heure: '20:00',
      aliments: [
        'Saumon (120g)',
        'Brocolis vapeur',
        'Riz complet (60g)',
      ],
    ),
  ];

  double get caloriesRestantes => calorieObjectif - caloriesConsommees;
  
  Color get caloriesRestantesColor {
    final pourcentage = (caloriesConsommees / calorieObjectif) * 100;
    if (pourcentage < 70) return Colors.green;
    if (pourcentage < 90) return Colors.orange;
    return Colors.red;
  }

  List<Repas> getRepasParType(TypeRepas type) {
    return repas.where((r) => r.type == type).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);
    final now = DateTime.now();
    final dateFormat = '${now.day}/${now.month}/${now.year}';
    final joursSemaine = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    final jourSemaine = joursSemaine[now.weekday - 1];
    
    return Scaffold(
      backgroundColor: isDark ? TColors.darkBackground : Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec titre et date
            Row(
              children: [
                Icon(
                  Iconsax.health,
                  color: TColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Nutrition',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: THelperFunctions.textColor(context),
                    fontSize: 22,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$jourSemaine $dateFormat',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            
            // Barre de progression principale - Calories
            _buildCaloriesProgressCard(context, isDark),
            const SizedBox(height: 16),
            
            // Indicateur de calories restantes
            _buildCaloriesRestantesCard(context, isDark),
            const SizedBox(height: 16),
            
            // Répartition des macronutriments
            _buildMacrosCard(context, isDark),
            const SizedBox(height: 24),
            
            // Sections de repas
            _buildRepasSection(
              context,
              isDark,
              'Petit-déjeuner',
              Iconsax.coffee,
              TypeRepas.petitDejeuner,
            ),
            const SizedBox(height: 16),
            _buildRepasSection(
              context,
              isDark,
              'Déjeuner',
              Iconsax.sun_1,
              TypeRepas.dejeuner,
            ),
            const SizedBox(height: 16),
            _buildRepasSection(
              context,
              isDark,
              'Dîner',
              Iconsax.moon,
              TypeRepas.diner,
            ),
            const SizedBox(height: 16),
            _buildRepasSection(
              context,
              isDark,
              'Collations',
              Iconsax.cake,
              TypeRepas.collation,
            ),
            const SizedBox(height: 16),
            
            // Statistiques rapides
            _buildStatsCard(context, isDark),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 8.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // TODO: Implémenter l'ajout de repas
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ajouter un repas (à implémenter)'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: TColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Ajouter un repas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCaloriesProgressCard(BuildContext context, bool isDark) {
    final pourcentage = (caloriesConsommees / calorieObjectif).clamp(0.0, 1.0);
    
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
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Calories',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${caloriesConsommees.toInt()} / ${calorieObjectif.toInt()} kcal',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: THelperFunctions.textColor(context),
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: caloriesRestantesColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${(pourcentage * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: caloriesRestantesColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: pourcentage,
                minHeight: 8,
                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(caloriesRestantesColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaloriesRestantesCard(BuildContext context, bool isDark) {
    final restantes = caloriesRestantes;
    final isNegatif = restantes < 0;
    
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
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (isNegatif ? Colors.red : Colors.green).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isNegatif ? Iconsax.arrow_up_2 : Iconsax.arrow_down_2,
                color: isNegatif ? Colors.red : Colors.green,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isNegatif ? 'Dépassement' : 'Calories restantes',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${isNegatif ? '+' : ''}${restantes.abs().toInt()} kcal',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isNegatif ? Colors.red : Colors.green,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacrosCard(BuildContext context, bool isDark) {
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
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Iconsax.chart_21,
                  color: TColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  'Macronutriments',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: THelperFunctions.textColor(context),
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Graphique circulaire
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 60,
                  sections: [
                    PieChartSectionData(
                      value: proteinesConsommees,
                      title: '${proteinesConsommees.toInt()}g',
                      color: Colors.blue,
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: glucidesConsommes,
                      title: '${glucidesConsommes.toInt()}g',
                      color: Colors.orange,
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: lipidesConsommes,
                      title: '${lipidesConsommes.toInt()}g',
                      color: Colors.green,
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Légende
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMacroLegend(context, isDark, 'Protéines', proteinesConsommees, proteinesObjectif, Colors.blue),
                _buildMacroLegend(context, isDark, 'Glucides', glucidesConsommes, glucidesObjectif, Colors.orange),
                _buildMacroLegend(context, isDark, 'Lipides', lipidesConsommes, lipidesObjectif, Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroLegend(BuildContext context, bool isDark, String nom, double consomme, double objectif, Color color) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          nom,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text.rich(
          TextSpan(
            text: '${consomme.toInt()}g',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: THelperFunctions.textColor(context),
              fontSize: 12,
            ),
            children: [
              TextSpan(
                text: ' / ${objectif.toInt()}g',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.normal,
                  color: isDark ? Colors.grey[500] : Colors.grey[500],
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRepasSection(BuildContext context, bool isDark, String titre, IconData icon, TypeRepas type) {
    final repasSection = getRepasParType(type);
    final totalCalories = repasSection.fold<double>(0, (sum, r) => sum + r.calories);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: TColors.primary,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              titre,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: THelperFunctions.textColor(context),
                fontSize: 18,
              ),
            ),
            const Spacer(),
            if (totalCalories > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: TColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${totalCalories.toInt()} kcal',
                  style: TextStyle(
                    color: TColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (repasSection.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.transparent : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.withOpacity(0.1),
              ),
            ),
            child: Center(
              child: Text(
                'Aucun repas enregistré',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.grey[500] : Colors.grey[500],
                  fontSize: 14,
                ),
              ),
            ),
          )
        else
          ...repasSection.map((repas) => Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: _buildRepasCard(context, repas, isDark),
          )),
      ],
    );
  }

  Widget _buildRepasCard(BuildContext context, Repas repas, bool isDark) {
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
          _showRepasDetails(context, repas, isDark);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      repas.nom,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: THelperFunctions.textColor(context),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Iconsax.clock,
                          size: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          repas.heure,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${repas.calories} kcal',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Iconsax.arrow_right_3,
                size: 16,
                color: TColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, bool isDark) {
    final moyenneQuotidienne = 1850.0; // Simulé
    final meilleurJour = 2200.0; // Simulé
    final totalSemaine = 12950.0; // Simulé
    
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
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Iconsax.chart_1,
                  color: TColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  'Statistiques',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: THelperFunctions.textColor(context),
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(context, isDark, 'Moyenne', '${moyenneQuotidienne.toInt()} kcal', Iconsax.chart_2),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem(context, isDark, 'Meilleur jour', '${meilleurJour.toInt()} kcal', Iconsax.star),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatItem(context, isDark, 'Total semaine', '${totalSemaine.toInt()} kcal', Iconsax.calendar),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, bool isDark, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
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
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: TColors.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: THelperFunctions.textColor(context),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _showRepasDetails(BuildContext context, Repas repas, bool isDark) {
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
                      // Header
                      Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Iconsax.health,
                              color: Colors.orange,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  repas.nom,
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: THelperFunctions.textColor(context),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Iconsax.clock,
                                      size: 14,
                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      repas.heure,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Calories principales
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${repas.calories}',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                                fontSize: 28,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'kcal',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.orange,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Macronutriments
                      Text(
                        'Macronutriments',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: THelperFunctions.textColor(context),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMacroDetailCard(
                              context,
                              isDark,
                              'Protéines',
                              '${repas.proteines}g',
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMacroDetailCard(
                              context,
                              isDark,
                              'Glucides',
                              '${repas.glucides}g',
                              Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMacroDetailCard(
                              context,
                              isDark,
                              'Lipides',
                              '${repas.lipides}g',
                              Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Liste des aliments
                      Text(
                        'Aliments',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: THelperFunctions.textColor(context),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...repas.aliments.map((aliment) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                aliment,
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
              // Boutons d'action
              Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 24.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // TODO: Implémenter la modification
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Modifier',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // TODO: Implémenter la suppression
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Repas "${repas.nom}" supprimé'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Supprimer',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMacroDetailCard(BuildContext context, bool isDark, String label, String value, Color color) {
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
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
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
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

enum TypeRepas {
  petitDejeuner,
  dejeuner,
  diner,
  collation,
}

class Repas {
  final int id;
  final String nom;
  final TypeRepas type;
  final int calories;
  final double proteines;
  final double glucides;
  final double lipides;
  final String heure;
  final List<String> aliments;

  const Repas({
    required this.id,
    required this.nom,
    required this.type,
    required this.calories,
    required this.proteines,
    required this.glucides,
    required this.lipides,
    required this.heure,
    required this.aliments,
  });
}
