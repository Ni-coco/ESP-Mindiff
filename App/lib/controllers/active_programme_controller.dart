import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Modèle d'un exercice structuré dans un programme
// ---------------------------------------------------------------------------

class ProgrammeExercice {
  final String nom;
  final String emoji;
  final String analyzerKey; // clé qui map vers kExercises (ex: "squat")
  final int series;
  final int repsCible;
  final bool isSeconds; // true pour planche (secondes au lieu de reps)

  const ProgrammeExercice({
    required this.nom,
    required this.emoji,
    required this.analyzerKey,
    required this.series,
    required this.repsCible,
    this.isSeconds = false,
  });

  Map<String, dynamic> toJson() => {
        'nom': nom,
        'emoji': emoji,
        'analyzerKey': analyzerKey,
        'series': series,
        'repsCible': repsCible,
        'isSeconds': isSeconds,
      };

  factory ProgrammeExercice.fromJson(Map<String, dynamic> json) =>
      ProgrammeExercice(
        nom: json['nom'],
        emoji: json['emoji'],
        analyzerKey: json['analyzerKey'],
        series: json['series'],
        repsCible: json['repsCible'],
        isSeconds: json['isSeconds'] ?? false,
      );
}

// ---------------------------------------------------------------------------
// Progression d'un exercice dans une séance
// ---------------------------------------------------------------------------

class ExerciceProgression {
  final String analyzerKey;
  int seriesCompletes;
  List<int> repsParSerie; // reps validées par série

  ExerciceProgression({
    required this.analyzerKey,
    this.seriesCompletes = 0,
    List<int>? repsParSerie,
  }) : repsParSerie = repsParSerie ?? [];

  bool estTermine(ProgrammeExercice exercice) =>
      seriesCompletes >= exercice.series;

  Map<String, dynamic> toJson() => {
        'analyzerKey': analyzerKey,
        'seriesCompletes': seriesCompletes,
        'repsParSerie': repsParSerie,
      };

  factory ExerciceProgression.fromJson(Map<String, dynamic> json) =>
      ExerciceProgression(
        analyzerKey: json['analyzerKey'],
        seriesCompletes: json['seriesCompletes'] ?? 0,
        repsParSerie: List<int>.from(json['repsParSerie'] ?? []),
      );
}

// ---------------------------------------------------------------------------
// Séance (une session de workout)
// ---------------------------------------------------------------------------

class Seance {
  final int numero; // numéro de la séance (1, 2, 3...)
  final DateTime date;
  final Map<String, ExerciceProgression> progressions; // analyzerKey -> progression
  bool terminee;

  Seance({
    required this.numero,
    required this.date,
    required this.progressions,
    this.terminee = false,
  });

  Map<String, dynamic> toJson() => {
        'numero': numero,
        'date': date.toIso8601String(),
        'progressions':
            progressions.map((k, v) => MapEntry(k, v.toJson())),
        'terminee': terminee,
      };

  factory Seance.fromJson(Map<String, dynamic> json) => Seance(
        numero: json['numero'],
        date: DateTime.parse(json['date']),
        progressions: (json['progressions'] as Map<String, dynamic>).map(
          (k, v) =>
              MapEntry(k, ExerciceProgression.fromJson(v)),
        ),
        terminee: json['terminee'] ?? false,
      );
}

// ---------------------------------------------------------------------------
// Programme actif (données persistées)
// ---------------------------------------------------------------------------

class ActiveProgrammeData {
  final int programmeId;
  final String nom;
  final int couleurValue;
  final List<ProgrammeExercice> exercices;
  final List<Seance> seances;
  final DateTime dateDebut;

  ActiveProgrammeData({
    required this.programmeId,
    required this.nom,
    required this.couleurValue,
    required this.exercices,
    required this.seances,
    required this.dateDebut,
  });

  int get seancesTerminees => seances.where((s) => s.terminee).length;

  Seance? get seanceEnCours {
    try {
      return seances.firstWhere((s) => !s.terminee);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toJson() => {
        'programmeId': programmeId,
        'nom': nom,
        'couleurValue': couleurValue,
        'exercices': exercices.map((e) => e.toJson()).toList(),
        'seances': seances.map((s) => s.toJson()).toList(),
        'dateDebut': dateDebut.toIso8601String(),
      };

  factory ActiveProgrammeData.fromJson(Map<String, dynamic> json) =>
      ActiveProgrammeData(
        programmeId: json['programmeId'],
        nom: json['nom'],
        couleurValue: json['couleurValue'],
        exercices: (json['exercices'] as List)
            .map((e) => ProgrammeExercice.fromJson(e))
            .toList(),
        seances: (json['seances'] as List)
            .map((s) => Seance.fromJson(s))
            .toList(),
        dateDebut: DateTime.parse(json['dateDebut']),
      );
}

// ---------------------------------------------------------------------------
// Contrôleur GetX
// ---------------------------------------------------------------------------

class ActiveProgrammeController extends GetxController {
  static const _storageKey = 'active_programme';

  final Rxn<ActiveProgrammeData> activeProgramme = Rxn<ActiveProgrammeData>();

  bool get hasActive => activeProgramme.value != null;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  // ── Démarrer un programme ──────────────────────────────────────────────

  void demarrer({
    required int programmeId,
    required String nom,
    required int couleurValue,
    required List<ProgrammeExercice> exercices,
  }) {
    final seance = _creerSeance(1, exercices);
    activeProgramme.value = ActiveProgrammeData(
      programmeId: programmeId,
      nom: nom,
      couleurValue: couleurValue,
      exercices: exercices,
      seances: [seance],
      dateDebut: DateTime.now(),
    );
    _save();
  }

  // ── Valider une série pour un exercice ─────────────────────────────────

  void validerSerie(String analyzerKey, int reps) {
    final data = activeProgramme.value;
    if (data == null) return;

    final seance = data.seanceEnCours;
    if (seance == null) return;

    final progression = seance.progressions[analyzerKey];
    if (progression == null) return;

    final exercice = data.exercices.firstWhere(
      (e) => e.analyzerKey == analyzerKey,
    );

    if (progression.estTermine(exercice)) return;

    progression.repsParSerie.add(reps);
    progression.seriesCompletes++;

    // Vérifier si toute la séance est terminée
    final toutTermine = data.exercices.every((ex) {
      final prog = seance.progressions[ex.analyzerKey];
      return prog != null && prog.estTermine(ex);
    });

    if (toutTermine) {
      seance.terminee = true;
    }

    activeProgramme.refresh();
    _save();
  }

  // ── Commencer une nouvelle séance ──────────────────────────────────────

  void nouvelleSeance() {
    final data = activeProgramme.value;
    if (data == null) return;

    final seance = _creerSeance(data.seances.length + 1, data.exercices);
    data.seances.add(seance);
    activeProgramme.refresh();
    _save();
  }

  // ── Arrêter / abandonner le programme ──────────────────────────────────

  void arreter() {
    activeProgramme.value = null;
    _save();
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  Seance _creerSeance(int numero, List<ProgrammeExercice> exercices) {
    return Seance(
      numero: numero,
      date: DateTime.now(),
      progressions: {
        for (final ex in exercices)
          ex.analyzerKey: ExerciceProgression(analyzerKey: ex.analyzerKey),
      },
    );
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    if (activeProgramme.value == null) {
      await prefs.remove(_storageKey);
    } else {
      await prefs.setString(
          _storageKey, jsonEncode(activeProgramme.value!.toJson()));
    }
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      try {
        activeProgramme.value =
            ActiveProgrammeData.fromJson(jsonDecode(raw));
      } catch (_) {
        await prefs.remove(_storageKey);
      }
    }
  }
}
