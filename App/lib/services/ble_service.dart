import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class BleService extends GetxController {
  static const String serviceUUID    = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String charNotifyUUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8"; // ESP32 → app
  static const String charWriteUUID  = "6d68efe5-04b6-4a85-abc4-c2670b7bf7fd"; // app → ESP32

  final isConnected = false.obs;
  final isScanning = false.obs;
  final isSynced = false.obs;
  final weight = 0.0.obs;
  final weightStable = false.obs;
  final deviceName = "Balance-ESP32".obs;
  final scanResults = <ScanResult>[].obs;

  BluetoothDevice? _device;
  BluetoothCharacteristic? _writeChar;
  BluetoothCharacteristic? _notifyChar;
  StreamSubscription? _weightSubscription;
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _scanSubscription;

  Timer? _stabilityTimer;
  double _lastWeight = 0.0;

  Future<bool> _requestPermissions() async {
    final scan = await Permission.bluetoothScan.request();
    final connectPerm = await Permission.bluetoothConnect.request();
    final location = await Permission.location.request();

    if (scan.isDenied || connectPerm.isDenied || location.isDenied) {
      Get.snackbar(
        'Permission refusée',
        'Le Bluetooth et la localisation sont nécessaires',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
    return true;
  }

  Future<void> startScan() async {
    if (isScanning.value) return;
    if (!await _requestPermissions()) return;

    scanResults.clear();
    isScanning.value = true;

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        if (r.device.platformName.isNotEmpty) {
          final idx = scanResults.indexWhere(
            (s) => s.device.remoteId == r.device.remoteId,
          );
          if (idx >= 0) {
            scanResults[idx] = r;
          } else {
            scanResults.add(r);
          }
        }
      }
    });

    await Future.delayed(const Duration(seconds: 10));
    await _stopScan();
  }

  Future<void> _stopScan() async {
    await FlutterBluePlus.stopScan();
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    isScanning.value = false;
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    await _stopScan();
    _device = device;
    deviceName.value = device.platformName.isNotEmpty
        ? device.platformName
        : "Balance";
    await _connectToDevice();
  }

  Future<void> _connectToDevice() async {
    if (_device == null) return;

    try {
      await _device!.connect(license: License.free, mtu: null);

      await _device!.connectionState
          .where((s) => s == BluetoothConnectionState.connected)
          .first
          .timeout(const Duration(seconds: 10));

      await _device!.requestMtu(512);
      isConnected.value = true;

      _connectionSubscription = _device!.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _resetState();
        }
      });

      final services = await _device!.discoverServices();
      for (final service in services) {
        if (service.uuid.toString().toLowerCase() == serviceUUID.toLowerCase()) {
          for (final c in service.characteristics) {
            final uuid = c.uuid.toString().toLowerCase();
            if (uuid == charNotifyUUID.toLowerCase()) {
              _notifyChar = c;
              await c.setNotifyValue(true);
              _weightSubscription = FlutterBluePlus.events.onCharacteristicReceived.listen((event) {
                if (event.device.remoteId != _device!.remoteId) return;
                if (event.characteristic.characteristicUuid.toString().toLowerCase() != charNotifyUUID.toLowerCase()) return;
                if (event.value.isEmpty) return;
                final str = String.fromCharCodes(event.value);
                try {
                  final json = jsonDecode(str) as Map<String, dynamic>;
                  if (json['type'] == 'status') {
                    isSynced.value = json['synced'] == true;
                    return;
                  }
                  final w = (json['weight'] as num).toDouble();
                  weight.value = w;
                  _checkStability(w);
                } catch (_) {
                  final w = double.tryParse(str) ?? weight.value;
                  weight.value = w;
                  _checkStability(w);
                }
              });
            } else if (uuid == charWriteUUID.toLowerCase()) {
              _writeChar = c;
            }
          }
        }
      }

      // Demande le statut dès que la discovery est faite
      if (_writeChar != null) {
        await _writeChar!.write('{"cmd":"status"}'.codeUnits, withoutResponse: false);
      }
    } catch (e) {
      _resetState();
      Get.snackbar(
        'Erreur de connexion',
        'Impossible de se connecter : $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> sendCommand(String json) async {
    if (_writeChar == null || !isConnected.value) {
      throw Exception('Balance non connectée ou service BLE introuvable');
    }
    await _writeChar!.write(json.codeUnits, withoutResponse: false);
  }

  void setSynced() {
    isSynced.value = true;
  }

  void _checkStability(double currentWeight) {
    if (currentWeight < 0.5) {
      weightStable.value = false;
      _stabilityTimer?.cancel();
      _lastWeight = currentWeight;
      return;
    }

    if ((currentWeight - _lastWeight).abs() > 0.1) {
      weightStable.value = false;
      _lastWeight = currentWeight;
      _stabilityTimer?.cancel();
      _stabilityTimer = Timer(const Duration(seconds: 2), () {
        weightStable.value = true;
      });
    }
  }

  void sendDeviceName(String newName) {
    deviceName.value = newName;
  }

  Future<void> disconnect() async {
    await _weightSubscription?.cancel();
    await _connectionSubscription?.cancel();
    await _stopScan();
    _stabilityTimer?.cancel();
    await _device?.disconnect();
    _resetState(clearSynced: true);
  }

  void _resetState({bool clearSynced = false}) {
    isConnected.value = false;
    if (clearSynced) isSynced.value = false;
    weight.value = 0.0;
    weightStable.value = false;
    _writeChar = null;
    _notifyChar = null;
    _stabilityTimer?.cancel();
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }
}
