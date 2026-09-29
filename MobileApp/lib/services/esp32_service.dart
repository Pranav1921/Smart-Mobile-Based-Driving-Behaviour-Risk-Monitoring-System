import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

enum Esp32ConnectionType { none, ble, wifi }

class Esp32DeviceStatus {
  final bool isConnected;
  final bool isBle;
  final String deviceId;
  final String firmwareVersion;
  final bool sensorConnected;
  final int uptime;
  final int freeHeap;
  final double ax;
  final double ay;
  final double az;
  final double gx;
  final double gy;
  final double gz;
  final double temperature;
  final double gMagnitude;
  final bool impactDetected;
  final int harshBrakeCount;
  final int rapidAccelCount;
  final int sharpTurnCount;

  Esp32DeviceStatus({
    required this.isConnected,
    this.isBle = false,
    this.deviceId = 'Unknown',
    this.firmwareVersion = '0.0.0',
    this.sensorConnected = false,
    this.uptime = 0,
    this.freeHeap = 0,
    this.ax = 0.0,
    this.ay = 0.0,
    this.az = 9.81,
    this.gx = 0.0,
    this.gy = 0.0,
    this.gz = 0.0,
    this.temperature = 25.0,
    this.gMagnitude = 1.0,
    this.impactDetected = false,
    this.harshBrakeCount = 0,
    this.rapidAccelCount = 0,
    this.sharpTurnCount = 0,
  });

  factory Esp32DeviceStatus.disconnected() => Esp32DeviceStatus(isConnected: false);

  factory Esp32DeviceStatus.fromBleJson(Map<String, dynamic> json, {String deviceId = 'FG-ESP32-BLE'}) {
    return Esp32DeviceStatus(
      isConnected: true,
      isBle: true,
      deviceId: deviceId,
      firmwareVersion: '3.0.0-BLE',
      sensorConnected: (json['sc'] == 1 || json['sc'] == true || json['sensorConnected'] == true),
      ax: (json['ax'] as num?)?.toDouble() ?? 0.0,
      ay: (json['ay'] as num?)?.toDouble() ?? 0.0,
      az: (json['az'] as num?)?.toDouble() ?? 9.81,
      gx: (json['gx'] as num?)?.toDouble() ?? 0.0,
      gy: (json['gy'] as num?)?.toDouble() ?? 0.0,
      gz: (json['gz'] as num?)?.toDouble() ?? 0.0,
      temperature: (json['temp'] as num?)?.toDouble() ?? (json['temperature'] as num?)?.toDouble() ?? 25.0,
      gMagnitude: (json['gMag'] as num?)?.toDouble() ?? (json['gMagnitude'] as num?)?.toDouble() ?? 1.0,
      impactDetected: (json['imp'] == 1 || json['imp'] == true || json['impactDetected'] == true),
      harshBrakeCount: (json['hb'] as num?)?.toInt() ?? (json['harshBrakeCount'] as num?)?.toInt() ?? 0,
      rapidAccelCount: (json['ra'] as num?)?.toInt() ?? (json['rapidAccelCount'] as num?)?.toInt() ?? 0,
      sharpTurnCount: (json['st'] as num?)?.toInt() ?? (json['sharpTurnCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class Esp32Service {
  // BLE UUID Constants
  static const String bleServiceUuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String bleTelemetryCharUuid = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  static const String bleCommandCharUuid = "beb5483e-36e1-4688-b7f5-ea07361b26a9";

  // Wi-Fi Defaults
  static const String defaultNodeIp = '192.168.4.1';
  static final HttpClient _client = HttpClient()..connectionTimeout = const Duration(milliseconds: 1200);

  // Active BLE Session References
  static BluetoothDevice? _connectedBleDevice;
  static StreamSubscription<List<int>>? _telemetrySub;
  static StreamSubscription<BluetoothConnectionState>? _connectionStateSub;
  static BluetoothCharacteristic? _commandChar;

  static BluetoothDevice? get connectedBleDevice => _connectedBleDevice;

  // -------------------------------------------------------------
  // BLUETOOTH LOW ENERGY (BLE) METHODS
  // -------------------------------------------------------------

  /// Start scanning for nearby SmartDrive BLE nodes
  static Future<void> startBleScan({Duration timeout = const Duration(seconds: 10)}) async {
    try {
      FlutterBluePlus.setLogLevel(LogLevel.none, color: false);
      if (await FlutterBluePlus.isSupported == false) {
        print('[ESP32-BLE] ⚠️ Bluetooth is not supported on this device.');
        return;
      }

      // Request required runtime permissions for BLE scanning (Android 12+ & older)
      try {
        await [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.location,
        ].request();
      } catch (_) {}

      // Prompt to turn on Bluetooth if disabled
      if (FlutterBluePlus.adapterStateNow != BluetoothAdapterState.on) {
        try {
          await FlutterBluePlus.turnOn();
        } catch (_) {}
      }

      // Stop any prior scan
      await FlutterBluePlus.stopScan();

      // Scan for all devices without rigid service filter (much more reliable on Android)
      await FlutterBluePlus.startScan(
        timeout: timeout,
        androidUsesFineLocation: true,
      );
    } catch (e) {
      print('[ESP32-BLE] ⚠️ Scan error: $e');
    }
  }

  /// Stop active BLE scan
  static Future<void> stopBleScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
  }

  /// Scan Results Stream
  static Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  /// Get already connected, bonded, and system devices
  static Future<List<BluetoothDevice>> getSystemAndConnectedDevices() async {
    final List<BluetoothDevice> list = [];
    try {
      list.addAll(FlutterBluePlus.connectedDevices);
    } catch (_) {}
    try {
      final sys = await FlutterBluePlus.systemDevices([]);
      for (final d in sys) {
        if (!list.any((item) => item.remoteId == d.remoteId)) {
          list.add(d);
        }
      }
    } catch (_) {}
    try {
      final bonded = await FlutterBluePlus.bondedDevices;
      for (final d in bonded) {
        if (!list.any((item) => item.remoteId == d.remoteId)) {
          list.add(d);
        }
      }
    } catch (_) {}
    return list;
  }

  static bool _matchesUuid(String u1, String u2) {
    return u1.toLowerCase().replaceAll('-', '') == u2.toLowerCase().replaceAll('-', '');
  }

  /// Connect to ESP32 BLE Node and listen for telemetry notifications
  static Future<bool> connectBle({
    required BluetoothDevice device,
    required Function(Esp32DeviceStatus status) onTelemetry,
    required Function() onDisconnected,
  }) async {
    try {
      FlutterBluePlus.setLogLevel(LogLevel.none, color: false);
      await stopBleScan();
      print('[ESP32-BLE] 🔗 Connecting to ${device.remoteId} (${device.platformName})...');
      await device.connect(timeout: const Duration(seconds: 12), autoConnect: false);
      _connectedBleDevice = device;

      // Monitor connection state
      await _connectionStateSub?.cancel();
      _connectionStateSub = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          print('[ESP32-BLE] 🔌 Disconnected from ${device.platformName}');
          _connectedBleDevice = null;
          _telemetrySub?.cancel();
          _telemetrySub = null;
          _commandChar = null;
          onDisconnected();
        }
      });

      // Request MTU 256 for full JSON telemetry
      try {
        await device.requestMtu(256);
      } catch (_) {}

      // Discover GATT Services
      final services = await device.discoverServices();
      BluetoothCharacteristic? telemetryChar;

      for (final service in services) {
        if (_matchesUuid(service.uuid.toString(), bleServiceUuid)) {
          for (final char in service.characteristics) {
            if (_matchesUuid(char.uuid.toString(), bleTelemetryCharUuid)) {
              telemetryChar = char;
            } else if (_matchesUuid(char.uuid.toString(), bleCommandCharUuid)) {
              _commandChar = char;
            }
          }
        }
      }

      // Fallback: search across all characteristics regardless of service UUID
      if (telemetryChar == null) {
        for (final service in services) {
          for (final char in service.characteristics) {
            if (_matchesUuid(char.uuid.toString(), bleTelemetryCharUuid)) {
              telemetryChar = char;
              break;
            }
          }
        }
      }

      if (telemetryChar != null) {
        print('[ESP32-BLE] ✅ Telemetry Characteristic Found! Subscribing to notifications...');
        await telemetryChar.setNotifyValue(true);

        _telemetrySub?.cancel();
        String bleBuffer = "";
        _telemetrySub = telemetryChar.onValueReceived.listen((data) {
          if (data.isNotEmpty) {
            try {
              final chunk = utf8.decode(data, allowMalformed: true);
              bleBuffer += chunk;

              // Parse any complete JSON objects within the accumulator buffer
              while (bleBuffer.contains('{') && bleBuffer.contains('}')) {
                final start = bleBuffer.indexOf('{');
                final end = bleBuffer.indexOf('}', start);
                if (end != -1 && end > start) {
                  final jsonStr = bleBuffer.substring(start, end + 1);
                  bleBuffer = bleBuffer.substring(end + 1);
                  try {
                    final decoded = jsonDecode(jsonStr);
                    if (decoded is Map<String, dynamic>) {
                      final status = Esp32DeviceStatus.fromBleJson(decoded, deviceId: device.platformName);
                      onTelemetry(status);
                    }
                  } catch (_) {}
                } else {
                  break;
                }
              }
              if (bleBuffer.length > 512) {
                bleBuffer = "";
              }
            } catch (e) {
              print('[ESP32-BLE] ⚠️ Buffer processing error: $e');
            }
          }
        });

        // Also trigger an initial read if available
        try {
          final initVal = await telemetryChar.read();
          if (initVal.isNotEmpty) {
            final decoded = jsonDecode(utf8.decode(initVal));
            if (decoded is Map<String, dynamic>) {
              onTelemetry(Esp32DeviceStatus.fromBleJson(decoded, deviceId: device.platformName));
            }
          }
        } catch (_) {}

        return true;
      } else {
        print('[ESP32-BLE] ❌ Telemetry characteristic not found on device.');
        return false;
      }
    } catch (e) {
      print('[ESP32-BLE] ❌ Connection error: $e');
      try {
        await device.disconnect();
      } catch (_) {}
      _connectedBleDevice = null;
      return false;
    }
  }

  /// Disconnect active BLE connection
  static Future<void> disconnectBle() async {
    try {
      await _telemetrySub?.cancel();
      _telemetrySub = null;
      _commandChar = null;
      await _connectionStateSub?.cancel();
      _connectionStateSub = null;
      if (_connectedBleDevice != null) {
        final dev = _connectedBleDevice;
        _connectedBleDevice = null;
        await dev!.disconnect(timeout: 2);
      }
    } catch (e) {
      print('[ESP32-BLE] Disconnect error: $e');
    }
  }

  /// Toggle ESP32 Built-in Diagnostics LED over BLE
  static Future<bool> toggleLedBle() async {
    try {
      if (_commandChar != null) {
        await _commandChar!.write(utf8.encode("LED_TOGGLE"), withoutResponse: false);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // -------------------------------------------------------------
  // WI-FI REST API METHODS (Fallback Mode)
  // -------------------------------------------------------------

  static Future<Esp32DeviceStatus> probeNode({String ip = defaultNodeIp}) async {
    try {
      final telemetryUri = Uri.parse('http://$ip/api/v1/telemetry/latest');
      final req = await _client.getUrl(telemetryUri).timeout(const Duration(milliseconds: 1200));
      final res = await req.close().timeout(const Duration(milliseconds: 1200));

      if (res.statusCode == 200) {
        final tStr = await res.transform(utf8.decoder).join();
        final teleJson = jsonDecode(tStr);

        return Esp32DeviceStatus(
          isConnected: true,
          isBle: false,
          deviceId: teleJson['deviceId'] ?? 'FG-ESP32-001',
          firmwareVersion: teleJson['firmwareVersion'] ?? '3.0.0',
          sensorConnected: teleJson['sensorConnected'] ?? true,
          uptime: (teleJson['uptime'] as num?)?.toInt() ?? 0,
          freeHeap: (teleJson['freeHeap'] as num?)?.toInt() ?? 0,
          ax: (teleJson['ax'] as num?)?.toDouble() ?? 0.0,
          ay: (teleJson['ay'] as num?)?.toDouble() ?? 0.0,
          az: (teleJson['az'] as num?)?.toDouble() ?? 9.81,
          gx: (teleJson['gx'] as num?)?.toDouble() ?? 0.0,
          gy: (teleJson['gy'] as num?)?.toDouble() ?? 0.0,
          gz: (teleJson['gz'] as num?)?.toDouble() ?? 0.0,
          temperature: (teleJson['temperature'] as num?)?.toDouble() ?? 25.0,
          gMagnitude: (teleJson['gMagnitude'] as num?)?.toDouble() ?? 1.0,
          impactDetected: teleJson['impactDetected'] ?? false,
          harshBrakeCount: (teleJson['harshBrakeCount'] as num?)?.toInt() ?? 0,
          rapidAccelCount: (teleJson['rapidAccelCount'] as num?)?.toInt() ?? 0,
          sharpTurnCount: (teleJson['sharpTurnCount'] as num?)?.toInt() ?? 0,
        );
      }
    } catch (_) {}

    return Esp32DeviceStatus.disconnected();
  }

  static Future<String?> autoDiscoverEsp32({String? initialIp}) async {
    // 1. Try initial IP
    if (initialIp != null && initialIp.isNotEmpty) {
      final status = await probeNode(ip: initialIp);
      if (status.isConnected) return initialIp;
    }

    // 2. Try default AP IP
    final apStatus = await probeNode(ip: defaultNodeIp);
    if (apStatus.isConnected) return defaultNodeIp;

    // 3. Scan local subnets in parallel batches
    try {
      final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
      final subnets = <String>{};

      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          final ip = addr.address;
          if (ip != '127.0.0.1' && !ip.startsWith('169.254')) {
            final parts = ip.split('.');
            if (parts.length == 4) {
              subnets.add("${parts[0]}.${parts[1]}.${parts[2]}");
            }
          }
        }
      }

      if (subnets.isEmpty) {
        subnets.addAll(['192.168.31', '192.168.163', '172.16.23', '172.26.64', '192.168.1', '192.168.0', '192.168.43']);
      }

      for (final subnet in subnets) {
        final targets = <String>[];
        for (final i in [50, 51, 100, 101, 102, 105, 120, 144, 150, 161, 200, 2, 3, 4, 5, 6, 7, 8, 9, 10]) {
          targets.add("$subnet.$i");
        }
        for (int i = 11; i <= 254; i++) {
          final target = "$subnet.$i";
          if (!targets.contains(target)) targets.add(target);
        }

        const batchSize = 30;
        for (int i = 0; i < targets.length; i += batchSize) {
          final batch = targets.sublist(i, (i + batchSize > targets.length) ? targets.length : i + batchSize);
          final results = await Future.wait(batch.map((targetIp) async {
            final st = await probeNode(ip: targetIp);
            return st.isConnected ? targetIp : null;
          }));

          final found = results.firstWhere((ip) => ip != null, orElse: () => null);
          if (found != null) return found;
        }
      }
    } catch (_) {}

    return null;
  }

  static Future<bool> toggleLedWifi({String ip = defaultNodeIp}) async {
    try {
      final uri = Uri.parse('http://$ip/api/v1/device/led');
      final req = await _client.postUrl(uri).timeout(const Duration(milliseconds: 1200));
      final res = await req.close().timeout(const Duration(milliseconds: 1200));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> toggleLed({String ip = defaultNodeIp}) => toggleLedWifi(ip: ip);
}
