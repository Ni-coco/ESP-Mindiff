// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mindiff_app/controllers/user_profile_controller.dart';
import 'package:mindiff_app/pages/balance_page.dart';
import 'package:mindiff_app/services/auth_service.dart';
import 'package:mindiff_app/utils/theme.dart';


class MetricsPage extends StatefulWidget {
  const MetricsPage({super.key});

  @override
  State<MetricsPage> createState() => _MetricsPageState();
}

class _MetricsPageState extends State<MetricsPage> {
  late final UserProfileController _ctrl;
  List<WeightData> _rawHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<UserProfileController>();
    _loadHistory();
  }

  Future<void> _showManualWeightDialog(BuildContext context) async {
    final controller = TextEditingController();
    final isDark = THelperFunctions.isDarkMode(context);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Saisie manuelle du poids',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: THelperFunctions.textColor(context),
          ),
        ),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Ex : 75.5',
            suffixText: 'kg',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: TColors.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              final val = double.tryParse(controller.text.replaceAll(',', '.'));
              if (val == null || val <= 0) return;
              Navigator.pop(ctx);
              final userId = _ctrl.userId.value;
              if (userId == null) return;
              try {
                await Get.find<AuthService>().addWeight(userId, val, source: 'manual');
                await _loadHistory();
              } catch (e) {
                debugPrint('MANUAL WEIGHT ERROR: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: TColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  Future<void> _loadHistory() async {
    final userId = _ctrl.userId.value;
    debugPrint('METRICS userId = $userId');
    if (userId == null) { setState(() => _isLoading = false); return; }
    try {
      final entries = await Get.find<AuthService>().getWeightHistory(userId);
      setState(() {
        _rawHistory = entries.map((e) => WeightData(
          DateTime.parse(e['date'] as String),
          (e['weight'] as num).toDouble(),
          e['source'] as String,
        )).toList();
      });
    } catch (e, st) {
      debugPrint('METRICS ERROR: $e\n$st');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Toujours vue journalière, limitée aux 4 dernières semaines (28 jours)
  // Si l'historique est plus court que 28 jours, on prend tout depuis le début
  List<WeightData> get weightHistory {
    if (_rawHistory.isEmpty) return [];
    if (_rawHistory.length <= 28) return _rawHistory;
    return _rawHistory.sublist(_rawHistory.length - 28);
  }

  double get _fallbackWeight => 80.0;
  double get _fallbackHeight => 175.0;
  double get _fallbackTarget => 75.0;

  double get startWeight => _ctrl.profile.value?.weightKg ?? _fallbackWeight;
  double get currentWeight {
    final reals = _rawHistory.where((e) => e.source != 'carried_forward');
    if (reals.isNotEmpty) return reals.last.weight;
    return _ctrl.actualWeight.value ?? startWeight;
  }
  double get height => _ctrl.profile.value?.heightCm ?? _fallbackHeight;
  double get targetWeight => _ctrl.targetWeight.value ?? _fallbackTarget;
  String? get primaryGoal => _ctrl.primaryGoal.value;

  // Variation vs il y a 30 jours (depuis les données réelles)
  double get _weight30dAgo {
    if (_rawHistory.isEmpty) return currentWeight;
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final before = _rawHistory.where((e) => e.date.isBefore(cutoff)).toList();
    return before.isNotEmpty ? before.last.weight : _rawHistory.first.weight;
  }

  double get weightVariation =>
      _rawHistory.isEmpty ? 0 : (currentWeight - _weight30dAgo) / _weight30dAgo * 100;

  String get variationText {
    if (weightVariation > 0) return '+${weightVariation.toStringAsFixed(1)}%';
    if (weightVariation < 0) return '${weightVariation.toStringAsFixed(1)}%';
    return '0.0%';
  }

  Color get variationColor {
    if (weightVariation < 0) return Colors.green;
    if (weightVariation > 0) return Colors.red;
    return Colors.grey;
  }

  double get currentBMI {
    final hm = height / 100;
    return currentWeight / (hm * hm);
  }

  double get averageWeight {
    if (weightHistory.isEmpty) return currentWeight;
    return weightHistory.map((e) => e.weight).reduce((a, b) => a + b) / weightHistory.length;
  }

  double get goalProgress {
    final goal = primaryGoal;
    if (goal == 'lose_weight' || goal == 'maintain') {
      final total = startWeight - targetWeight;
      if (total <= 0) return currentWeight <= targetWeight ? 100.0 : 0.0;
      return ((startWeight - currentWeight) / total * 100).clamp(0.0, 100.0);
    }
    if (goal == 'build_muscle' || goal == 'increase_strength' ||
        goal == 'improve_endurance' || goal == 'general_fitness') {
      final total = targetWeight - startWeight;
      if (total <= 0) return currentWeight >= targetWeight ? 100.0 : 0.0;
      return ((currentWeight - startWeight) / total * 100).clamp(0.0, 100.0);
    }
    return 0.0;
  }

  List<BMIData> get bmiHistory => weightHistory.map((d) {
    final hm = height / 100;
    return BMIData(d.date, d.weight / (hm * hm));
  }).toList();

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

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Obx(() {
      final _ = _ctrl.profile.value;
      _ctrl.targetWeight.value;

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
            
            // Label période + variation
            Row(
              children: [
                Text(
                  '4 dernières semaines',
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
              child: weightHistory.isEmpty
                  ? Center(
                      child: Text(
                        'Aucune donnée de poids',
                        style: TextStyle(color: Colors.grey[500], fontSize: 14),
                      ),
                    )
                  : LineChart(_buildLineChartData()),
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
                            // Boutons poids
                            Row(
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => _showManualWeightDialog(context),
                                  icon: const Icon(Iconsax.edit, size: 16),
                                  label: const Text('Manuel'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: TColors.primary,
                                    side: BorderSide(color: TColors.primary),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: () => Get.to(() => const BalancePage()),
                                  icon: const Icon(Iconsax.bluetooth, size: 16),
                                  label: const Text('Balance'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: TColors.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Disclaimer IMC
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 13, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "L'IMC est un indicateur statistique general. Il ne tient pas compte de la masse musculaire, de la morphologie ni de la composition corporelle. À utiliser avec recul.",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

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
                          'Départ : ${startWeight.toStringAsFixed(1)} kg',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: THelperFunctions.isDarkMode(context)
                                ? Colors.grey[400]
                                : Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Objectif : ${targetWeight.toStringAsFixed(1)} kg',
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
              child: bmiHistory.isEmpty
                  ? Center(
                      child: Text(
                        'Aucune donnée IMC',
                        style: TextStyle(color: Colors.grey[500], fontSize: 14),
                      ),
                    )
                  : LineChart(_buildBMILineChartData()),
            ),
            ],
          ),
        ),
      );
    });
  }

  LineChartData _buildLineChartData() {
    final isDark = THelperFunctions.isDarkMode(context);
    final minWeight = weightHistory.map((e) => e.weight).reduce((a, b) => a < b ? a : b);
    final maxWeight = weightHistory.map((e) => e.weight).reduce((a, b) => a > b ? a : b);
    final range = maxWeight - minWeight;
    final minY = minWeight - (range * 0.1);
    final maxY = maxWeight + (range * 0.1);

    return LineChartData(
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) => touchedSpots.map((spot) =>
            LineTooltipItem(
              '${spot.y.toStringAsFixed(1)} kg',
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ).toList(),
        ),
      ),
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
            interval: 7, // Un label par semaine
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= weightHistory.length) return const Text('');
              final date = weightHistory[index].date;
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('${date.day}/${date.month}', style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 10,
                )),
              );
            },
          ),
        ),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: (weightHistory.length - 1).toDouble(),
      minY: minY,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: weightHistory.asMap().entries.map((e) =>
            FlSpot(e.key.toDouble(), e.value.weight)).toList(),
          isCurved: true,
          color: TColors.primary,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, bar, index) {
              final isReal = weightHistory[index].source != 'carried_forward';
              return FlDotCirclePainter(
                radius: isReal ? 4 : 2,
                color: isReal ? TColors.primary : TColors.primary.withOpacity(0.3),
                strokeWidth: 0,
                strokeColor: Colors.transparent,
              );
            },
          ),
          belowBarData: BarAreaData(show: true, color: TColors.primary.withOpacity(0.1)),
        ),
      ],
    );
  }

  LineChartData _buildBMILineChartData() {
    if (bmiHistory.isEmpty) return LineChartData();
    final isDark = THelperFunctions.isDarkMode(context);
    final minBMI = bmiHistory.map((e) => e.bmi).reduce((a, b) => a < b ? a : b);
    final maxBMI = bmiHistory.map((e) => e.bmi).reduce((a, b) => a > b ? a : b);
    final range = (maxBMI - minBMI).clamp(0.5, double.infinity);
    final minY = minBMI - range * 0.1;
    final maxY = maxBMI + range * 0.1;

    return LineChartData(
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
            final bmiVal = spot.y;
            final String status;
            if (bmiVal < 18.5) status = 'Insuffisance';
            else if (bmiVal < 25) status = 'Normal';
            else if (bmiVal < 30) status = 'Surpoids';
            else status = 'Obésité';
            return LineTooltipItem(
              'IMC ${bmiVal.toStringAsFixed(1)}\n',
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              children: [
                TextSpan(
                  text: status,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ],
            );
          }).toList(),
        ),
      ),
      gridData: const FlGridData(show: false),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 7,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= bmiHistory.length) return const Text('');
              final date = bmiHistory[index].date;
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('${date.day}/${date.month}', style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 10,
                )),
              );
            },
          ),
        ),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: (bmiHistory.length - 1).toDouble(),
      minY: minY,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: bmiHistory.asMap().entries.map((e) =>
            FlSpot(e.key.toDouble(), double.parse(e.value.bmi.toStringAsFixed(2)))).toList(),
          isCurved: true,
          color: TColors.primary,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: true, color: TColors.primary.withOpacity(0.1)),
        ),
      ],
    );
  }
}

class WeightData {
  final DateTime date;
  final double weight;
  final String source;

  WeightData(this.date, this.weight, [this.source = 'manual']);
}

class BMIData {
  final DateTime date;
  final double bmi;

  BMIData(this.date, this.bmi);
}
