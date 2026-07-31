import 'dart:io';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:vibration/vibration.dart';
import 'api_service.dart';

class SocketService {
  static IO.Socket? _socket;
  
  // URL determination for physical vs emulator
  static final String _socketUrl = Platform.isAndroid 
      ? "http://127.0.0.1:3000" 
      : "http://localhost:3000";

  static void initSocket() async {
    final token = await ApiService.getToken();
    if (token == null) return;

    _socket = IO.io(_socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'auth': {'token': token},
    });

    _socket?.onConnect((_) {
      print('Socket.IO connected to backend');
    });

    _socket?.on('vibration_alert', (data) async {
      print('Received vibration alert from admin: $data');
      bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        Vibration.vibrate(pattern: [500, 1000, 500, 2000], intensities: [128, 255, 128, 255]);
      }
    });

    _socket?.onDisconnect((_) => print('Socket.IO disconnected'));
  }

  static void emitGpsUpdate({
    String? tripId,
    required double lat,
    required double lng,
    required double speed,
    required double heading,
  }) {
    if (_socket == null || !_socket!.connected) return;
    
    _socket?.emit('gps_update', {
      'tripId': tripId,
      'latitude': lat,
      'longitude': lng,
      'speed': speed,
      'heading': heading,
      'timestamp': DateTime.now().toUtc().toIso8601String()
    });
  }

  static void emitCrashEvent({
    String? tripId,
    required double lat,
    required double lng,
    String severity = 'CRITICAL',
    Map<String, dynamic>? sensorData
  }) {
    if (_socket == null || !_socket!.connected) return;
    
    _socket?.emit('crash_event', {
      'tripId': tripId,
      'latitude': lat,
      'longitude': lng,
      'severity': severity,
      'accelX': sensorData?['accel_x'],
      'accelY': sensorData?['accel_y'],
      'accelZ': sensorData?['accel_z'],
    });
  }

  static void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
