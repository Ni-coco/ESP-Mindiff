import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConsentService extends GetxService {
  static const String _cguKey = 'user_consent_cgu';
  static const String _healthDataKey = 'user_consent_health_data';

  final RxBool hasConsentedCGU = false.obs;
  final RxBool hasConsentedHealthData = false.obs;

  Future<ConsentService> init() async {
    final prefs = await SharedPreferences.getInstance();
    hasConsentedCGU.value = prefs.getBool(_cguKey) ?? false;
    hasConsentedHealthData.value = prefs.getBool(_healthDataKey) ?? false;
    return this;
  }

  Future<void> updateCGUConsent(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_cguKey, value);
    hasConsentedCGU.value = value;
  }

  Future<void> updateHealthDataConsent(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_healthDataKey, value);
    hasConsentedHealthData.value = value;
  }
}