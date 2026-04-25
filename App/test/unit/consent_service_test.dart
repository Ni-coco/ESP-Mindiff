import 'package:flutter_test/flutter_test.dart';
import 'package:mindiff_app/services/consent_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ConsentService', () {
    test('init charge les valeurs depuis le storage', () async {
      SharedPreferences.setMockInitialValues({
        'user_consent_cgu': true,
        'user_consent_health_data': false,
      });

      final service = await ConsentService().init();

      expect(service.hasConsentedCGU.value, isTrue);
      expect(service.hasConsentedHealthData.value, isFalse);
    });

    test('updateCGUConsent persiste et met à jour le state', () async {
      final service = await ConsentService().init();
      await service.updateCGUConsent(true);

      final prefs = await SharedPreferences.getInstance();
      expect(service.hasConsentedCGU.value, isTrue);
      expect(prefs.getBool('user_consent_cgu'), isTrue);
    });

    test('updateHealthDataConsent persiste et met à jour le state', () async {
      final service = await ConsentService().init();
      await service.updateHealthDataConsent(true);

      final prefs = await SharedPreferences.getInstance();
      expect(service.hasConsentedHealthData.value, isTrue);
      expect(prefs.getBool('user_consent_health_data'), isTrue);
    });
  });
}
