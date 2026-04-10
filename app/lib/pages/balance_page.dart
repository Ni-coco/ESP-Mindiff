import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mindiff_app/controllers/user_profile_controller.dart';
import 'package:mindiff_app/services/auth_service.dart';
import 'package:mindiff_app/services/ble_service.dart';
import 'package:mindiff_app/utils/theme.dart';

class BalancePage extends StatefulWidget {
  const BalancePage({super.key});

  @override
  State<BalancePage> createState() => _BalancePageState();
}

class _BalancePageState extends State<BalancePage> {
  late final UserProfileController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<UserProfileController>();
  }

  // ─────────────────────────────────────────────
  void _showRenameDialog(BuildContext context, BleService ble) {
    final controller = TextEditingController(text: ble.deviceName.value);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Renommer la balance'),
        content: TextField(
          controller: controller,
          maxLength: 31,
          decoration: const InputDecoration(
            labelText: 'Nouveau nom',
            hintText: 'ex: MaBalance',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ble.sendDeviceName(name);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Renommer'),
          ),
        ],
      ),
    );
  }

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
        actions: [
          // Bouton renommage — visible seulement si connecté
          Obx(
            () => ble.isConnected.value
                ? IconButton(
                    icon: const Icon(Iconsax.edit),
                    tooltip: 'Renommer la balance',
                    onPressed: () => _showRenameDialog(context, ble),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: Center(
        child: Obx(() {
          // ── Scanning ──────────────────────────
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

          // ── Non connecté ──────────────────────
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
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: ble.connect,
                  icon: const Icon(Iconsax.bluetooth),
                  label: const Text('Connecter la balance'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            );
          }

          // ── Connecté ──────────────────────────
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Statut BLE
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.bluetooth, color: TColors.primary, size: 18),
                  const SizedBox(width: 6),
                  Obx(
                    () => Text(
                      ble.deviceName.value,
                      style: TextStyle(
                        color: TColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),

              // Poids
              Obx(
                () => AnimatedOpacity(
                  opacity: ble.weightStable.value ? 1.0 : 0.4,
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    '${ble.weight.value.toStringAsFixed(3)} kg',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: THelperFunctions.textColor(context),
                      fontSize: 64,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Indicateur stabilité
              Obx(
                () => Text(
                  ble.weightStable.value ? 'Poids stable ✓' : 'En attente...',
                  style: TextStyle(
                    fontSize: 14,
                    color: ble.weightStable.value
                        ? Colors.green
                        : (isDark ? Colors.grey[400] : Colors.grey[600]),
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Boutons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Enregistrer — actif seulement si poids stable
                  Obx(
                    () => ElevatedButton.icon(
                      onPressed: ble.weightStable.value
                          ? () async {
                              try {
                                final userId = _ctrl.userId.value;
                                if (userId != null) {
                                  await Get.find<AuthService>().addWeight(
                                    userId,
                                    ble.weight.value,
                                    source: 'manual',
                                  );
                                }
                              } catch (e) {
                                debugPrint('MANUAL WEIGHT ERROR: $e');
                              }
                            }
                          : null,
                      icon: const Icon(Iconsax.tick_circle),
                      label: const Text('Enregistrer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: ble.disconnect,
                    icon: const Icon(Iconsax.bluetooth_2),
                    label: const Text('Déconnecter'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
