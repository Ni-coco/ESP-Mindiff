// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mindiff_app/controllers/user_profile_controller.dart';
import 'package:mindiff_app/services/auth_service.dart';
import 'package:mindiff_app/utils/theme.dart';

// ─── Modèles locaux ───────────────────────────────────────────────────────────

class MealEntry {
  final int id;
  final String mealType;
  final String description;
  final double calories;
  final double proteinG;
  final double fatG;
  final double carbsG;
  final double fiberG;

  MealEntry({
    required this.id,
    required this.mealType,
    required this.description,
    required this.calories,
    required this.proteinG,
    required this.fatG,
    required this.carbsG,
    required this.fiberG,
  });

  factory MealEntry.fromJson(Map<String, dynamic> j) => MealEntry(
        id: j['id'] as int,
        mealType: j['meal_type'] as String,
        description: j['description'] as String,
        calories: (j['calories'] as num).toDouble(),
        proteinG: (j['protein_g'] as num).toDouble(),
        fatG: (j['fat_g'] as num).toDouble(),
        carbsG: (j['carbs_g'] as num).toDouble(),
        fiberG: (j['fiber_g'] as num).toDouble(),
      );
}

// ─── Page ─────────────────────────────────────────────────────────────────────

class NutritionPage extends StatefulWidget {
  const NutritionPage({super.key});

  @override
  State<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage> {
  final _ctrl = Get.find<UserProfileController>();
  final _auth = Get.find<AuthService>();

  List<MealEntry> _meals = [];
  bool _isLoading = true;

  // Totaux du jour
  double _totalCalories = 0;
  double _totalProtein = 0;
  double _totalFat = 0;
  double _totalCarbs = 0;
  double _totalFiber = 0;

  static const _mealTypes = ['breakfast', 'lunch', 'dinner', 'snack'];
  static const _mealLabels = {
    'breakfast': 'Petit-déjeuner',
    'lunch': 'Déjeuner',
    'dinner': 'Dîner',
    'snack': 'Collation',
  };
  static const _mealIcons = {
    'breakfast': Iconsax.coffee,
    'lunch': Iconsax.sun_1,
    'dinner': Iconsax.moon,
    'snack': Iconsax.cup,
  };

  @override
  void initState() {
    super.initState();
    _loadMeals();
  }

  Future<void> _loadMeals() async {
    final userId = _ctrl.userId.value;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final data = await _auth.getMeals(userId);
      final list = (data['meals'] as List)
          .map((e) => MealEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() {
        _meals = list;
        _totalCalories = (data['total_calories'] as num).toDouble();
        _totalProtein = (data['total_protein_g'] as num).toDouble();
        _totalFat = (data['total_fat_g'] as num).toDouble();
        _totalCarbs = (data['total_carbs_g'] as num).toDouble();
        _totalFiber = (data['total_fiber_g'] as num).toDouble();
      });
    } catch (e) {
      debugPrint('NUTRITION ERROR: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<MealEntry> _mealsOf(String type) =>
      _meals.where((m) => m.mealType == type).toList();

  /// Mifflin-St Jeor + multiplicateur d'activité + ajustement objectif poids
  double get _maintenanceCalories {
    final weight = _ctrl.profile.value?.weightKg;
    final height = _ctrl.profile.value?.heightCm;
    final age = _ctrl.age.value;
    final gender = _ctrl.gender.value;
    if (weight == null || height == null || age == null) return 2000;

    final bmr = (10 * weight) + (6.25 * height) - (5 * age) +
        (gender == 'female' ? -161 : 5);

    final sessions = _ctrl.sessionsPerWeek.value ?? 0;
    final double multiplier;
    if (sessions <= 1) {
      multiplier = 1.2;
    } else if (sessions <= 3) {
      multiplier = 1.375;
    } else if (sessions <= 5) {
      multiplier = 1.55;
    } else {
      multiplier = 1.725;
    }

    final tdee = bmr * multiplier;

    final targetWeight = _ctrl.targetWeight.value;
    if (targetWeight == null) return tdee;
    if (targetWeight < weight) return tdee - 500;
    if (targetWeight > weight) return tdee + 300;
    return tdee;
  }

  Future<void> _openAddSheet(String mealType) async {
    final controller = TextEditingController();
    bool isAnalyzing = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final isDark = THelperFunctions.isDarkMode(context);
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? TColors.darkBackground : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ajouter — ${_mealLabels[mealType]}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: THelperFunctions.textColor(context),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Une ligne = un aliment (ex: 200g de riz, 1 pomme)',
                    style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    maxLines: 5,
                    style: TextStyle(
                        color: THelperFunctions.textColor(context),
                        fontSize: 14),
                    decoration: InputDecoration(
                      hintText:
                          '200g de riz\n150g de poulet grillé\n1 cuillère d\'huile d\'olive',
                      hintStyle: TextStyle(
                          color:
                              isDark ? Colors.grey[600] : Colors.grey[400],
                          fontSize: 13),
                      filled: true,
                      fillColor: isDark ? Colors.grey[900] : Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: Colors.grey.withOpacity(0.3), width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: Colors.grey.withOpacity(0.2), width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: TColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isAnalyzing
                          ? null
                          : () async {
                              if (controller.text.trim().isEmpty) return;
                              setSheetState(() => isAnalyzing = true);
                              try {
                                final userId = _ctrl.userId.value!;
                                await _auth.addMeal(
                                  userId,
                                  mealType: mealType,
                                  description: controller.text.trim(),
                                );
                                if (ctx.mounted) Navigator.pop(ctx);
                                await _loadMeals();
                              } catch (e) {
                                debugPrint('ADD MEAL ERROR: $e');
                                setSheetState(() => isAnalyzing = false);
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text('Erreur : $e'),
                                      backgroundColor: Colors.red[700],
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isAnalyzing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Analyser et ajouter',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openFreestyleSheet() async {
    final nameCtrl = TextEditingController();
    final caloriesCtrl = TextEditingController();
    final proteinCtrl = TextEditingController();
    final carbsCtrl = TextEditingController();
    final fatCtrl = TextEditingController();
    final fiberCtrl = TextEditingController();
    String selectedType = 'snack';
    bool isSaving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final isDark = THelperFunctions.isDarkMode(context);
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? TColors.darkBackground : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Saisie manuelle',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: THelperFunctions.textColor(context),
                            )),
                    const SizedBox(height: 4),
                    Text("Edamam ne reconnaît pas l'aliment ? Saisis les macros toi-même.",
                        style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600])),
                    const SizedBox(height: 16),
                    // Nom de l'aliment
                    _FreestyleField(
                      controller: nameCtrl,
                      label: 'Nom de l\'aliment',
                      hint: 'ex: Burger maison, Lait entier…',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 10),
                    // Sélecteur type de repas
                    Text('Repas',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.grey[300] : Colors.grey[700])),
                    const SizedBox(height: 6),
                    Row(
                      children: _mealTypes.map((type) {
                        final selected = type == selectedType;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: GestureDetector(
                              onTap: () => setSheetState(() => selectedType = type),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? TColors.primary.withOpacity(0.15)
                                      : (isDark ? Colors.grey[900] : Colors.grey[100]),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: selected ? TColors.primary : Colors.transparent,
                                  ),
                                ),
                                child: Text(
                                  _mealLabels[type]!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: selected
                                        ? TColors.primary
                                        : (isDark ? Colors.grey[400] : Colors.grey[600]),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    // Calories (pleine largeur)
                    _FreestyleField(
                      controller: caloriesCtrl,
                      label: 'Calories (kcal) *',
                      hint: '0',
                      isDark: isDark,
                      numeric: true,
                    ),
                    const SizedBox(height: 10),
                    // Macros sur 2 colonnes
                    Row(
                      children: [
                        Expanded(
                          child: _FreestyleField(
                            controller: proteinCtrl,
                            label: 'Protéines (g)',
                            hint: '0',
                            isDark: isDark,
                            numeric: true,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _FreestyleField(
                            controller: carbsCtrl,
                            label: 'Glucides (g)',
                            hint: '0',
                            isDark: isDark,
                            numeric: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _FreestyleField(
                            controller: fatCtrl,
                            label: 'Lipides (g)',
                            hint: '0',
                            isDark: isDark,
                            numeric: true,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _FreestyleField(
                            controller: fiberCtrl,
                            label: 'Fibres (g)',
                            hint: '0',
                            isDark: isDark,
                            numeric: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                final name = nameCtrl.text.trim();
                                final calories = double.tryParse(caloriesCtrl.text.trim());
                                if (name.isEmpty || calories == null) return;
                                setSheetState(() => isSaving = true);
                                try {
                                  final userId = _ctrl.userId.value!;
                                  await _auth.addMeal(
                                    userId,
                                    mealType: selectedType,
                                    description: name,
                                    calories: calories,
                                    proteinG: double.tryParse(proteinCtrl.text.trim()) ?? 0,
                                    carbsG: double.tryParse(carbsCtrl.text.trim()) ?? 0,
                                    fatG: double.tryParse(fatCtrl.text.trim()) ?? 0,
                                    fiberG: double.tryParse(fiberCtrl.text.trim()) ?? 0,
                                  );
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  await _loadMeals();
                                } catch (e) {
                                  setSheetState(() => isSaving = false);
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(
                                        content: Text('Erreur : $e'),
                                        backgroundColor: Colors.red[700],
                                      ),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Ajouter',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteMeal(int mealId) async {
    final userId = _ctrl.userId.value;
    if (userId == null) return;
    try {
      await _auth.deleteMeal(userId, mealId);
      await _loadMeals();
    } catch (e) {
      debugPrint('DELETE MEAL ERROR: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: isDark ? TColors.darkBackground : Colors.white,
      body: RefreshIndicator(
        onRefresh: _loadMeals,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Titre ─────────────────────────────────────────────────────
              Row(
                children: [
                  Icon(Iconsax.health, color: TColors.primary, size: 20),
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
              const SizedBox(height: 6),
              Text(
                "Aujourd'hui",
                style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
              const SizedBox(height: 20),

              // ── Compteur journalier ────────────────────────────────────────
              _DailyCounter(
                calories: _totalCalories,
                maintenanceCalories: _maintenanceCalories,
                protein: _totalProtein,
                fat: _totalFat,
                carbs: _totalCarbs,
                fiber: _totalFiber,
                isDark: isDark,
              ),
              const SizedBox(height: 24),

              // ── Cards repas ────────────────────────────────────────────────
              ..._mealTypes.map((type) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _MealCard(
                      mealType: type,
                      label: _mealLabels[type]!,
                      icon: _mealIcons[type]!,
                      meals: _mealsOf(type),
                      isDark: isDark,
                      onAdd: () => _openAddSheet(type),
                      onDelete: _deleteMeal,
                    ),
                  )),

              // ── Saisie manuelle ────────────────────────────────────────────
              _FreestyleCard(isDark: isDark, onAdd: _openFreestyleSheet),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Widget compteur journalier ───────────────────────────────────────────────

class _DailyCounter extends StatelessWidget {
  final double calories, maintenanceCalories, protein, fat, carbs, fiber;
  final bool isDark;

  const _DailyCounter({
    required this.calories,
    required this.maintenanceCalories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.fiber,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (calories / maintenanceCalories).clamp(0.0, 1.0);
    final remaining = (maintenanceCalories - calories).clamp(0.0, double.infinity);
    final Color barColor = progress < 0.75
        ? Colors.green
        : progress < 1.0
            ? Colors.orange
            : Colors.red;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.transparent : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ligne calories consommées / maintien
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Calories du jour',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: THelperFunctions.textColor(context))),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${calories.toStringAsFixed(0)} ',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: barColor),
                    ),
                    TextSpan(
                      text: '/ ${maintenanceCalories.toStringAsFixed(0)} kcal',
                      style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[400] : Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Barre de progression
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            remaining > 0
                ? '${remaining.toStringAsFixed(0)} kcal restantes'
                : 'Objectif de maintien atteint',
            style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.grey[400] : Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          // Macros
          Row(
            children: [
              _MacroChip(label: 'Protéines', value: protein, color: Colors.blue),
              const SizedBox(width: 8),
              _MacroChip(label: 'Glucides', value: carbs, color: Colors.orange),
              const SizedBox(width: 8),
              _MacroChip(label: 'Lipides', value: fat, color: Colors.red[300]!),
              const SizedBox(width: 8),
              _MacroChip(label: 'Fibres', value: fiber, color: Colors.green),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _MacroChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text('${value.toStringAsFixed(0)}g',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(fontSize: 10, color: color.withOpacity(0.8)),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ─── Widget card repas ────────────────────────────────────────────────────────

class _MealCard extends StatelessWidget {
  final String mealType;
  final String label;
  final IconData icon;
  final List<MealEntry> meals;
  final bool isDark;
  final VoidCallback onAdd;
  final void Function(int mealId) onDelete;

  const _MealCard({
    required this.mealType,
    required this.label,
    required this.icon,
    required this.meals,
    required this.isDark,
    required this.onAdd,
    required this.onDelete,
  });

  double get _totalCal => meals.fold(0, (s, m) => s + m.calories);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.transparent : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
            child: Row(
              children: [
                Icon(icon, color: TColors.primary, size: 20),
                const SizedBox(width: 10),
                Text(label,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: THelperFunctions.textColor(context))),
                const Spacer(),
                if (meals.isNotEmpty)
                  Text('${_totalCal.toStringAsFixed(0)} kcal',
                      style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[400] : Colors.grey[600])),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: onAdd,
                  icon: Icon(Iconsax.add_circle, color: TColors.primary, size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Liste des entrées
          if (meals.isNotEmpty) ...[
            Divider(height: 1, color: Colors.grey.withOpacity(0.15)),
            ...meals.map((m) => _MealEntryTile(
                  entry: m,
                  isDark: isDark,
                  onDelete: () => onDelete(m.id),
                )),
          ] else
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 14),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Rien d\'ajouté',
                    style: TextStyle(
                        fontSize: 13,
                        color:
                            isDark ? Colors.grey[600] : Colors.grey[400])),
              ),
            ),
        ],
      ),
    );
  }
}

class _MealEntryTile extends StatelessWidget {
  final MealEntry entry;
  final bool isDark;
  final VoidCallback onDelete;

  const _MealEntryTile(
      {required this.entry, required this.isDark, required this.onDelete});

  void _showDetail(BuildContext context) {
    final lines = entry.description
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: isDark ? TColors.darkBackground : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Détail du repas',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: THelperFunctions.textColor(context))),
            const SizedBox(height: 12),
            // Aliments
            ...lines.map((line) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Iconsax.arrow_right_3,
                          size: 14, color: TColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(line,
                            style: TextStyle(
                                fontSize: 13,
                                color: THelperFunctions.textColor(context))),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
            Divider(color: Colors.grey.withOpacity(0.2)),
            const SizedBox(height: 12),
            // Tableau macros
            _MacroRow('Calories', '${entry.calories.toStringAsFixed(0)} kcal',
                TColors.primary, isDark),
            _MacroRow('Protéines', '${entry.proteinG.toStringAsFixed(1)} g',
                Colors.blue, isDark),
            _MacroRow('Glucides', '${entry.carbsG.toStringAsFixed(1)} g',
                Colors.orange, isDark),
            _MacroRow('Lipides', '${entry.fatG.toStringAsFixed(1)} g',
                Colors.red[300]!, isDark),
            _MacroRow('Fibres', '${entry.fiberG.toStringAsFixed(1)} g',
                Colors.green, isDark),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onDelete();
                },
                icon: Icon(Iconsax.trash, size: 16, color: Colors.red[400]),
                label: Text('Supprimer ce repas',
                    style: TextStyle(color: Colors.red[400])),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.red[300]!),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showDetail(context),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.description,
                    style: TextStyle(
                        fontSize: 13,
                        color: THelperFunctions.textColor(context)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 2,
                    children: [
                      _MiniMacro('${entry.calories.toStringAsFixed(0)} kcal',
                          TColors.primary),
                      _MiniMacro(
                          'P ${entry.proteinG.toStringAsFixed(0)}g', Colors.blue),
                      _MiniMacro('G ${entry.carbsG.toStringAsFixed(0)}g',
                          Colors.orange),
                      _MiniMacro(
                          'L ${entry.fatG.toStringAsFixed(0)}g', Colors.red[300]!),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Iconsax.arrow_right_3,
                size: 16,
                color: isDark ? Colors.grey[600] : Colors.grey[400]),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _MacroRow(this.label, this.value, this.color, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 10),
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      color: THelperFunctions.textColor(context))),
            ],
          ),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ],
      ),
    );
  }
}

class _MiniMacro extends StatelessWidget {
  final String text;
  final Color color;

  const _MiniMacro(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w500));
  }
}

// ─── Card saisie manuelle ─────────────────────────────────────────────────────

class _FreestyleCard extends StatelessWidget {
  final bool isDark;
  final VoidCallback onAdd;

  const _FreestyleCard({required this.isDark, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onAdd,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? Colors.transparent : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: TColors.primary.withOpacity(0.3),
            style: BorderStyle.solid,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: TColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Iconsax.edit, color: TColors.primary, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Saisie manuelle',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: THelperFunctions.textColor(context))),
                  const SizedBox(height: 2),
                  Text("Edamam ne reconnaît pas l'aliment ? Entre les macros toi-même.",
                      style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[400] : Colors.grey[600])),
                ],
              ),
            ),
            Icon(Iconsax.arrow_right_3, size: 16, color: TColors.primary),
          ],
        ),
      ),
    );
  }
}

// ─── Champ texte freestyle ────────────────────────────────────────────────────

class _FreestyleField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool isDark;
  final bool numeric;

  const _FreestyleField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.isDark,
    this.numeric = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[300] : Colors.grey[700])),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: numeric
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          style: TextStyle(
              color: THelperFunctions.textColor(context), fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                color: isDark ? Colors.grey[600] : Colors.grey[400],
                fontSize: 13),
            filled: true,
            fillColor: isDark ? Colors.grey[900] : Colors.grey[50],
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: Colors.grey.withOpacity(0.3), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: TColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
