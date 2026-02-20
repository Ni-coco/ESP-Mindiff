import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class BleService extends GetxController {
  static const String serviceUUID = "12345678-1234-1234-1234-123456789abc";
  static const String characteristicUUID = "abcd1234-ab12-cd34-ef56-abcdef123456";

  final isConnected = false.obs;
  final isScanning = false.obs;
  final weight = 0.0.obs;

  BluetoothDevice? _device;
  StreamSubscription? _weightSubscription;
  StreamSubscription? _connectionSubscription;

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
        if (r.device.platformName == "Balance-ESP32") {
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

      // Attendre que la connexion soit vraiment établie
      await _device!.connectionState
          .where((s) => s == BluetoothConnectionState.connected)
          .first
          .timeout(const Duration(seconds: 10));

      isConnected.value = true;

      // Écoute les déconnexions
      _connectionSubscription = _device!.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          isConnected.value = false;
          weight.value = 0.0;
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
                weight.value = double.tryParse(str) ?? weight.value;
              });
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

  Future<void> disconnect() async {
    await _weightSubscription?.cancel();
    await _connectionSubscription?.cancel();
    await _device?.disconnect();
    isConnected.value = false;
    weight.value = 0.0;
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }
}