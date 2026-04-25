import 'package:flutter_test/flutter_test.dart';
import 'package:mindiff_app/controllers/active_programme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ActiveProgrammeController', () {
    test('demarrer initialise un programme actif avec une séance', () {
      final controller = ActiveProgrammeController();
      const exercice = ProgrammeExercice(
        nom: 'Squat',
        emoji: '🏋️',
        analyzerKey: 'squat',
        series: 3,
        repsCible: 12,
      );

      controller.demarrer(
        programmeId: 1,
        nom: 'Force',
        couleurValue: 0xFF000000,
        exercices: const [exercice],
      );

      expect(controller.hasActive, isTrue);
      expect(controller.activeProgramme.value!.nom, 'Force');
      expect(controller.activeProgramme.value!.seances.length, 1);
      expect(
        controller.activeProgramme.value!.seanceEnCours!.progressions,
        contains('squat'),
      );
    });

    test('validerSerie incrémente la progression et termine la séance', () {
      final controller = ActiveProgrammeController();
      const exercice = ProgrammeExercice(
        nom: 'Pompes',
        emoji: '💪',
        analyzerKey: 'pushup',
        series: 2,
        repsCible: 10,
      );
      controller.demarrer(
        programmeId: 2,
        nom: 'Pecs',
        couleurValue: 0xFFFFFFFF,
        exercices: const [exercice],
      );

      controller.validerSerie('pushup', 10);
      controller.validerSerie('pushup', 9);

      final seance = controller.activeProgramme.value!.seances.first;
      final progression = seance.progressions['pushup']!;
      expect(progression.seriesCompletes, 2);
      expect(progression.repsParSerie, [10, 9]);
      expect(seance.terminee, isTrue);
    });

    test('nouvelleSeance ajoute une nouvelle séance', () {
      final controller = ActiveProgrammeController();
      const exercice = ProgrammeExercice(
        nom: 'Gainage',
        emoji: '🧱',
        analyzerKey: 'plank',
        series: 1,
        repsCible: 30,
        isSeconds: true,
      );
      controller.demarrer(
        programmeId: 3,
        nom: 'Core',
        couleurValue: 0xFF00FF00,
        exercices: const [exercice],
      );

      controller.nouvelleSeance();

      final data = controller.activeProgramme.value!;
      expect(data.seances.length, 2);
      expect(data.seances.last.numero, 2);
    });

    test('arreter supprime le programme actif', () {
      final controller = ActiveProgrammeController();
      const exercice = ProgrammeExercice(
        nom: 'Row',
        emoji: '🫷',
        analyzerKey: 'row',
        series: 3,
        repsCible: 8,
      );
      controller.demarrer(
        programmeId: 4,
        nom: 'Dos',
        couleurValue: 0xFF112233,
        exercices: const [exercice],
      );

      controller.arreter();

      expect(controller.hasActive, isFalse);
      expect(controller.activeProgramme.value, isNull);
    });
  });
}
