import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mindiff_app/utils/theme.dart';

class MetricsPage extends StatefulWidget {
  const MetricsPage({super.key});

  @override
  State<MetricsPage> createState() => _MetricsPageState();
}

class _MetricsPageState extends State<MetricsPage> {
  // Données de poids simulées (à remplacer par des données réelles plus tard)
  final double currentWeight = 81.2; // Poids actuel en kg
  final double weight30DaysAgo = 82.7; // Poids il y a 30 jours
  final double height = 175.0; // Taille en cm (à récupérer du profil utilisateur)
  final double targetWeight = 75.0; // Objectif de poids en kg
  
  // Données pour le graphique (6 derniers mois avec 2-3 entrées par mois)
  List<WeightData> get weightHistory => [
    // Mois 6 (il y a 6 mois)
    WeightData(DateTime.now().subtract(const Duration(days: 180)), 85.0),
    WeightData(DateTime.now().subtract(const Duration(days: 165)), 84.7),
    WeightData(DateTime.now().subtract(const Duration(days: 150)), 84.3),
    // Mois 5
    WeightData(DateTime.now().subtract(const Duration(days: 135)), 84.0),
    WeightData(DateTime.now().subtract(const Duration(days: 120)), 83.5),
    WeightData(DateTime.now().subtract(const Duration(days: 105)), 83.2),
    // Mois 4
    WeightData(DateTime.now().subtract(const Duration(days: 90)), 82.8),
    WeightData(DateTime.now().subtract(const Duration(days: 75)), 82.5),
    WeightData(DateTime.now().subtract(const Duration(days: 60)), 82.2),
    // Mois 3
    WeightData(DateTime.now().subtract(const Duration(days: 45)), 82.8),
    WeightData(DateTime.now().subtract(const Duration(days: 30)), 82.7),
    WeightData(DateTime.now().subtract(const Duration(days: 15)), 82.0),
    // Mois actuel
    WeightData(DateTime.now(), currentWeight),
  ];

  double get weightVariation {
    final variation = currentWeight - weight30DaysAgo;
    final percentage = (variation / weight30DaysAgo) * 100;
    return percentage;
  }

  String get variationText {
    final variation = weightVariation;
    if (variation > 0) {
      return '+${variation.toStringAsFixed(1)}%';
    } else if (variation < 0) {
      return variation.toStringAsFixed(1) + '%';
    } else {
      return '0.0%';
    }
  }

  Color get variationColor {
    if (weightVariation < 0) {
      return Colors.green; // Perte de poids
    } else if (weightVariation > 0) {
      return Colors.red; // Gain de poids
    } else {
      return Colors.grey;
    }
  }

  // Calcul de l'IMC actuel
  double get currentBMI {
    final heightInMeters = height / 100;
    return currentWeight / (heightInMeters * heightInMeters);
  }

  // Poids moyen sur la période
  double get averageWeight {
    final sum = weightHistory.map((e) => e.weight).reduce((a, b) => a + b);
    return sum / weightHistory.length;
  }

  // Progression vers l'objectif (en pourcentage)
  double get goalProgress {
    // Poids initial (le plus ancien dans l'historique)
    final initialWeight = weightHistory.first.weight;
    final totalToLose = initialWeight - targetWeight;
    final currentProgress = initialWeight - currentWeight;
    
    if (totalToLose == 0) return 100.0;
    final progress = (currentProgress / totalToLose) * 100;
    return progress.clamp(0.0, 100.0);
  }

  // Données IMC pour le graphique
  List<BMIData> get bmiHistory {
    return weightHistory.map((data) {
      final heightInMeters = height / 100;
      final bmi = data.weight / (heightInMeters * heightInMeters);
      return BMIData(data.date, bmi);
    }).toList();
  }

  // Statut IMC avec couleur
  String get bmiStatus {
    if (currentBMI < 18.5) return 'Insuffisance';
    if (currentBMI < 25) return 'Normal';
    if (currentBMI < 30) return 'Surpoids';
    return 'Obésité';
  }

  Color get bmiStatusColor {
    if (currentBMI < 18.5) return Colors.blue;
    if (currentBMI < 25) return Colors.green;
    if (currentBMI < 30) return Colors.orange;
    return Colors.red;
  }

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
            // Section Poids avec icône
            Row(
              children: [
                Icon(
                  Iconsax.weight,
                  color: TColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Poids',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: THelperFunctions.textColor(context),
                    fontSize: 22,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Valeur du poids actuel
            Text(
              '${currentWeight.toStringAsFixed(1)} kg',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: TColors.primary,
                fontSize: 32,
              ),
            ),
            const SizedBox(height: 6),
            
            // Texte "30 derniers jours" avec variation
            Row(
              children: [
                Text(
                  '30 derniers jours',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: THelperFunctions.isDarkMode(context)
                        ? Colors.grey[400]
                        : Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: variationColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    variationText,
                    style: TextStyle(
                      color: variationColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Graphique en ligne - Poids
            Text(
              'Évolution du poids',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: THelperFunctions.textColor(context),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 250,
              padding: const EdgeInsets.all(16),
              child: LineChart(
                _buildLineChartData(),
              ),
            ),
            const SizedBox(height: 24),
            
            // Section IMC et Statistiques avec Cards
            IntrinsicHeight(
              child: Row(
                children: [
                  // IMC Card
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.transparent : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.15),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Iconsax.chart_2,
                                  color: bmiStatusColor,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'IMC',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: THelperFunctions.isDarkMode(context)
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  currentBMI.toStringAsFixed(1),
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: THelperFunctions.textColor(context),
                                    fontSize: 24,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: bmiStatusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    bmiStatus,
                                    style: TextStyle(
                                      color: bmiStatusColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Poids moyen Card
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.transparent : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.15),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
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
                                  'Poids moyen',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: THelperFunctions.isDarkMode(context)
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${averageWeight.toStringAsFixed(1)} kg',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: THelperFunctions.textColor(context),
                                fontSize: 24,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Objectif de poids avec progression - Card
            Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.transparent : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.15),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Iconsax.flag,
                          color: TColors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Objectif',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: THelperFunctions.isDarkMode(context)
                                ? Colors.grey[400]
                                : Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${goalProgress.toStringAsFixed(0)}%',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: TColors.primary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: goalProgress / 100,
                        minHeight: 10,
                        backgroundColor: THelperFunctions.isDarkMode(context)
                            ? Colors.grey[800]
                            : Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(TColors.primary),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${currentWeight.toStringAsFixed(1)} kg',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: THelperFunctions.isDarkMode(context)
                                ? Colors.grey[400]
                                : Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${targetWeight.toStringAsFixed(1)} kg',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: THelperFunctions.isDarkMode(context)
                                ? Colors.grey[400]
                                : Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Graphique IMC
            Row(
              children: [
                Icon(
                  Iconsax.chart_2,
                  color: TColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  'Évolution de l\'IMC',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: THelperFunctions.textColor(context),
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 250,
              padding: const EdgeInsets.all(16),
              child: LineChart(
                _buildBMILineChartData(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  LineChartData _buildLineChartData() {
    final isDark = THelperFunctions.isDarkMode(context);
    final minWeight = weightHistory.map((e) => e.weight).reduce((a, b) => a < b ? a : b);
    final maxWeight = weightHistory.map((e) => e.weight).reduce((a, b) => a > b ? a : b);
    final range = maxWeight - minWeight;
    final minY = minWeight - (range * 0.1);
    final maxY = maxWeight + (range * 0.1);

    return LineChartData(
      gridData: const FlGridData(
        show: false,
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 3, // Afficher un label tous les 3 points (environ 1 par mois)
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < weightHistory.length) {
                final date = weightHistory[index].date;
                final monthNames = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 
                                   'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
                final month = monthNames[date.month - 1];
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    month,
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 10,
                    ),
                  ),
                );
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(
        show: false,
      ),
      minX: 0,
      maxX: (weightHistory.length - 1).toDouble(),
      minY: minY,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: weightHistory.asMap().entries.map((entry) {
            return FlSpot(entry.key.toDouble(), entry.value.weight);
          }).toList(),
          isCurved: true,
          color: TColors.primary,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: TColors.primary.withOpacity(0.1),
          ),
        ),
      ],
    );
  }

  LineChartData _buildBMILineChartData() {
    final isDark = THelperFunctions.isDarkMode(context);
    final minBMI = bmiHistory.map((e) => e.bmi).reduce((a, b) => a < b ? a : b);
    final maxBMI = bmiHistory.map((e) => e.bmi).reduce((a, b) => a > b ? a : b);
    final range = maxBMI - minBMI;
    final minY = minBMI - (range * 0.1);
    final maxY = maxBMI + (range * 0.1);

    return LineChartData(
      gridData: const FlGridData(
        show: false,
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 3,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < bmiHistory.length) {
                final date = bmiHistory[index].date;
                final monthNames = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 
                                   'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
                final month = monthNames[date.month - 1];
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    month,
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 10,
                    ),
                  ),
                );
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(
        show: false,
      ),
      minX: 0,
      maxX: (bmiHistory.length - 1).toDouble(),
      minY: minY,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: bmiHistory.asMap().entries.map((entry) {
            return FlSpot(entry.key.toDouble(), entry.value.bmi);
          }).toList(),
          isCurved: true,
          color: TColors.primary,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: TColors.primary.withOpacity(0.1),
          ),
        ),
      ],
    );
  }
}

class WeightData {
  final DateTime date;
  final double weight;

  WeightData(this.date, this.weight);
}

class BMIData {
  final DateTime date;
  final double bmi;

  BMIData(this.date, this.bmi);
}
