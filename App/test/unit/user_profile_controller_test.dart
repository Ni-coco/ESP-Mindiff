import 'package:flutter_test/flutter_test.dart';
import 'package:mindiff_app/controllers/user_profile_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('UserProfileController', () {
    test('setFromRegistration split le nom et remplit les champs', () {
      final controller = UserProfileController();

      controller.setFromRegistration(
        name: 'Nicolas Garde',
        email: 'nico@example.com',
        weight: 80,
        height: 180,
        sportObjective: 'build_muscle',
        targetWeight: 85,
        sessionsPerWeek: 4,
        age: 26,
        gender: 'male',
      );

      expect(controller.profile.value, isNotNull);
      expect(controller.profile.value!.firstName, 'Nicolas');
      expect(controller.profile.value!.lastName, 'Garde');
      expect(controller.primaryGoal.value, 'build_muscle');
      expect(controller.targetWeight.value, 85);
      expect(controller.sessionsPerWeek.value, 4);
      expect(controller.age.value, 26);
      expect(controller.gender.value, 'male');
    });

    test('setFromApiResponse mappe correctement les données backend', () {
      final controller = UserProfileController();

      controller.setFromApiResponse({
        'id': 7,
        'email': 'api@example.com',
        'username': 'api_user',
        'gender': 'female',
        'sport_objective': 'lose_weight',
        'target_weight': 62.5,
        'sessions_per_week': 3,
        'user_metrics': [
          {
            'weight': 68,
            'height': 170,
            'age': 30,
            'actual_weight': 67.2,
          },
        ],
      });

      expect(controller.userId.value, 7);
      expect(controller.profile.value!.email, 'api@example.com');
      expect(controller.primaryGoal.value, 'lose_weight');
      expect(controller.targetWeight.value, 62.5);
      expect(controller.sessionsPerWeek.value, 3);
      expect(controller.age.value, 30);
      expect(controller.actualWeight.value, 67.2);
      expect(controller.profile.value!.weightKg, 68);
      expect(controller.profile.value!.heightCm, 170);
    });

    test('clear réinitialise le state en mémoire', () async {
      final controller = UserProfileController();
      controller.setFromRegistration(
        name: 'Test User',
        email: 'test@example.com',
      );

      await controller.clear();

      expect(controller.profile.value, isNull);
      expect(controller.primaryGoal.value, isNull);
      expect(controller.targetWeight.value, isNull);
      expect(controller.sessionsPerWeek.value, isNull);
      expect(controller.age.value, isNull);
      expect(controller.gender.value, isNull);
      expect(controller.userId.value, isNull);
      expect(controller.actualWeight.value, isNull);
    });
  });
}
