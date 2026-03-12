import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mindiff_app/services/ble_service.dart';
import 'package:mindiff_app/utils/theme.dart';

class BalancePage extends StatelessWidget {
  const BalancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ble = Get.put(BleService());
    final isDark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: isDark ? TColors.darkBackground : Colors.white,
      appBar: AppBar(
        title: const Text('Balance'),
        backgroundColor: isDark ? TColors.darkBackground : Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Obx(() {
          if (ble.isScanning.value) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text(
                  'Recherche de la balance...',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            );
          }

          if (!ble.isConnected.value) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.weight, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 24),
                Text(
                  'Balance non connectée',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: THelperFunctions.textColor(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Assure-toi que la balance est allumée',
                  style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: ble.connect,
                  icon: const Icon(Iconsax.bluetooth),
                  label: const Text('Connecter la balance'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            );
          }

          // Connecté → affiche le poids
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Iconsax.bluetooth, color: TColors.primary, size: 24),
              const SizedBox(height: 8),
              Text(
                'Balance connectée',
                style: TextStyle(color: TColors.primary, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 48),
              Text(
                '${ble.weight.value.toStringAsFixed(3)} kg',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: THelperFunctions.textColor(context),
                  fontSize: 64,
                ),
              ),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: sauvegarder le poids dans UserProfileController
                    },
                    icon: const Icon(Iconsax.tick_circle),
                    label: const Text('Enregistrer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: ble.disconnect,
                    icon: const Icon(Iconsax.bluetooth_2),
                    label: const Text('Déconnecter'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }
}