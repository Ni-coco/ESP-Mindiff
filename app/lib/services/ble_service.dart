import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class BleService extends GetxController {
  // ─────────────────────────────────────────────
  //  UUIDs — doivent correspondre à l'ESP32
  // ─────────────────────────────────────────────
  static const String serviceUUID        = "12345678-1234-1234-1234-123456789abc";
  static const String characteristicUUID = "abcd1234-ab12-cd34-ef56-abcdef123456";
  static const String writeUUID          = "abcd1234-ab12-cd34-ef56-abcdef123457"; // WRITE

  // ─────────────────────────────────────────────
  //  State observable
  // ─────────────────────────────────────────────
  final isConnected  = false.obs;
  final isScanning   = false.obs;
  final weight       = 0.0.obs;
  final weightStable = false.obs;   // true quand poids stable reçu
  final deviceName   = 'Balance-ESP32'.obs;

  BluetoothDevice?       _device;
  BluetoothCharacteristic? _writeCharacteristic;
  StreamSubscription?    _weightSubscription;
  StreamSubscription?    _connectionSubscription;

  // ─────────────────────────────────────────────
  //  Connexion
  // ─────────────────────────────────────────────
  Future<void> connect() async {
    final scan        = await Permission.bluetoothScan.request();
    final connectPerm = await Permission.bluetoothConnect.request();
    final location    = await Permission.location.request();

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
        if (r.device.platformName == deviceName.value) {
          await FlutterBluePlus.stopScan();
          isScanning.value = false;
          _device = r.device;
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
      await _device!.connect(license: License.free, mtu: null);

      await _device!.connectionState
          .where((s) => s == BluetoothConnectionState.connected)
          .first
          .timeout(const Duration(seconds: 10));

      isConnected.value = true;

      // Écoute déconnexions
      _connectionSubscription = _device!.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          isConnected.value  = false;
          weightStable.value = false;
          weight.value       = 0.0;
        }
      });

      // Découvre les services
      final services = await _device!.discoverServices();
      for (final service in services) {
        if (service.uuid.toString().toLowerCase() == serviceUUID.toLowerCase()) {
          for (final c in service.characteristics) {

            // Caracteristique NOTIFY — réception du poids stable
            if (c.uuid.toString().toLowerCase() == characteristicUUID.toLowerCase()) {
              await c.setNotifyValue(true);
              _weightSubscription = c.onValueReceived.listen((value) {
                final str = String.fromCharCodes(value);
                final parsed = double.tryParse(str);
                if (parsed != null) {
                  weight.value       = parsed;
                  weightStable.value = true;
                }
              });
            }

            // Caracteristique WRITE — envoi de commandes vers l'ESP32
            if (c.uuid.toString().toLowerCase() == writeUUID.toLowerCase()) {
              _writeCharacteristic = c;
            }
          }
        }
      }
    } catch (e) {
      isConnected.value = false;
      Get.snackbar(
        'Erreur de connexion',
        'Impossible de se connecter à la balance : $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ─────────────────────────────────────────────
  //  Commandes vers l'ESP32
  // ─────────────────────────────────────────────

  Future<void> sendDeviceName(String name) async {
    if (_writeCharacteristic == null) return;
    final cmd = 'n $name';
    await _writeCharacteristic!.write(utf8.encode(cmd), withoutResponse: false);
    deviceName.value = name;
    Get.snackbar('Nom mis à jour', 'La balance s\'appelle maintenant "$name"',
        snackPosition: SnackPosition.BOTTOM);
  }

  Future<void> sendTare() async {
    if (_writeCharacteristic == null) return;
    await _writeCharacteristic!.write(utf8.encode('t'), withoutResponse: false);
  }

  Future<void> sendSleepTimeout(int seconds) async {
    if (_writeCharacteristic == null) return;
    await _writeCharacteristic!.write(utf8.encode('s $seconds'), withoutResponse: false);
  }

  // ─────────────────────────────────────────────
  //  Déconnexion
  // ─────────────────────────────────────────────
  Future<void> disconnect() async {
    await _weightSubscription?.cancel();
    await _connectionSubscription?.cancel();
    await _device?.disconnect();
    isConnected.value  = false;
    weightStable.value = false;
    weight.value       = 0.0;
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }
}