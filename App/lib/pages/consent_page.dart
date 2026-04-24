import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mindiff_app/services/consent_service.dart';
import 'package:mindiff_app/utils/theme.dart';

class ConsentPage extends StatelessWidget {
  const ConsentPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ConsentService consentService = Get.find<ConsentService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confidentialité & RGPD'),
      ),
      backgroundColor: THelperFunctions.backgroundColor(context),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Gestion de vos données",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Conformément au RGPD, vous avez le contrôle total sur vos données.",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            
            // Switch pour les CGU
            Obx(() => SwitchListTile(
              title: const Text("Conditions Générales d'Utilisation"),
              subtitle: const Text("Nécessaire pour le fonctionnement de base de l'application."),
              value: consentService.hasConsentedCGU.value,
              activeColor: TColors.primary,
              onChanged: (bool value) {
                if (!value) {
                  Get.defaultDialog(
                    title: "Attention",
                    middleText: "Refuser les CGU limitera grandement l'accès à l'application. Êtes-vous sûr ?",
                    textConfirm: "Oui, refuser",
                    textCancel: "Annuler",
                    confirmTextColor: Colors.white,
                    onConfirm: () {
                      consentService.updateCGUConsent(value);
                      Get.back();
                    },
                  );
                } else {
                  consentService.updateCGUConsent(value);
                }
              },
            )),

            const Divider(),

            // Switch pour les données de santé
            Obx(() => SwitchListTile(
              title: const Text("Traitement des données de santé"),
              subtitle: const Text("Autorise l'utilisation de votre poids, âge et blessures pour l'IA."),
              value: consentService.hasConsentedHealthData.value,
              activeColor: TColors.primary,
              onChanged: (bool value) {
                consentService.updateHealthDataConsent(value);
                if (!value) {
                   Get.snackbar(
                    "Données de santé", 
                    "Vos programmes et conseils nutritionnels ne seront plus personnalisés.",
                    snackPosition: SnackPosition.BOTTOM,
                  );
                }
              },
            )),
          ],
        ),
      ),
    );
  }
}