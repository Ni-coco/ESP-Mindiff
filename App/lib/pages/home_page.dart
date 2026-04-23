// ignore_for_file: deprecated_member_use

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mindiff_app/controllers/user_profile_controller.dart';
import 'package:mindiff_app/services/auth_service.dart';
import 'package:mindiff_app/utils/theme.dart';
import 'package:url_launcher/url_launcher.dart' show launchUrl, LaunchMode;

// ── Modèle local ─────────────────────────────────────────────────────────────

class _WeightPoint {
  final DateTime date;
  final double weight;
  final String source;
  _WeightPoint(this.date, this.weight, this.source);
}

// ── Page ─────────────────────────────────────────────────────────────────────

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _ctrl = Get.find<UserProfileController>();
  final _auth = Get.find<AuthService>();

  List<_WeightPoint> _history = [];
  Map<String, dynamic>? _mealSuggestions;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = _ctrl.userId.value;
    if (userId == null) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }
    try {
      final results = await Future.wait([
        _auth.getWeightHistory(userId),
        _auth.getMealSuggestions(userId),
      ]);
      if (!mounted) return;
      setState(() {
        _history = (results[0] as List<Map<String, dynamic>>)
            .map((e) => _WeightPoint(
                  DateTime.parse(e['date'] as String),
                  (e['weight'] as num).toDouble(),
                  e['source'] as String,
                ))
            .toList();
        _mealSuggestions = results[1] as Map<String, dynamic>;
      });
    } catch (e) {
      debugPrint('HOME ERROR: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Calculs poids ──────────────────────────────────────────────────────────

  double get _currentWeight {
    final reals = _history.where((e) => e.source != 'carried_forward');
    if (reals.isNotEmpty) return reals.last.weight;
    return _ctrl.profile.value?.weightKg ?? 80.0;
  }

  double? get _currentBMI {
    final h = _ctrl.profile.value?.heightCm;
    if (h == null || h == 0) return null;
    final hm = h / 100;
    return _currentWeight / (hm * hm);
  }

  List<_WeightPoint> get _last7 {
    if (_history.isEmpty) return [];
    if (_history.length <= 7) return _history;
    return _history.sublist(_history.length - 7);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? TColors.darkBackground : Colors.white,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? TColors.darkBackground : Colors.white,
      body: SafeArea(
        child: Obx(() {
          final profile = _ctrl.profile.value;
          final name = profile?.firstName ?? 'Bienvenue';
          final goalKey = _ctrl.primaryGoal.value;
          final sessions = _ctrl.sessionsPerWeek.value;

          return RefreshIndicator(
            onRefresh: _load,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, name, isDark),
                  const SizedBox(height: 20),
                  _buildTodaySummary(context, isDark, goalKey, sessions),
                  const SizedBox(height: 20),
                  _buildQuickMetricsRow(context, isDark),
                  if (_last7.length >= 2) ...[
                    const SizedBox(height: 16),
                    _buildWeightCharts(context, isDark),
                  ],
                  const SizedBox(height: 20),
                  _buildMealSuggestions(context, isDark),
                  const SizedBox(height: 20),
                  _buildInspiration(context, isDark),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, String name, bool isDark) {
    final greeting = _greeting();
    return Row(
      children: [
        Expanded(
          child: Column(
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

  // ── Bannière objectif ──────────────────────────────────────────────────────

  Widget _buildTodaySummary(
    BuildContext context,
    bool isDark,
    String? goalKey,
    int? sessionsPerWeek,
  ) {
    final goal = _goalLabel(goalKey) ?? 'Rester en forme';
    final sessionsText = sessionsPerWeek != null
        ? '$sessionsPerWeek séances prévues cette semaine'
        : 'Fixe-toi un objectif de séances';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [TColors.primary, TColors.primary.withValues(alpha: 0.7)],
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

  // ── Cards poids / IMC ──────────────────────────────────────────────────────

  Widget _buildQuickMetricsRow(BuildContext context, bool isDark) {
    final weight = _currentWeight;
    final bmi = _currentBMI;

    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            icon: Iconsax.weight,
            label: 'Poids actuel',
            value: '${weight.toStringAsFixed(1)} kg',
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

  // ── Graphiques poids + IMC ────────────────────────────────────────────────

  Widget _buildWeightCharts(BuildContext context, bool isDark) {
    final data = _last7;
    final h = _ctrl.profile.value?.heightCm ?? 175.0;
    final hm = h / 100;
    final bmiData = data.map((e) => e.weight / (hm * hm)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Iconsax.graph, size: 18, color: TColors.primary),
          const SizedBox(width: 6),
          Text(
            '7 derniers jours',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: THelperFunctions.textColor(context),
                ),
          ),
        ]),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _MiniLineChart(
                  label: 'Poids',
                  unit: 'kg',
                  values: data.map((e) => e.weight).toList(),
                  sources: data.map((e) => e.source).toList(),
                  dates: data.map((e) => e.date).toList(),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniLineChart(
                  label: 'IMC',
                  unit: '',
                  values: bmiData,
                  sources: data.map((e) => e.source).toList(),
                  dates: data.map((e) => e.date).toList(),
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Suggestions de repas ───────────────────────────────────────────────────

  Widget _buildMealSuggestions(BuildContext context, bool isDark) {
    final s = _mealSuggestions;
    final tdee = (s?['tdee'] as num?)?.toInt() ?? 0;
    final consumed = (s?['consumed_today'] as num?)?.toInt() ?? 0;
    final remaining = (s?['remaining'] as num?)?.toInt() ?? 0;
    final suggestions = (s?['suggestions'] as List<dynamic>?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Iconsax.health, size: 18, color: TColors.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Idées de repas',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: THelperFunctions.textColor(context),
                  ),
            ),
          ),
          if (tdee > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: TColors.primary.withOpacity(0.08),
              ),
              child: Text(
                '$consumed / $tdee kcal',
                style: TextStyle(
                  color: TColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ]),
        if (remaining > 0) ...[
          const SizedBox(height: 4),
          Text(
            '$remaining kcal restantes à combler',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
        const SizedBox(height: 10),
        if (tdee > 0 && remaining <= 0)
          _buildAllDoneCard(context)
        else if (suggestions.isEmpty)
          _buildNoDataCard(context, isDark, tdee)
        else
          SizedBox(
            height: 148,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: suggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _MealSuggestionCard(
                data: suggestions[i] as Map<String, dynamic>,
                isDark: isDark,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAllDoneCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.green.withOpacity(0.08),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Text(
            'Objectif calorique atteint pour aujourd\'hui !',
            style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataCard(BuildContext context, bool isDark, int tdee) {
    final msg = tdee == 0
        ? 'Complète ton profil pour obtenir des suggestions de repas.'
        : 'Aucune suggestion disponible pour le moment.';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey[100],
      ),
      child: Text(
        msg,
        style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
      ),
    );
  }

  // ── Inspiration ────────────────────────────────────────────────────────────

  Widget _buildInspiration(BuildContext context, bool isDark) {
    final quotes = [
      "Un petit pas chaque jour vaut mieux qu'un grand pas jamais fait.",
      "Ton corps entend tout ce que pense ton esprit.",
      "La constance bat toujours l'intensité.",
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Iconsax.quote_down, size: 18, color: TColors.primary),
          const SizedBox(width: 6),
          Text(
            'Inspiration du jour',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: THelperFunctions.textColor(context),
                ),
          ),
        ]),
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

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour';
    if (hour < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  String? _goalLabel(String? goal) {
    switch (goal) {
      case 'lose_weight':       return 'Objectif : Perdre du poids';
      case 'build_muscle':      return 'Objectif : Prendre du muscle';
      case 'maintain':          return 'Objectif : Maintenir ton poids';
      case 'improve_endurance': return 'Objectif : Améliorer ton endurance';
      case 'increase_strength': return 'Objectif : Gagner en force';
      case 'general_fitness':   return 'Objectif : Forme générale';
      default: return null;
    }
  }
}

// ── Widgets réutilisables ─────────────────────────────────────────────────────

class _MiniLineChart extends StatelessWidget {
  final String label;
  final String unit;
  final List<double> values;
  final List<String> sources;
  final List<DateTime> dates;
  final bool isDark;

  const _MiniLineChart({
    required this.label,
    required this.unit,
    required this.values,
    required this.sources,
    required this.dates,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).clamp(0.5, double.infinity);
    final minY = minV - range * 0.15;
    final maxY = maxV + range * 0.15;
    final labelColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Container(
      height: 160,
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
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
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: TColors.primary,
            ),
          ),
          Text(
            unit.isNotEmpty
                ? '${values.last.toStringAsFixed(1)} $unit'
                : values.last.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                minX: 0,
                maxX: (values.length - 1).toDouble(),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
                      unit.isNotEmpty
                          ? '${s.y.toStringAsFixed(1)} $unit'
                          : s.y.toStringAsFixed(1),
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    )).toList(),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: (values.length / 2).ceilToDouble(),
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= dates.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${dates[i].day}/${dates[i].month}',
                            style: TextStyle(fontSize: 9, color: labelColor),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      values.length,
                      (i) => FlSpot(i.toDouble(), values[i]),
                    ),
                    isCurved: true,
                    color: TColors.primary,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, i) => FlDotCirclePainter(
                        radius: sources[i] != 'carried_forward' ? 3 : 2,
                        color: sources[i] != 'carried_forward'
                            ? TColors.primary
                            : TColors.primary.withOpacity(0.3),
                        strokeWidth: 0,
                        strokeColor: Colors.transparent,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: TColors.primary.withOpacity(0.08),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
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
          Row(children: [
            Icon(icon, size: 18, color: TColors.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
            ),
          ]),
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

class _MealSuggestionCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isDark;

  const _MealSuggestionCard({required this.data, required this.isDark});

  void _openDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MealDetailSheet(data: data, isDark: isDark),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mealType = data['meal_type'] as String;
    final label = data['label'] as String;
    final calories = (data['calories'] as num).toInt();
    final proteinG = (data['protein_g'] as num).toDouble();
    final carbsG = (data['carbs_g'] as num).toDouble();
    final fatG = (data['fat_g'] as num).toDouble();
    final imageUrl = data['image_url'] as String?;

    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Container(
        width: 220,
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
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (imageUrl != null)
              Image.network(
                imageUrl,
                height: 70,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(height: 0),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _mealLabel(mealType),
                        style: TextStyle(
                          fontSize: 11,
                          color: TColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: TColors.primary.withOpacity(0.08),
                        ),
                        child: Text(
                          '$calories kcal',
                          style: TextStyle(
                            color: TColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: THelperFunctions.textColor(context),
                        ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _MacroChip('P ${proteinG.toStringAsFixed(0)}g', Colors.blue),
                      const SizedBox(width: 4),
                      _MacroChip('G ${carbsG.toStringAsFixed(0)}g', Colors.orange),
                      const SizedBox(width: 4),
                      _MacroChip('L ${fatG.toStringAsFixed(0)}g', Colors.red),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _mealLabel(String type) {
    switch (type) {
      case 'breakfast': return 'Petit-déjeuner';
      case 'lunch':     return 'Déjeuner';
      case 'dinner':    return 'Dîner';
      case 'snack':     return 'Collation';
      default:          return type;
    }
  }
}

class _MealDetailSheet extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isDark;

  const _MealDetailSheet({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final label = data['label'] as String;
    final calories = (data['calories'] as num).toInt();
    final proteinG = (data['protein_g'] as num).toDouble();
    final carbsG = (data['carbs_g'] as num).toDouble();
    final fatG = (data['fat_g'] as num).toDouble();
    final fiberG = (data['fiber_g'] as num).toDouble();
    final servings = (data['servings'] as num?)?.toInt() ?? 1;
    final imageUrl = data['image_url'] as String?;
    final recipeUrl = data['recipe_url'] as String? ?? '';
    final source = data['source'] as String? ?? '';
    final ingredients = (data['ingredient_lines'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [];
    final bg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        clipBehavior: Clip.hardEdge,
        child: ListView(
          controller: controller,
          padding: EdgeInsets.zero,
          children: [
            // Image + handle
            Stack(
              children: [
                if (imageUrl != null)
                  Image.network(
                    imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(height: 60, color: Colors.transparent),
                  )
                else
                  const SizedBox(height: 16),
                Positioned(
                  top: 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: imageUrl != null ? Colors.white54 : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre + source
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: THelperFunctions.textColor(context),
                        ),
                  ),
                  if (source.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      source,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    '$servings portion${servings > 1 ? 's' : ''} · $calories kcal / portion',
                    style: TextStyle(
                      fontSize: 13,
                      color: TColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  // Macros
                  const SizedBox(height: 16),
                  Text(
                    'Valeurs nutritionnelles (par portion)',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: THelperFunctions.textColor(context),
                        ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _MacroTile('Protéines', '${proteinG.toStringAsFixed(1)} g', Colors.blue, isDark)),
                      const SizedBox(width: 8),
                      Expanded(child: _MacroTile('Glucides', '${carbsG.toStringAsFixed(1)} g', Colors.orange, isDark)),
                      const SizedBox(width: 8),
                      Expanded(child: _MacroTile('Lipides', '${fatG.toStringAsFixed(1)} g', Colors.red, isDark)),
                      const SizedBox(width: 8),
                      Expanded(child: _MacroTile('Fibres', '${fiberG.toStringAsFixed(1)} g', Colors.green, isDark)),
                    ],
                  ),

                  // Ingrédients
                  if (ingredients.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Ingrédients',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: THelperFunctions.textColor(context),
                          ),
                    ),
                    const SizedBox(height: 8),
                    ...ingredients.map(
                      (ing) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 7),
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: TColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                ing,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: THelperFunctions.textColor(context),
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Bouton recette complète
                  if (recipeUrl.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            await launchUrl(
                              Uri.parse(recipeUrl),
                              mode: LaunchMode.externalApplication,
                            );
                          } catch (_) {}
                        },
                        icon: const Icon(Iconsax.export, size: 18),
                        label: const Text('Voir la recette complète'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _MacroTile(this.label, this.value, this.color, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withOpacity(0.08),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String text;
  final Color color;
  const _MacroChip(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: color.withOpacity(0.12),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
