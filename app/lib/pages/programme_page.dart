// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mindiff_app/controllers/user_profile_controller.dart';
import 'package:mindiff_app/services/auth_service.dart';
import 'package:mindiff_app/utils/theme.dart';

// ─── Modèles locaux ───────────────────────────────────────────────────────────

class _Exercise {
  final String id, name, target, gifUrl, equipment;
  _Exercise({required this.id, required this.name, required this.target, required this.gifUrl, required this.equipment});
  factory _Exercise.fromJson(Map<String, dynamic> j) => _Exercise(
        id: j['id'] as String,
        name: j['name'] as String,
        target: j['target'] as String? ?? '',
        gifUrl: j['gif_url'] as String? ?? '',
        equipment: j['equipment'] as String? ?? '',
      );
}

class _WorkoutExercise {
  final String exerciseId, exerciseName, target, gifUrl, equipment;
  final int sets, repsMin, repsMax;
  final bool isCardio;
  _WorkoutExercise.fromJson(Map<String, dynamic> j)
      : exerciseId = (j['exercise'] as Map)['id'] as String,
        exerciseName = (j['exercise'] as Map)['name'] as String,
        target = (j['exercise'] as Map)['target'] as String? ?? '',
        gifUrl = (j['exercise'] as Map)['gif_url'] as String? ?? '',
        equipment = (j['exercise'] as Map)['equipment'] as String? ?? '',
        sets = j['sets'] as int,
        repsMin = j['reps_min'] as int,
        repsMax = j['reps_max'] as int,
        isCardio = j['is_cardio'] as bool;
}

class _Session {
  final int id, sessionNumber, durationMinutes;
  final String splitName;
  final List<_WorkoutExercise> exercises;
  _Session.fromJson(Map<String, dynamic> j)
      : id = j['id'] as int,
        sessionNumber = j['session_number'] as int,
        splitName = j['split_name'] as String,
        durationMinutes = j['duration_minutes'] as int,
        exercises = (j['exercises'] as List).map((e) => _WorkoutExercise.fromJson(e as Map<String, dynamic>)).toList();
}

class _WorkoutWeek {
  final int id, sessionsPerWeek, weekNumber;
  final String? goal;
  final bool isPinned;
  final List<_Session> sessions;
  _WorkoutWeek.fromJson(Map<String, dynamic> j)
      : id = j['id'] as int,
        sessionsPerWeek = j['sessions_per_week'] as int,
        weekNumber = j['week_number'] as int,
        goal = j['goal'] as String?,
        isPinned = j['is_pinned'] as bool,
        sessions = (j['sessions'] as List).map((e) => _Session.fromJson(e as Map<String, dynamic>)).toList();
}

class _CustomWorkout {
  final int id;
  final String name;
  final List<_WorkoutExercise> exercises;
  _CustomWorkout.fromJson(Map<String, dynamic> j)
      : id = j['id'] as int,
        name = j['name'] as String,
        exercises = (j['exercises'] as List).map((e) => _WorkoutExercise.fromJson(e as Map<String, dynamic>)).toList();
}

// ─── Constantes ───────────────────────────────────────────────────────────────

const _goalLabels = {
  'lose_weight': 'Perdre du poids',
  'build_muscle': 'Prendre du muscle',
  'maintain': 'Maintenir',
  'improve_endurance': 'Endurance',
  'increase_strength': 'Force',
  'general_fitness': 'Forme générale',
};

const _allTargets = [
  'abs', 'adductors', 'abductors', 'biceps', 'calves',
  'cardiovascular system', 'delts', 'forearms', 'glutes',
  'hamstrings', 'lats', 'pectorals', 'quads', 'serratus anterior',
  'traps', 'triceps', 'upper back',
];

// ─── Page ─────────────────────────────────────────────────────────────────────

class ProgrammePage extends StatefulWidget {
  const ProgrammePage({super.key});

  @override
  State<ProgrammePage> createState() => _ProgrammePageState();
}

class _ProgrammePageState extends State<ProgrammePage> {
  final _ctrl = Get.find<UserProfileController>();
  final _auth = Get.find<AuthService>();

  _WorkoutWeek? _week;
  List<_CustomWorkout> _customs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = _ctrl.userId.value;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final results = await Future.wait([
        _auth.getCurrentWorkout(userId),
        _auth.getCustomWorkouts(userId),
      ]);
      setState(() {
        _week = _WorkoutWeek.fromJson(results[0] as Map<String, dynamic>);
        _customs = (results[1] as List).map((e) => _CustomWorkout.fromJson(e as Map<String, dynamic>)).toList();
      });
    } catch (e) {
      debugPrint('PROGRAMME ERROR: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _regenerate() async {
    final userId = _ctrl.userId.value;
    if (userId == null) return;
    setState(() => _isLoading = true);
    try {
      final data = await _auth.regenerateWorkout(userId);
      setState(() => _week = _WorkoutWeek.fromJson(data));
    } catch (e) {
      debugPrint('REGENERATE ERROR: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pin() async {
    final userId = _ctrl.userId.value;
    if (userId == null || _week == null) return;
    try {
      final data = await _auth.pinWorkout(userId, _week!.id);
      setState(() => _week = _WorkoutWeek.fromJson(data));
    } catch (e) {
      debugPrint('PIN ERROR: $e');
    }
  }

  Future<void> _deleteCustom(int workoutId) async {
    final userId = _ctrl.userId.value;
    if (userId == null) return;
    try {
      await _auth.deleteCustomWorkout(userId, workoutId);
      setState(() => _customs.removeWhere((c) => c.id == workoutId));
    } catch (e) {
      debugPrint('DELETE CUSTOM ERROR: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Obx(() {
      final goal = _ctrl.primaryGoal.value;
      final sessions = _ctrl.sessionsPerWeek.value;

      return Scaffold(
        backgroundColor: isDark ? TColors.darkBackground : Colors.white,
        body: RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Titre ───────────────────────────────────────────────────
                Row(children: [
                  Icon(Iconsax.activity, color: TColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('Programmes',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: THelperFunctions.textColor(context),
                            fontSize: 22,
                          )),
                ]),
                const SizedBox(height: 8),

                // ── Bannière profil ──────────────────────────────────────────
                if (goal != null || sessions != null)
                  _RecommendationBanner(
                    text: _bannerText(goal, sessions),
                    isDark: isDark,
                  ),
                const SizedBox(height: 4),
                Text(
                  sessions != null ? '$sessions séance${sessions > 1 ? 's' : ''}/semaine' : '',
                  style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
                const SizedBox(height: 24),

                // ── Programme de la semaine ──────────────────────────────────
                _SectionHeader(
                  title: 'Programme de la semaine',
                  trailing: _week != null
                      ? Row(mainAxisSize: MainAxisSize.min, children: [
                          if (!(_week!.isPinned))
                            _ActionChip(
                              icon: Iconsax.lock,
                              label: 'Épingler',
                              onTap: _pin,
                              isDark: isDark,
                            ),
                          const SizedBox(width: 8),
                          if (!(_week!.isPinned))
                            _ActionChip(
                              icon: Iconsax.refresh,
                              label: 'Nouveau',
                              onTap: _regenerate,
                              isDark: isDark,
                            ),
                          if (_week!.isPinned)
                            _ActionChip(
                              icon: Iconsax.lock_1,
                              label: 'Épinglé',
                              onTap: null,
                              isDark: isDark,
                            ),
                        ])
                      : null,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),

                if (_week == null)
                  _EmptyCard(
                    text: 'Impossible de charger le programme.',
                    isDark: isDark,
                  )
                else
                  ..._week!.sessions.map((session) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _SessionCard(
                          session: session,
                          isDark: isDark,
                          onTap: () => _showSessionDetail(session, isDark),
                        ),
                      )),

                const SizedBox(height: 28),

                // ── Séances custom ───────────────────────────────────────────
                _SectionHeader(
                  title: 'Mes séances custom',
                  trailing: _ActionChip(
                    icon: Iconsax.add,
                    label: 'Créer',
                    onTap: () => _openCustomBuilder(isDark),
                    isDark: isDark,
                  ),
                  isDark: isDark,
                ),
                const SizedBox(height: 12),

                if (_customs.isEmpty)
                  _EmptyCard(
                    text: 'Aucune séance custom. Crées-en une !',
                    isDark: isDark,
                  )
                else
                  ..._customs.map((cw) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _CustomWorkoutCard(
                          workout: cw,
                          isDark: isDark,
                          onTap: () => _showCustomDetail(cw, isDark),
                          onDelete: () => _deleteCustom(cw.id),
                        ),
                      )),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      );
    });
  }

  // ── Bottom sheet détail séance générée ──────────────────────────────────────

  void _showSessionDetail(_Session session, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SessionDetailSheet(session: session, isDark: isDark, auth: _auth),
    );
  }

  // ── Bottom sheet détail custom ────────────────────────────────────────────

  void _showCustomDetail(_CustomWorkout cw, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CustomDetailSheet(workout: cw, isDark: isDark, auth: _auth),
    );
  }

  // ── Builder de séance custom ──────────────────────────────────────────────

  void _openCustomBuilder(bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CustomBuilderSheet(
        isDark: isDark,
        auth: _auth,
        onSaved: (name, exercises) async {
          final userId = _ctrl.userId.value;
          if (userId == null) return;
          try {
            final data = await _auth.createCustomWorkout(userId, name: name, exercises: exercises);
            setState(() => _customs.add(_CustomWorkout.fromJson(data)));
          } catch (e) {
            debugPrint('CREATE CUSTOM ERROR: $e');
          }
        },
      ),
    );
  }

  String _bannerText(String? goal, int? sessions) {
    final g = goal != null ? _goalLabels[goal] : null;
    if (g != null && sessions != null) return 'Objectif : $g • $sessions séance${sessions > 1 ? 's' : ''}/sem.';
    if (g != null) return 'Objectif : $g';
    if (sessions != null) return '$sessions séance${sessions > 1 ? 's' : ''}/semaine';
    return 'Programme personnalisé';
  }
}

// ─── Widgets internes ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final bool isDark;
  const _SectionHeader({required this.title, this.trailing, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: THelperFunctions.textColor(context),
                )),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isDark;
  const _ActionChip({required this.icon, required this.label, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: TColors.primary.withOpacity(onTap != null ? 0.12 : 0.06),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: onTap != null ? TColors.primary : Colors.grey),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: onTap != null ? TColors.primary : Colors.grey)),
        ]),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String text;
  final bool isDark;
  const _EmptyCard({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.transparent : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Text(text, style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[500] : Colors.grey[400])),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final _Session session;
  final bool isDark;
  final VoidCallback onTap;
  const _SessionCard({required this.session, required this.isDark, required this.onTap});

  Color get _splitColor {
    switch (session.splitName) {
      case 'Push': return const Color(0xFF2196F3);
      case 'Pull': return const Color(0xFF4CAF50);
      case 'Legs': return const Color(0xFFF44336);
      case 'Upper Body': return const Color(0xFF9C27B0);
      case 'Lower Body': return const Color(0xFFFF9800);
      case 'Chest': return const Color(0xFF2196F3);
      case 'Shoulders': return const Color(0xFF00BCD4);
      case 'Arms': return const Color(0xFFFF5722);
      case 'Back': return const Color(0xFF4CAF50);
      default: return TColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final strength = session.exercises.where((e) => !e.isCardio).length;
    final hasCardio = session.exercises.any((e) => e.isCardio);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.transparent : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.15)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Badge "Recommandé pour toi"
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: TColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('Recommandé pour toi',
                    style: TextStyle(color: TColors.primary, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ),
            Row(children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: _splitColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(_splitIcon(session.splitName), style: const TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Séance ${session.sessionNumber} — ${session.splitName}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: THelperFunctions.textColor(context),
                            fontSize: 17,
                          )),
                  const SizedBox(height: 4),
                  Text('$strength exercices${hasCardio ? ' + cardio' : ''}',
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[400] : Colors.grey[600])),
                ]),
              ),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              _InfoChip(context, Iconsax.clock, '${session.durationMinutes} min', isDark),
              const SizedBox(width: 8),
              _InfoChip(context, Iconsax.document, '$strength exos', isDark),
              if (hasCardio) ...[
                const SizedBox(width: 8),
                _InfoChip(context, Iconsax.heart, 'Cardio', isDark, color: Colors.red[300]),
              ],
            ]),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              Icon(Iconsax.arrow_right_3, size: 16, color: TColors.primary),
            ]),
          ]),
        ),
      ),
    );
  }

  String _splitIcon(String name) {
    switch (name) {
      case 'Push': return '🫸';
      case 'Pull': return '🫷';
      case 'Legs': return '🦵';
      case 'Upper Body': return '💪';
      case 'Lower Body': return '🦵';
      case 'Full Body': return '🏋️';
      case 'Chest': return '🫁';
      case 'Shoulders': return '🏋️';
      case 'Arms': return '💪';
      case 'Back': return '🔙';
      default: return '🏃';
    }
  }

  Widget _InfoChip(BuildContext context, IconData icon, String text, bool isDark, {Color? color}) {
    final c = color ?? TColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: c),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _CustomWorkoutCard extends StatelessWidget {
  final _CustomWorkout workout;
  final bool isDark;
  final VoidCallback onTap, onDelete;
  const _CustomWorkoutCard({required this.workout, required this.isDark, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.transparent : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.15)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: TColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(Iconsax.edit, color: TColors.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(workout.name,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: THelperFunctions.textColor(context))),
                const SizedBox(height: 2),
                Text('${workout.exercises.length} exercice${workout.exercises.length > 1 ? 's' : ''}',
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600])),
              ]),
            ),
            IconButton(
              onPressed: onDelete,
              icon: Icon(Iconsax.trash, size: 18, color: Colors.red[300]),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            Icon(Iconsax.arrow_right_3, size: 16, color: TColors.primary),
            const SizedBox(width: 8),
          ]),
        ),
      ),
    );
  }
}

// ─── Bottom sheet détail séance ───────────────────────────────────────────────

class _SessionDetailSheet extends StatelessWidget {
  final _Session session;
  final bool isDark;
  final AuthService auth;
  const _SessionDetailSheet({required this.session, required this.isDark, required this.auth});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? TColors.darkBackground : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          _SheetHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Séance ${session.sessionNumber} — ${session.splitName}',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: THelperFunctions.textColor(context))),
                  Text('${session.durationMinutes} min · ${session.exercises.length} exercices',
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[400] : Colors.grey[600])),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: Colors.grey.withOpacity(0.15)),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              itemCount: session.exercises.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
              itemBuilder: (_, i) => _ExerciseTile(ex: session.exercises[i], isDark: isDark, auth: auth),
            ),
          ),
        ]),
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  final _WorkoutExercise ex;
  final bool isDark;
  final AuthService auth;
  const _ExerciseTile({required this.ex, required this.isDark, required this.auth});

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExerciseDetailSheet(
        exerciseId: ex.exerciseId,
        exerciseName: ex.exerciseName,
        sets: ex.sets,
        repsMin: ex.repsMin,
        repsMax: ex.repsMax,
        isCardio: ex.isCardio,
        isDark: isDark,
        auth: auth,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showDetail(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: (ex.isCardio ? Colors.red[300] : TColors.primary)!.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(ex.isCardio ? Iconsax.heart : Iconsax.activity,
                size: 20, color: ex.isCardio ? Colors.red[300] : TColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(ex.exerciseName,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: THelperFunctions.textColor(context))),
              const SizedBox(height: 2),
              Text(ex.isCardio ? 'Cardio · ${ex.equipment}' : '${ex.sets} séries × ${ex.repsMin}-${ex.repsMax} reps · ${ex.target}',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600])),
            ]),
          ),
          Icon(Iconsax.arrow_right_3, size: 14, color: isDark ? Colors.grey[600] : Colors.grey[400]),
        ]),
      ),
    );
  }
}

// ─── Bottom sheet détail custom ───────────────────────────────────────────────

class _CustomDetailSheet extends StatelessWidget {
  final _CustomWorkout workout;
  final bool isDark;
  final AuthService auth;
  const _CustomDetailSheet({required this.workout, required this.isDark, required this.auth});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? TColors.darkBackground : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          _SheetHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(workout.name,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: THelperFunctions.textColor(context))),
            ),
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: Colors.grey.withOpacity(0.15)),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              itemCount: workout.exercises.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
              itemBuilder: (_, i) => _ExerciseTile(ex: workout.exercises[i], isDark: isDark, auth: auth),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Builder de séance custom ─────────────────────────────────────────────────

class _CustomBuilderSheet extends StatefulWidget {
  final bool isDark;
  final AuthService auth;
  final Future<void> Function(String name, List<Map<String, dynamic>> exercises) onSaved;
  const _CustomBuilderSheet({required this.isDark, required this.auth, required this.onSaved});

  @override
  State<_CustomBuilderSheet> createState() => _CustomBuilderSheetState();
}

class _CustomBuilderSheetState extends State<_CustomBuilderSheet> {
  final _nameCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  String? _selectedTarget;
  List<_Exercise> _searchResults = [];
  final List<_Exercise> _selected = [];
  bool _isSearching = false;
  bool _isSaving = false;

  Future<void> _search() async {
    setState(() => _isSearching = true);
    try {
      final data = await widget.auth.getExercises(
        target: _selectedTarget,
        q: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
        limit: 40,
      );
      setState(() => _searchResults = data.map((e) => _Exercise.fromJson(e as Map<String, dynamic>)).toList());
    } catch (e) {
      debugPrint('SEARCH ERROR: $e');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _selected.isEmpty) return;
    setState(() => _isSaving = true);
    try {
      final exercises = _selected.asMap().entries.map((e) => {
        'exercise_id': e.value.id,
        'position': e.key,
        'sets': 3,
        'reps_min': 8,
        'reps_max': 12,
      }).toList();
      await widget.onSaved(_nameCtrl.text.trim(), exercises);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: widget.isDark ? TColors.darkBackground : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          _SheetHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Créer une séance',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: THelperFunctions.textColor(context))),
              const SizedBox(height: 12),
              // Nom
              TextField(
                controller: _nameCtrl,
                style: TextStyle(color: THelperFunctions.textColor(context), fontSize: 14),
                decoration: _inputDecoration('Nom de la séance', widget.isDark),
              ),
              const SizedBox(height: 12),
              // Filtres par groupe musculaire
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _TargetChip(label: 'Tous', selected: _selectedTarget == null,
                        onTap: () { setState(() => _selectedTarget = null); _search(); }, isDark: widget.isDark),
                    ..._allTargets.map((t) => _TargetChip(
                          label: t,
                          selected: _selectedTarget == t,
                          onTap: () { setState(() => _selectedTarget = t); _search(); },
                          isDark: widget.isDark,
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Recherche texte
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    style: TextStyle(color: THelperFunctions.textColor(context), fontSize: 14),
                    decoration: _inputDecoration('Rechercher un exercice…', widget.isDark),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _search,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSearching
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Iconsax.search_normal, size: 18),
                ),
              ]),
              // Sélectionnés
              if (_selected.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text('${_selected.length} exercice${_selected.length > 1 ? 's' : ''} sélectionné${_selected.length > 1 ? 's' : ''}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: TColors.primary)),
              ],
            ]),
          ),
          Divider(height: 1, color: Colors.grey.withOpacity(0.15)),
          Expanded(
            child: _searchResults.isEmpty
                ? Center(
                    child: Text('Lance une recherche ou sélectionne un groupe musculaire.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: widget.isDark ? Colors.grey[500] : Colors.grey[400])),
                  )
                : ListView.separated(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    itemCount: _searchResults.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
                    itemBuilder: (_, i) {
                      final ex = _searchResults[i];
                      final isAdded = _selected.any((s) => s.id == ex.id);
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 6),
                        title: Text(ex.name,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: THelperFunctions.textColor(context))),
                        subtitle: Text('${ex.target} · ${ex.equipment}',
                            style: TextStyle(fontSize: 12, color: widget.isDark ? Colors.grey[400] : Colors.grey[600])),
                        trailing: GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isAdded) _selected.removeWhere((s) => s.id == ex.id);
                              else _selected.add(ex);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isAdded ? Colors.red.withOpacity(0.1) : TColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(isAdded ? Iconsax.minus : Iconsax.add,
                                size: 18, color: isAdded ? Colors.red[300] : TColors.primary),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // Bouton sauvegarder
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_selected.isEmpty || _isSaving) ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Sauvegarder${_selected.isEmpty ? '' : ' (${_selected.length} exos)'}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, bool isDark) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.grey[600] : Colors.grey[400], fontSize: 13),
        filled: true,
        fillColor: isDark ? Colors.grey[900] : Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withOpacity(0.3))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withOpacity(0.2))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: TColors.primary, width: 1.5)),
      );
}

class _TargetChip extends StatelessWidget {
  final String label;
  final bool selected, isDark;
  final VoidCallback onTap;
  const _TargetChip({required this.label, required this.selected, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? TColors.primary : (isDark ? Colors.grey[900] : Colors.grey[100]),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? TColors.primary : Colors.transparent),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[600]))),
      ),
    );
  }
}

// ─── Composants réutilisables ─────────────────────────────────────────────────

// ─── Bottom sheet détail exercice (GIF + instructions) ───────────────────────

class _ExerciseDetailSheet extends StatefulWidget {
  final String exerciseId, exerciseName;
  final int sets, repsMin, repsMax;
  final bool isCardio, isDark;
  final AuthService auth;

  const _ExerciseDetailSheet({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
    required this.repsMin,
    required this.repsMax,
    required this.isCardio,
    required this.isDark,
    required this.auth,
  });

  @override
  State<_ExerciseDetailSheet> createState() => _ExerciseDetailSheetState();
}

class _ExerciseDetailSheetState extends State<_ExerciseDetailSheet> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await widget.auth.getExercise(widget.exerciseId);
      if (mounted) setState(() => _data = data);
    } catch (e) {
      debugPrint('EXERCISE DETAIL ERROR: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gifUrl = _data?['gif_url'] as String?;
    final instructions = (_data?['instructions'] as List? ?? [])
        .map((e) => e as Map<String, dynamic>)
        .toList()
      ..sort((a, b) => (a['step_order'] as int).compareTo(b['step_order'] as int));
    final target = _data?['target'] as String?;
    final equipment = _data?['equipment'] as String?;
    final bodyPart = _data?['body_part'] as String?;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.90),
      child: Container(
        decoration: BoxDecoration(
          color: widget.isDark ? TColors.darkBackground : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          _SheetHandle(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      // Nom
                      Text(widget.exerciseName,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: THelperFunctions.textColor(context))),
                      const SizedBox(height: 6),
                      // Infos
                      Wrap(spacing: 8, runSpacing: 6, children: [
                        if (target != null) _Badge(target, TColors.primary),
                        if (bodyPart != null) _Badge(bodyPart, Colors.orange),
                        if (equipment != null) _Badge(equipment, Colors.grey),
                      ]),
                      const SizedBox(height: 16),
                      // Sets × reps
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: TColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                          _StatItem('Séries', '${widget.sets}'),
                          _Divider(),
                          _StatItem('Répétitions', '${widget.repsMin}–${widget.repsMax}'),
                          if (widget.isCardio) ...[
                            _Divider(),
                            _StatItem('Type', 'Cardio'),
                          ],
                        ]),
                      ),
                      const SizedBox(height: 20),
                      // GIF
                      if (gifUrl != null && gifUrl.isNotEmpty) ...[
                        Text('Démonstration',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: THelperFunctions.textColor(context))),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            gifUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (_, child, progress) => progress == null
                                ? child
                                : Container(
                                    height: 200,
                                    color: widget.isDark ? Colors.grey[900] : Colors.grey[100],
                                    child: const Center(child: CircularProgressIndicator()),
                                  ),
                            errorBuilder: (_, __, ___) => Container(
                              height: 140,
                              decoration: BoxDecoration(
                                color: widget.isDark ? Colors.grey[900] : Colors.grey[100],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Icon(Iconsax.video_slash, size: 32,
                                    color: widget.isDark ? Colors.grey[600] : Colors.grey[400]),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      // Instructions
                      if (instructions.isNotEmpty) ...[
                        Text('Instructions',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: THelperFunctions.textColor(context))),
                        const SizedBox(height: 10),
                        ...instructions.map((step) {
                          final order = step['step_order'] as int;
                          final text = step['text'] as String;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Container(
                                width: 24, height: 24,
                                decoration: BoxDecoration(
                                  color: TColors.primary.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text('$order',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: TColors.primary)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(text,
                                    style: TextStyle(
                                        fontSize: 13,
                                        height: 1.5,
                                        color: THelperFunctions.textColor(context))),
                              ),
                            ]),
                          );
                        }),
                      ],
                    ]),
                  ),
          ),
        ]),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge(this.text, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      );
}

class _StatItem extends StatelessWidget {
  final String label, value;
  const _StatItem(this.label, this.value);

  @override
  Widget build(BuildContext context) => Column(children: [
        Text(value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: TColors.primary)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(fontSize: 11, color: THelperFunctions.isDarkMode(context) ? Colors.grey[400] : Colors.grey[600])),
      ]);
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 30, color: Colors.grey.withOpacity(0.2));
}

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 12, bottom: 4),
        width: 40, height: 4,
        decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)),
      );
}

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
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Row(children: [
        Icon(Iconsax.magic_star, size: 18, color: TColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: THelperFunctions.textColor(context),
                  )),
        ),
      ]),
    );
  }
}
