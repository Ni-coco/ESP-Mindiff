import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class BleService extends GetxController {
  static const String serviceUUID = "12345678-1234-1234-1234-123456789abc";
  static const String characteristicUUID = "abcd1234-ab12-cd34-ef56-abcdef123456";

  final isConnected = false.obs;
  final isScanning = false.obs;
  
  // 👉 LES NOUVELLES VARIABLES POUR L'UI
  final weight = 0.0.obs;
  final weightStable = false.obs;
  final deviceName = "Balance-ESP32".obs;

  BluetoothDevice? _device;
  StreamSubscription? _weightSubscription;
  StreamSubscription? _connectionSubscription;
  
  // Pour calculer la stabilité du poids
  Timer? _stabilityTimer;
  double _lastWeight = 0.0;

  Future<void> connect() async {
    final scan = await Permission.bluetoothScan.request();
    final connectPerm = await Permission.bluetoothConnect.request();
    final location = await Permission.location.request();

    if (scan.isDenied || connectPerm.isDenied || location.isDenied) {
      Get.snackbar(
        'Permission refusée',
        'Le Bluetooth et la localisation sont nécessaires',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isScanning.value = true;

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

    await for (final results in FlutterBluePlus.scanResults) {
      for (final r in results) {
        if (r.device.platformName == "Balance-ESP32" || r.device.platformName == deviceName.value) {
          await FlutterBluePlus.stopScan();
          isScanning.value = false;
          _device = r.device;
          // Met à jour le nom affiché
          deviceName.value = r.device.platformName.isNotEmpty ? r.device.platformName : "Balance Connectée";
          await _connectToDevice();
          return;
        }
      }
    }

    isScanning.value = false;
    Get.snackbar(
      'Balance introuvable',
      'Assure-toi que la balance est allumée et à portée',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> _connectToDevice() async {
    if (_device == null) return;

    try {
      // Attention à license: License.free, certains packages l'ont supprimé dans leurs versions récentes. 
      // Si ça souligne en rouge, enlève juste ce paramètre.
      await _device!.connect(license: License.free, mtu: null);

      // Attendre que la connexion soit vraiment établie
      await _device!.connectionState
          .where((s) => s == BluetoothConnectionState.connected)
          .first
          .timeout(const Duration(seconds: 10));

      isConnected.value = true;

      // Écoute les déconnexions
      _connectionSubscription = _device!.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _resetState();
        }
      });

      // Découvre les services
      final services = await _device!.discoverServices();
      for (final service in services) {
        if (service.uuid.toString().toLowerCase() == serviceUUID.toLowerCase()) {
          for (final c in service.characteristics) {
            if (c.uuid.toString().toLowerCase() == characteristicUUID.toLowerCase()) {
              await c.setNotifyValue(true);
              _weightSubscription = c.onValueReceived.listen((value) {
                final str = String.fromCharCodes(value);
                final currentWeight = double.tryParse(str) ?? weight.value;
                
                weight.value = currentWeight;
                _checkStability(currentWeight);
              });
            }
          }
        }
      }
    } catch (e) {
      _resetState();
      Get.snackbar(
        'Erreur de connexion',
        'Impossible de se connecter à la balance : $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // 👉 NOUVELLE FONCTION : Vérifie si le poids est stable
  void _checkStability(double currentWeight) {
    // Si le poids est quasiment à zéro, on n'est pas stable (personne sur la balance)
    if (currentWeight < 0.5) {
      weightStable.value = false;
      _stabilityTimer?.cancel();
      _lastWeight = currentWeight;
      return;
    }

    // Si le poids bouge de plus de 100 grammes, on annule le chrono
    if ((currentWeight - _lastWeight).abs() > 0.1) {
      weightStable.value = false;
      _lastWeight = currentWeight;
      _stabilityTimer?.cancel();
      
      // On relance un chrono de 2 secondes
      _stabilityTimer = Timer(const Duration(seconds: 2), () {
        weightStable.value = true;
      });
    }
  }

  // 👉 NOUVELLE FONCTION : Pour renommer la balance dans l'UI
  void sendDeviceName(String newName) {
    deviceName.value = newName;
    // Plus tard, tu pourras ajouter le code ici pour écrire le nom directement dans la puce ESP32 
    // en utilisant une caractéristique Bluetooth (GATT Write).
  }

  Future<void> disconnect() async {
    await _weightSubscription?.cancel();
    await _connectionSubscription?.cancel();
    _stabilityTimer?.cancel();
    await _device?.disconnect();
    _resetState();
  }

  void _resetState() {
    isConnected.value = false;
    weight.value = 0.0;
    weightStable.value = false;
    _stabilityTimer?.cancel();
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }
}