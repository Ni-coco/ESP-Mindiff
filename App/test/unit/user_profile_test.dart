import 'package:flutter_test/flutter_test.dart';
import 'package:mindiff_app/features/user_profile/domain/entities/user.dart';

void main() {
  const baseUser = UserProfile(
    id: 1,
    email: 'test@example.com',
    firstName: 'Alice',
    lastName: 'Dupont',
    weightKg: 65.0,
    heightCm: 170.0,
    sportObjective: 'perte de poids',
    themeMode: MyThemeMode.light,
  );

  group('UserProfile.copyWith', () {
    test('met à jour le poids uniquement', () {
      final updated = baseUser.copyWith(weightKg: 63.0);

      expect(updated.weightKg, 63.0);
      expect(updated.heightCm, 170.0);
      expect(updated.firstName, 'Alice');
      expect(updated.id, 1);
    });

    test('met à jour plusieurs champs simultanément', () {
      final updated = baseUser.copyWith(
        weightKg: 60.0,
        heightCm: 168.0,
        sportObjective: 'prise de masse',
      );

      expect(updated.weightKg, 60.0);
      expect(updated.heightCm, 168.0);
      expect(updated.sportObjective, 'prise de masse');
      expect(updated.email, 'test@example.com');
    });

    test('change le thème de light à dark', () {
      final updated = baseUser.copyWith(themeMode: MyThemeMode.dark);

      expect(updated.themeMode, MyThemeMode.dark);
      expect(updated.firstName, 'Alice');
    });

    test('ne modifie rien si aucun argument', () {
      final updated = baseUser.copyWith();

      expect(updated.id, baseUser.id);
      expect(updated.email, baseUser.email);
      expect(updated.firstName, baseUser.firstName);
      expect(updated.lastName, baseUser.lastName);
      expect(updated.weightKg, baseUser.weightKg);
      expect(updated.heightCm, baseUser.heightCm);
      expect(updated.sportObjective, baseUser.sportObjective);
      expect(updated.themeMode, baseUser.themeMode);
    });

    test('l\'id et l\'email ne peuvent pas être modifiés via copyWith', () {
      final updated = baseUser.copyWith(weightKg: 70.0);

      // id et email sont immuables (non exposés dans copyWith)
      expect(updated.id, 1);
      expect(updated.email, 'test@example.com');
    });
  });

  group('UserProfile valeurs par défaut', () {
    test('themeMode vaut system par défaut', () {
      const user = UserProfile(
        id: 2,
        email: 'bob@example.com',
        firstName: 'Bob',
        lastName: 'Martin',
      );

      expect(user.themeMode, MyThemeMode.system);
    });

    test('les champs optionnels sont null par défaut', () {
      const user = UserProfile(
        id: 3,
        email: 'carol@example.com',
        firstName: 'Carol',
        lastName: 'Lee',
      );

      expect(user.weightKg, isNull);
      expect(user.heightCm, isNull);
      expect(user.sportObjective, isNull);
      expect(user.avatarUrl, isNull);
    });
  });

  group('MyThemeMode enum', () {
    test('contient les trois valeurs attendues', () {
      expect(MyThemeMode.values, containsAll([
        MyThemeMode.light,
        MyThemeMode.dark,
        MyThemeMode.system,
      ]));
    });
  });
}
