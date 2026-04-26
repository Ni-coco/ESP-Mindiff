import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mindiff_app/config/app_config.dart';
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
  late final BleService _ble;
  late final UserProfileController _ctrl;

  @override
  void initState() {
    super.initState();
    _ble = Get.put(BleService(), permanent: true);
    _ctrl = Get.find<UserProfileController>();
    if (!_ble.isConnected.value) {
      _ble.startScan();
    }
  }

  // ── Sync modal ────────────────────────────────────────────────────────────

  Future<void> _showSyncModal(BuildContext context) async {
    final ssidController = TextEditingController();
    final passwordController = TextEditingController();
    final isDark = THelperFunctions.isDarkMode(context);
    var isLoading = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Synchroniser la balance',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: THelperFunctions.textColor(context),
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Entrez vos identifiants WiFi pour connecter la balance à Internet.',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),

              TextField(
                controller: ssidController,
                decoration: InputDecoration(
                  labelText: 'Nom du réseau WiFi (SSID)',
                  prefixIcon: const Icon(Iconsax.wifi),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: TColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Mot de passe WiFi',
                  prefixIcon: const Icon(Iconsax.lock),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: TColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final ssid = ssidController.text.trim();
                          if (ssid.isEmpty) return;

                          setModalState(() => isLoading = true);
                          try {
                            final token = await Get.find<AuthService>()
                                .getDeviceToken();
                            final userId = _ctrl.userId.value ?? 0;
                            final apiUrl = AppConfig.apiBaseUrl;

                            final command = jsonEncode({
                              'cmd': 'wifi',
                              'ssid': ssid,
                              'password': passwordController.text,
                              'token': token,
                              'api_url': apiUrl,
                              'user_id': userId,
                            });

                            await _ble.sendCommand(command);
                            _ble.setSynced();

                            if (ctx.mounted) Navigator.pop(ctx);
                            Get.snackbar(
                              'Synchronisation envoyée',
                              'La balance se connecte au WiFi...',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.green[100],
                              colorText: Colors.green[900],
                            );
                          } catch (e) {
                            setModalState(() => isLoading = false);
                            Get.snackbar(
                              'Erreur',
                              'Impossible de synchroniser : $e',
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Synchroniser',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: isDark ? TColors.darkBackground : Colors.white,
      appBar: AppBar(
        title: const Text('Balance'),
        backgroundColor: isDark ? TColors.darkBackground : Colors.white,
        elevation: 0,
        actions: [
          Obx(() => _ble.isConnected.value
              ? IconButton(
                  icon: const Icon(Iconsax.bluetooth_2),
                  tooltip: 'Déconnecter',
                  onPressed: _ble.disconnect,
                )
              : const SizedBox.shrink()),
        ],
      ),
      body: Obx(() {
        if (_ble.isConnected.value) {
          return _buildConnectedView(context, isDark);
        }
        return _buildScanView(context, isDark);
      }),
    );
  }

  // ── Vue scan ──────────────────────────────────────────────────────────────

  Widget _buildScanView(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Appareils à portée',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: THelperFunctions.textColor(context),
                      ),
                ),
              ),
              Obx(() => _ble.isScanning.value
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Iconsax.refresh),
                      onPressed: _ble.startScan,
                      tooltip: 'Relancer le scan',
                    )),
            ],
          ),
        ),

        Obx(() => _ble.isScanning.value
            ? Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  'Recherche en cours...',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              )
            : const SizedBox.shrink()),

        Expanded(
          child: Obx(() {
            if (_ble.scanResults.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Iconsax.bluetooth_2, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      _ble.isScanning.value
                          ? 'Recherche d\'appareils...'
                          : 'Aucun appareil trouvé',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    if (!_ble.isScanning.value) ...[
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _ble.startScan,
                        icon: const Icon(Iconsax.refresh),
                        label: const Text('Relancer'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: TColors.primary,
                          side: BorderSide(color: TColors.primary),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              itemCount: _ble.scanResults.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final result = _ble.scanResults[index];
                final name = result.device.platformName.isNotEmpty
                    ? result.device.platformName
                    : 'Appareil inconnu';

                return Card(
                  elevation: 0,
                  color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: TColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Iconsax.bluetooth,
                          color: TColors.primary, size: 22),
                    ),
                    title: Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: THelperFunctions.textColor(context),
                      ),
                    ),
                    subtitle: Text(
                      'Signal : ${result.rssi} dBm',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _ble.connectToDevice(result.device),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  // ── Vue connectée ─────────────────────────────────────────────────────────

  Widget _buildConnectedView(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 32),

            // Nom appareil
            Obx(() => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Iconsax.bluetooth, color: TColors.primary, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      _ble.deviceName.value,
                      style: TextStyle(
                        color: TColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                )),

            const SizedBox(height: 48),

            // Poids en grand
            Obx(() => AnimatedOpacity(
                  opacity: _ble.weightStable.value ? 1.0 : 0.4,
                  duration: const Duration(milliseconds: 300),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: _ble.weight.value.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 72,
                            fontWeight: FontWeight.bold,
                            color: THelperFunctions.textColor(context),
                          ),
                        ),
                        TextSpan(
                          text: ' kg',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w400,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                )),

            const SizedBox(height: 8),

            // Stabilité
            Obx(() => AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    _ble.weightStable.value
                        ? 'Poids stable ✓'
                        : 'Mesure en cours...',
                    key: ValueKey(_ble.weightStable.value),
                    style: TextStyle(
                      fontSize: 14,
                      color: _ble.weightStable.value
                          ? Colors.green
                          : (isDark ? Colors.grey[400] : Colors.grey[600]),
                    ),
                  ),
                )),

            const SizedBox(height: 56),

            // Boutons selon état sync
            Obx(() => _ble.isSynced.value
                ? _buildSyncedButtons(context, isDark)
                : _buildSyncButton(context)),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncButton(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showSyncModal(context),
            icon: const Icon(Iconsax.wifi),
            label: const Text(
              'Synchroniser',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: TColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Configurez le WiFi pour envoyer les pesées automatiquement',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.grey[500]),
        ),
      ],
    );
  }

  Widget _buildSyncedButtons(BuildContext context, bool isDark) {
    final neutralColor = isDark ? Colors.grey[400]! : Colors.grey[700]!;
    final neutralBorder = isDark ? Colors.grey[700]! : Colors.grey[300]!;

    return Column(
      children: [
        // Tare
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _ble.sendCommand('{"cmd":"tare"}'),
            icon: const Icon(Iconsax.empty_wallet),
            label: const Text('Tare (remettre à zéro)'),
            style: OutlinedButton.styleFrom(
              foregroundColor: TColors.primary,
              side: BorderSide(color: TColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Calibration
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showCalibModal(context),
            icon: const Icon(Iconsax.weight),
            label: const Text('Calibrer la balance'),
            style: OutlinedButton.styleFrom(
              foregroundColor: TColors.primary,
              side: BorderSide(color: TColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Renommer
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showRenameModal(context),
            icon: const Icon(Iconsax.edit),
            label: const Text('Renommer la balance'),
            style: OutlinedButton.styleFrom(
              foregroundColor: neutralColor,
              side: BorderSide(color: neutralBorder),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Redémarrer
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _ble.sendCommand('{"cmd":"restart"}'),
            icon: const Icon(Iconsax.refresh),
            label: const Text('Redémarrer la balance'),
            style: OutlinedButton.styleFrom(
              foregroundColor: neutralColor,
              side: BorderSide(color: neutralBorder),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Reset usine
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showResetConfirm(context),
            icon: const Icon(Iconsax.trash),
            label: const Text('Réinitialiser la balance'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  // ── Calibration modal ─────────────────────────────────────────────────────

  Future<void> _showCalibModal(BuildContext context) async {
    final controller = TextEditingController();
    final isDark = THelperFunctions.isDarkMode(context);
    var isLoading = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Text('Calibrer la balance',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: THelperFunctions.textColor(context),
                )),
              const SizedBox(height: 8),
              Text(
                'Placez un objet de poids connu sur la balance, puis entrez son poids exact.',
                style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Poids de référence (kg)',
                  prefixIcon: const Icon(Iconsax.weight),
                  suffixText: 'kg',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: TColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : () async {
                    final val = double.tryParse(controller.text.replaceAll(',', '.'));
                    if (val == null || val <= 0) return;
                    setModalState(() => isLoading = true);
                    try {
                      await _ble.sendCommand(jsonEncode({'cmd': 'calib', 'weight': val}));
                      if (ctx.mounted) Navigator.pop(ctx);
                      Get.snackbar('Calibration lancée', 'Résultat affiché sur la balance.',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.blue[100],
                        colorText: Colors.blue[900],
                      );
                    } catch (e) {
                      setModalState(() => isLoading = false);
                      Get.snackbar('Erreur', 'Impossible de calibrer : $e',
                        snackPosition: SnackPosition.BOTTOM);
                    }
                  },
                  icon: isLoading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Iconsax.weight),
                  label: const Text('Calibrer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Rename modal ──────────────────────────────────────────────────────────

  Future<void> _showRenameModal(BuildContext context) async {
    final controller = TextEditingController(text: _ble.deviceName.value);
    final isDark = THelperFunctions.isDarkMode(context);
    var isLoading = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Text('Renommer la balance',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: THelperFunctions.textColor(context),
                )),
              const SizedBox(height: 8),
              Text('Le nouveau nom sera pris en compte au prochain redémarrage.',
                style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[400] : Colors.grey[600])),
              const SizedBox(height: 24),
              TextField(
                controller: controller,
                autofocus: true,
                maxLength: 20,
                decoration: InputDecoration(
                  labelText: 'Nom de la balance',
                  prefixIcon: const Icon(Iconsax.edit),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: TColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : () async {
                    final name = controller.text.trim();
                    if (name.isEmpty) return;
                    setModalState(() => isLoading = true);
                    try {
                      await _ble.sendCommand(jsonEncode({'cmd': 'rename', 'name': name}));
                      _ble.deviceName.value = name;
                      if (ctx.mounted) Navigator.pop(ctx);
                      Get.snackbar('Renommée', 'Balance renommée en "$name".',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.green[100],
                        colorText: Colors.green[900],
                      );
                    } catch (e) {
                      setModalState(() => isLoading = false);
                      Get.snackbar('Erreur', 'Impossible de renommer : $e',
                        snackPosition: SnackPosition.BOTTOM);
                    }
                  },
                  icon: isLoading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Iconsax.edit),
                  label: const Text('Renommer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Reset confirmation ────────────────────────────────────────────────────

  Future<void> _showResetConfirm(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Réinitialiser la balance ?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'Cela effacera tous les paramètres enregistrés (WiFi, token, calibration) et redémarrera la balance.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _ble.sendCommand('{"cmd":"reset"}');
      } catch (_) {}
    }
  }
}
