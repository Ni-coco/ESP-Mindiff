import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mindiff_app/pages/login_page.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
  });

  tearDown(Get.reset);

  testWidgets('affiche les erreurs de validation si formulaire vide', (
    tester,
  ) async {
    await tester.pumpWidget(const GetMaterialApp(home: LoginPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();

    expect(find.text("L'email est requis"), findsOneWidget);
    expect(find.text('Le mot de passe est requis'), findsOneWidget);
  });
}
