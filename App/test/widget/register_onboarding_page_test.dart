import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mindiff_app/pages/register_onboarding_page.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
  });

  tearDown(Get.reset);

  testWidgets('affiche la première étape de création de compte', (tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: RegisterOnboardingPage()));
    await tester.pumpAndSettle();

    expect(find.text('Informations du compte'), findsOneWidget);
    expect(find.text('Créez votre compte pour commencer'), findsOneWidget);
  });
}
