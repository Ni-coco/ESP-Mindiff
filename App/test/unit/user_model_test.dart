import 'package:flutter_test/flutter_test.dart';
import 'package:mindiff_app/features/user_profile/data/models/user_model.dart';
import 'package:mindiff_app/features/user_profile/domain/entities/user.dart';

void main() {
  group('UserModel.fromJson', () {
    test('désérialise un JSON complet correctement', () {
      final json = {
        'id': 1,
        'email': 'test@example.com',
        'first_name': 'Alice',
        'last_name': 'Dupont',
        'weight_in_kg': 65.5,
        'height_in_cm': 170.0,
        'sport_objective': 'perte de poids',
        'avatar_url': 'https://example.com/avatar.png',
      };

      final model = UserModel.fromJson(json);

      expect(model.id, 1);
      expect(model.email, 'test@example.com');
      expect(model.firstName, 'Alice');
      expect(model.lastName, 'Dupont');
      expect(model.weightKg, 65.5);
      expect(model.heightCm, 170.0);
      expect(model.sportObjective, 'perte de poids');
      expect(model.avatarUrl, 'https://example.com/avatar.png');
    });

    test('désérialise un JSON avec champs optionnels null', () {
      final json = {
        'id': 2,
        'email': 'bob@example.com',
        'first_name': 'Bob',
        'last_name': 'Martin',
        'weight_in_kg': null,
        'height_in_cm': null,
        'sport_objective': null,
        'avatar_url': null,
      };

      final model = UserModel.fromJson(json);

      expect(model.id, 2);
      expect(model.weightKg, isNull);
      expect(model.heightCm, isNull);
      expect(model.sportObjective, isNull);
      expect(model.avatarUrl, isNull);
    });

    test('convertit weight_in_kg en double même si fourni en int', () {
      final json = {
        'id': 3,
        'email': 'carol@example.com',
        'first_name': 'Carol',
        'last_name': 'Lee',
        'weight_in_kg': 70,
        'height_in_cm': 165,
        'sport_objective': null,
        'avatar_url': null,
      };

      final model = UserModel.fromJson(json);

      expect(model.weightKg, 70.0);
      expect(model.heightCm, 165.0);
    });
  });

  group('UserModel.toJson', () {
    test('sérialise un modèle complet correctement', () {
      const model = UserModel(
        id: 1,
        email: 'test@example.com',
        firstName: 'Alice',
        lastName: 'Dupont',
        weightKg: 65.5,
        heightCm: 170.0,
        sportObjective: 'prise de masse',
        avatarUrl: 'https://example.com/avatar.png',
      );

      final json = model.toJson();

      expect(json['id'], 1);
      expect(json['email'], 'test@example.com');
      expect(json['first_name'], 'Alice');
      expect(json['last_name'], 'Dupont');
      expect(json['weight_in_kg'], 65.5);
      expect(json['height_in_cm'], 170.0);
      expect(json['sport_objective'], 'prise de masse');
      expect(json['avatar_url'], 'https://example.com/avatar.png');
    });

    test('sérialise les champs optionnels à null', () {
      const model = UserModel(
        id: 2,
        email: 'bob@example.com',
        firstName: 'Bob',
        lastName: 'Martin',
      );

      final json = model.toJson();

      expect(json['weight_in_kg'], isNull);
      expect(json['height_in_cm'], isNull);
      expect(json['sport_objective'], isNull);
      expect(json['avatar_url'], isNull);
    });
  });

  group('UserModel.fromEntity', () {
    test('crée un UserModel depuis une entité UserProfile', () {
      const entity = UserProfile(
        id: 5,
        email: 'entity@example.com',
        firstName: 'Entity',
        lastName: 'Test',
        weightKg: 80.0,
        heightCm: 180.0,
      );

      final model = UserModel.fromEntity(entity);

      expect(model.id, 5);
      expect(model.email, 'entity@example.com');
      expect(model.firstName, 'Entity');
      expect(model.weightKg, 80.0);
    });
  });

  group('fromJson -> toJson (aller-retour)', () {
    test('un JSON sérialisé puis désérialisé doit être identique', () {
      final original = {
        'id': 10,
        'email': 'roundtrip@example.com',
        'first_name': 'Round',
        'last_name': 'Trip',
        'weight_in_kg': 72.3,
        'height_in_cm': 175.0,
        'sport_objective': 'endurance',
        'avatar_url': null,
      };

      final json = UserModel.fromJson(original).toJson();

      expect(json['id'], original['id']);
      expect(json['email'], original['email']);
      expect(json['first_name'], original['first_name']);
      expect(json['last_name'], original['last_name']);
      expect(json['weight_in_kg'], original['weight_in_kg']);
      expect(json['height_in_cm'], original['height_in_cm']);
      expect(json['sport_objective'], original['sport_objective']);
      expect(json['avatar_url'], original['avatar_url']);
    });
  });
}
