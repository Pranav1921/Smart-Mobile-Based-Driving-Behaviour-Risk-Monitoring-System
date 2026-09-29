import 'dart:async';
import 'dart:io';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'api_service.dart';
import 'voice_service.dart';
import 'sensor_service.dart';
import 'notification_service.dart';
import 'discovery_service.dart';
import '../core/constants/app_urls.dart';

class SocketService {
  static IO.Socket? _socket;
  static Function(String message)? onDriverAlertCallback;
  static Function(String message)? onDriverCheckPingCallback;
  
  static String? _connectedHost;
  static String connectionStatus = "Disconnected";
  static String? get connectedHost => _connectedHost;
  static bool get isConnected => _socket?.connected ?? false;

  static Map<String, dynamic>? _lastPendingGpsUpdate;
  static final List<Map<String, dynamic>> _offlineBuffer = [];
  static final List<Map<String, dynamic>> _pendingBreakdownAlerts = [];
  static final List<Map<String, dynamic>> _pendingSosAlerts = [];
  static int get offlineBufferedCount => _offlineBuffer.length + _pendingBreakdownAlerts.length + _pendingSosAlerts.length;
  static bool get isGhatModeActive => !isConnected && (_offlineBuffer.isNotEmpty || _pendingBreakdownAlerts.isNotEmpty || _pendingSosAlerts.isNotEmpty);

  static StreamSubscription<String>? _hostSubscription;
  static int _consecutiveErrors = 0;
  static bool _isRediscovering = false;

  static void initSocket({String? customHost}) async {
    // Listen for dynamic host changes from discovery or UI
    _hostSubscription ??= DiscoveryService.onHostChanged.listen((newHost) async {
      String? token = await ApiService.getToken();
      token ??= "demo-driver-token-${DateTime.now().millisecondsSinceEpoch}";
      if (_connectedHost != newHost) {
        print('[SocketService] 🔄 Host changed dynamically to $newHost. Re-establishing link...');
        _connectToHost(newHost, token);
      }
    });

    String? token = await ApiService.getToken();
    if (token == null || token.isEmpty) {
      token = "demo-driver-token-${DateTime.now().millisecondsSinceEpoch}";
      print('[SocketService] ℹ️ Using demo auth token for driver socket handshake.');
    }

    String? targetHost;
    if (customHost != null && customHost.isNotEmpty) {
      targetHost = customHost.startsWith('http') ? customHost : 'http://$customHost:3000';
      DiscoveryService.setManualHost(targetHost);
    } else {
      connectionStatus = "Auto-discovering server...";
      targetHost = await DiscoveryService.autoDiscoverHost();
    }

    targetHost ??= AppUrls.socketUrl;
    print('[SocketService] 🎯 Selected target backend host: $targetHost');
    ApiService.setCustomHost(targetHost);
    _connectToHost(targetHost, token);
  }

  static void _connectToHost(String host, String token) {
    _socket?.dispose();
    _socket = null;

    print('[SocketService] 🔌 Establishing Socket.IO connection to: $host');
    connectionStatus = "Linking: $host";

    final socket = IO.io(
      host,
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(999)
          .setReconnectionDelay(1000)
          .setTimeout(4000)
          .setAuth({'token': token, 'role': 'DRIVER'})
          .build(),
    );

    socket.onConnect((_) {
      _consecutiveErrors = 0;
      _connectedHost = host;
      _socket = socket;
      connectionStatus = "Connected ($host)";
      print('[SocketService] ✅ LINK ESTABLISHED at $host (Socket ID: ${socket.id})');

      if (_lastPendingGpsUpdate != null) {
        _socket?.emit('gps_update', _lastPendingGpsUpdate);
        print('[SocketService] 🚀 Initial telemetry transmitted.');
      }

      // Burst-sync pending SOS panic alerts queued during Ghat / Dead Zone mode
      if (_pendingSosAlerts.isNotEmpty) {
        final pendingSos = List<Map<String, dynamic>>.from(_pendingSosAlerts);
        _pendingSosAlerts.clear();
        for (final sos in pendingSos) {
          _socket?.emit('driver_sos_alert', sos);
          _socket?.emit('sos_alert', sos);
          print('[SocketService] 🚨 GHAT / DEAD ZONE RECONNECT: Emitted queued SOS alert: ${sos['reason']}');
        }
      }

      // Burst-sync pending Roadside Breakdown alerts queued during Ghat / valley offline mode
      if (_pendingBreakdownAlerts.isNotEmpty) {
        final pendingAlerts = List<Map<String, dynamic>>.from(_pendingBreakdownAlerts);
        _pendingBreakdownAlerts.clear();
        for (final alert in pendingAlerts) {
          _socket?.emit('roadside_breakdown_alert', alert);
          print('[SocketService] 🚨 GHAT RECONNECT: Emitted queued roadside breakdown alert: ${alert['issueType']}');
        }
      }

      // Burst-sync buffered Ghat Mode telemetry points
      if (_offlineBuffer.isNotEmpty) {
        final burstBatch = List<Map<String, dynamic>>.from(_offlineBuffer);
        _offlineBuffer.clear();
        final firstDriverId = burstBatch.first['driverId'] ?? 'demo-driver';
        _socket?.emit('batch_offline_telemetry', {
          'driverId': firstDriverId,
          'count': burstBatch.length,
          'points': burstBatch,
          'syncedAt': DateTime.now().toUtc().toIso8601String(),
        });
        print('[SocketService] ⚡ GHAT MODE: Burst synced ${burstBatch.length} buffered telemetry points to server!');
      }
    });

    socket.onConnectError((err) {
      print('[SocketService] ❌ Connection error on $host: $err');
      connectionStatus = "Link Error on $host";
      _consecutiveErrors++;

      // If multiple consecutive failures occur (e.g. host IP changed on Wi-Fi switch),
      // trigger zero-config background sweep to find the new IP
      if (_consecutiveErrors >= 3 && !_isRediscovering) {
        _attemptAutoRecovery(token);
      }
    });

    socket.onDisconnect((_) {
      print('[SocketService] 🔌 Link Severed from host');
      connectionStatus = "Disconnected";
    });

    _attachListeners(socket);
  }

  static void _attemptAutoRecovery(String token) async {
    _isRediscovering = true;
    _consecutiveErrors = 0;
    print('[SocketService] 🔍 Server unreachable on current IP. Sweeping subnets for updated IP...');
    connectionStatus = "Re-discovering backend server...";

    try {
      final newHost = await DiscoveryService.autoDiscoverHost(forceRefresh: true);
      if (newHost != null && newHost != _connectedHost) {
        print('[SocketService] ✨ Found updated backend server at $newHost! Connecting...');
        _connectToHost(newHost, token);
      }
    } catch (_) {} finally {
      _isRediscovering = false;
    }
  }

  static void _attachListeners(IO.Socket socket) {
    socket.on('admin_crash_check', (data) {
      onDriverCheckPingCallback?.call(data['message'] ?? 'Confirm Safety');
    });

    socket.on('driver_check_ping', (data) {
      onDriverCheckPingCallback?.call(data['message'] ?? 'Admin safety check: Are you safe?');
    });

    socket.on('request_live_cam', (data) {
      final active = data['active'] == true;
      print('[SocketService] 📹 Live camera requested: $active');
      onLiveCamRequestCallback?.call(active);
    });

    socket.on('driver_message', (data) {
      final msg = (data is Map ? (data['message'] ?? '') : data.toString()).toString();
      if (msg.isNotEmpty) {
        print('[SocketService] 📩 Received Admin Message: $msg');
        VoiceService.speak("Admin is asking: $msg");
        NotificationService.showSafetyAlert("ADMIN INQUIRY", "Admin is asking: $msg");
        SensorService.vibrate(duration: 600);
        onDriverAlertCallback?.call("Admin is asking: $msg");
      }
    });

    socket.on('admin_call_trigger', (data) {
      VoiceService.speak("Admin is calling you. Please answer.");
      onDriverAlertCallback?.call("INCOMING ADMIN CALL: ${data['phone']}");
    });

    socket.on('job_assigned', (data) {
      print('[SocketService] 📦 New job assigned from Admin: $data');
      if (data is Map<String, dynamic>) {
        onJobAssignedCallback?.call(data);
      } else if (data is Map) {
        onJobAssignedCallback?.call(Map<String, dynamic>.from(data));
      }
    });

    socket.on('potholes_snapshot', (data) {
      print('[SocketService] 🕳️ Received Potholes Snapshot: $data');
      if (data is List) {
        onPotholesSnapshotCallback?.call(data);
      }
    });

    socket.on('pothole_broadcast', (data) {
      print('[SocketService] ⚠️ Received Pothole Hazard Broadcast: $data');
      if (data is Map<String, dynamic>) {
        onPotholeBroadcastCallback?.call(data);
      } else if (data is Map) {
        onPotholeBroadcastCallback?.call(Map<String, dynamic>.from(data));
      }
    });

    socket.on('blind_curve_warning', (data) {
      print('[SocketService] ⚠️ Blind Curve V2V Warning received: $data');
      if (data is Map<String, dynamic>) {
        onBlindCurveWarningCallback?.call(data);
      } else if (data is Map) {
        onBlindCurveWarningCallback?.call(Map<String, dynamic>.from(data));
      }
    });

    socket.on('admin_voice_broadcast', (data) {
      print('[SocketService] 📢 Received Admin Voice Broadcast: $data');
      if (data is Map<String, dynamic>) {
        onVoiceBroadcastCallback?.call(data);
      } else if (data is Map) {
        onVoiceBroadcastCallback?.call(Map<String, dynamic>.from(data));
      }
    });

    socket.on('geofences_sync', (data) {
      print('[SocketService] 🌐 Received Dynamic Geofences Sync: $data');
      if (data is List) {
        onGeofencesSyncCallback?.call(data);
      }
    });

    socket.on('geofence_updated', (data) {
      print('[SocketService] 🌐 Dynamic Geofence updated: $data');
      if (data is Map && data['all'] is List) {
        onGeofencesSyncCallback?.call(data['all']);
      }
    });

    socket.onDisconnect((_) {
       print('[SocketService] 🔌 Link Severed from host');
       connectionStatus = "Disconnected";
    });
  }

  static Function(Map<String, dynamic> data)? onJobAssignedCallback;
  static Function(String? reportId)? onCrashConfirmedCallback;
  static Function(bool active)? onLiveCamRequestCallback;
  static Function(dynamic data)? onPotholeDetectedCallback;
  static Function(List<dynamic> list)? onPotholesSnapshotCallback;
  static Function(Map<String, dynamic> data)? onPotholeBroadcastCallback;
  static Function(Map<String, dynamic> data)? onBlindCurveWarningCallback;
  static Function(Map<String, dynamic> data)? onVoiceBroadcastCallback;
  static Function(List<dynamic> list)? onGeofencesSyncCallback;

  static void requestGeofencesSync() {
    if (_socket == null || !_socket!.connected) return;
    _socket?.emit('get_geofences');
  }

  static void emitLiveFrame(String driverId, String base64Frame) {
    if (_socket == null || !_socket!.connected) return;
    _socket?.emit('live_frame', {
      'driverId': driverId,
      'frame': base64Frame,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
  }

  static void emitShiftStatus({
    required String driverId,
    required String status,
    required double lat,
    required double lng,
    String? driverName,
    String? regionId,
    String? region,
  }) {
    if (_socket == null || !_socket!.connected) return;
    _socket?.emit('shift_status', {
      'driverId': driverId,
      'driverName': driverName,
      'status': status,
      'latitude': lat,
      'longitude': lng,
      'regionId': regionId,
      'region': region ?? regionId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  static void emitCrashAlert({
    required String driverId,
    required String reason,
    required double lat,
    required double lng,
    double? speedBefore,
    double? speedAfter,
    double? gForce,
    double? accelX,
    double? accelY,
    double? accelZ,
    List<Map<String, dynamic>>? blackBoxData,
  }) {
    if (_socket == null || !_socket!.connected) return;
    final payload = {
      'driverId': driverId,
      'reason': reason,
      'latitude': lat,
      'longitude': lng,
      'severity': 'CRITICAL',
      'speedBefore': speedBefore ?? 60.0,
      'speedAfter': speedAfter ?? 0.0,
      'gForce': gForce ?? 4.2,
      'accelX': accelX ?? 0.0,
      'accelY': accelY ?? 0.0,
      'accelZ': accelZ ?? 3.8,
      'blackBoxData': blackBoxData ?? [],
      'timestamp': DateTime.now().toIso8601String(),
    };
    _socket?.emit('crash_event', payload);
    _socket?.emit('crash_detected', payload);
  }

  static void emitEmergencyEscalation({required String driverId, String? reason}) {
    if (_socket == null || !_socket!.connected) return;
    final payload = {
      'driverId': driverId,
      'reason': reason ?? 'Emergency SOS / Verification Timer Expired',
      'timestamp': DateTime.now().toIso8601String(),
    };
    _socket?.emit('emergency_escalation', payload);
    _socket?.emit('driver_no_response', payload);
  }

  static void emitPingNoResponse({required String driverId, String? reason}) {
    if (_socket == null || !_socket!.connected) return;
    final payload = {
      'driverId': driverId,
      'reason': reason ?? 'Admin Safety Ping Expired: No Response from Driver (30s elapsed)',
      'timestamp': DateTime.now().toIso8601String(),
    };
    _socket?.emit('driver_no_response', payload);
    _socket?.emit('emergency_escalation', payload);
  }

  static void emitPotholeDetected({
    required double lat,
    required double lng,
    double? intensity,
    double? vibrationRate,
    String? roadName,
    String? driverId,
    String? driverName,
    String? regionId,
  }) {
    if (_socket == null || !_socket!.connected) return;
    _socket?.emit('pothole_detected', {
      'latitude': lat,
      'longitude': lng,
      'intensity': intensity ?? 0.85,
      'vibrationRate': vibrationRate ?? 3.2,
      'roadName': roadName ?? 'Main Transit Sector',
      'driverId': driverId,
      'driverName': driverName,
      'regionId': regionId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  static void emitRuleViolation(Map<String, dynamic> data) {
    if (_socket == null || !_socket!.connected) return;
    _socket?.emit('rule_violation_alert', data);
  }

  static void emitJobAccepted(String orderId, String driverName) {
    if (_socket == null || !_socket!.connected) return;
    _socket?.emit('job_accepted', {
      'orderId': orderId,
      'driverName': driverName,
    });
  }

  static void emitSafetyResponse({String? driverId, String? driverName}) {
    if (_socket == null || !_socket!.connected) return;
    _socket?.emit('safety_response', {
      'driverId': driverId,
      'driverName': driverName,
      'status': 'safe',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  static void emitLeaveStatus({
    required String driverId,
    String? driverName,
    required bool isOnLeave,
    String? reason,
    String? regionId,
  }) {
    if (_socket == null || !_socket!.connected) return;
    _socket?.emit('driver_leave_status', {
      'driverId': driverId,
      'driverName': driverName,
      'isOnLeave': isOnLeave,
      'reason': reason ?? '',
      'regionId': regionId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  static void emitGpsUpdate({
    String? tripId,
    String? driverId,
    String? driverName,
    String? regionId,
    String? region,
    String? deliveryFrom,
    String? deliveryTo,
    String? orderItems,
    required double lat,
    required double lng,
    required double speed,
    required double heading,
    double? accelX,
    double? accelY,
    double? accelZ,
    double? vibrationRate,
    double? gyroX,
    double? gyroY,
    double? gyroZ,
    double? magX,
    double? magY,
    double? magZ,
    double? destLat,
    double? destLng,
    String? status,
    double? safetyScore,
    int? points,
    double? earnings,
    int? trips,
    double? distanceToday,
    int? harshBrakingCount,
    int? overspeedCount,
    int? sharpTurnCount,
    String? email,
    String? phoneNumber,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? familyRelationship,
  }) {
    final payload = {
      'tripId': tripId,
      'driverId': driverId,
      'driverName': driverName,
      'regionId': regionId,
      'region': region ?? regionId,
      'deliveryFrom': deliveryFrom,
      'deliveryTo': deliveryTo,
      'orderItems': orderItems,
      'latitude': lat,
      'longitude': lng,
      'speed': speed,
      'heading': heading,
      'accelX': accelX,
      'accelY': accelY,
      'accelZ': accelZ,
      'vibrationRate': vibrationRate,
      'gyroX': gyroX,
      'gyroY': gyroY,
      'gyroZ': gyroZ,
      'magX': magX,
      'magY': magY,
      'magZ': magZ,
      'destLat': destLat,
      'destLng': destLng,
      'status': status,
      'safetyScore': safetyScore,
      'points': points ?? 0,
      'earnings': earnings ?? 0.0,
      'trips': trips ?? 0,
      'distanceToday': distanceToday ?? 0.0,
      'harshBrakingCount': harshBrakingCount ?? 0,
      'overspeedCount': overspeedCount ?? 0,
      'sharpTurnCount': sharpTurnCount ?? 0,
      if (email != null && email.isNotEmpty) 'email': email,
      if (phoneNumber != null && phoneNumber.isNotEmpty) 'phone': phoneNumber,
      if (phoneNumber != null && phoneNumber.isNotEmpty) 'phoneNumber': phoneNumber,
      if (emergencyContactName != null && emergencyContactName.isNotEmpty) 'emergencyContactName': emergencyContactName,
      if (emergencyContactPhone != null && emergencyContactPhone.isNotEmpty) 'emergencyContactPhone': emergencyContactPhone,
      if (familyRelationship != null && familyRelationship.isNotEmpty) 'familyRelationship': familyRelationship,
      'timestamp': DateTime.now().toUtc().toIso8601String()
    };

    _lastPendingGpsUpdate = payload;

    if (_socket != null && _socket!.connected) {
      _socket?.emit('gps_update', payload);
    } else {
      if (_offlineBuffer.length >= 500) {
        _offlineBuffer.removeAt(0); // FIFO drop oldest point
      }
      _offlineBuffer.add(payload);
      _consecutiveErrors++;
      if (_consecutiveErrors >= 4 && !_isRediscovering) {
        _attemptAutoRecovery("demo-driver-token-${DateTime.now().millisecondsSinceEpoch}");
      }
    }
  }

  static void emitRoadsideBreakdown({
    required String driverId,
    required String driverName,
    required String issueType,
    String? notes,
    required double lat,
    required double lng,
    String? vehiclePlate,
  }) {
    final payload = {
      'id': 'BRK-${DateTime.now().millisecondsSinceEpoch}',
      'driverId': driverId,
      'driverName': driverName,
      'issueType': issueType,
      'breakdownType': issueType,
      'notes': notes ?? '',
      'latitude': lat,
      'longitude': lng,
      'vehiclePlate': vehiclePlate ?? 'KA-19-PT-2026',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    if (_socket != null && _socket!.connected) {
      _socket?.emit('roadside_breakdown_alert', payload);
      print('[SocketService] 🚨 Roadside breakdown alert emitted live: $issueType');
    } else {
      _pendingBreakdownAlerts.add(payload);
      print('[SocketService] 🚨 Roadside breakdown alert queued for offline sync (Ghat Mode): $issueType');
    }
  }

  static void emitSosAlert({
    required String driverId,
    required String driverName,
    required double lat,
    required double lng,
    String? reason,
    String? phone,
    String? vehiclePlate,
    double? speed,
  }) {
    final payload = {
      'id': 'SOS-${DateTime.now().millisecondsSinceEpoch}',
      'driverId': driverId,
      'driverName': driverName,
      'alertType': 'SOS',
      'reason': reason ?? 'Manual SOS Panic Triggered by Operator',
      'latitude': lat,
      'longitude': lng,
      'speed': speed ?? 0.0,
      'phone': phone ?? '+91 94812 55667',
      'vehiclePlate': vehiclePlate ?? 'KA-19-PT-2026',
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };
    if (_socket != null && _socket!.connected) {
      _socket?.emit('driver_sos_alert', payload);
      _socket?.emit('sos_alert', payload);
      print('[SocketService] 🚨 Driver SOS Panic alert emitted live: ${payload['reason']}');
    } else {
      _pendingSosAlerts.add(payload);
      print('[SocketService] 🚨 Driver SOS Panic alert queued for offline sync (Dead Zone Mode): ${payload['reason']}');
    }
  }

  static void forceSyncBuffer() {
    if (!isConnected || _socket == null) return;
    if (_pendingSosAlerts.isNotEmpty) {
      final pendingSos = List<Map<String, dynamic>>.from(_pendingSosAlerts);
      _pendingSosAlerts.clear();
      for (final sos in pendingSos) {
        _socket?.emit('driver_sos_alert', sos);
        _socket?.emit('sos_alert', sos);
      }
    }
    if (_pendingBreakdownAlerts.isNotEmpty) {
      final pendingAlerts = List<Map<String, dynamic>>.from(_pendingBreakdownAlerts);
      _pendingBreakdownAlerts.clear();
      for (final alert in pendingAlerts) {
        _socket?.emit('roadside_breakdown_alert', alert);
      }
    }
    if (_offlineBuffer.isNotEmpty) {
      final burstBatch = List<Map<String, dynamic>>.from(_offlineBuffer);
      _offlineBuffer.clear();
      final firstDriverId = burstBatch.first['driverId'] ?? 'demo-driver';
      _socket?.emit('batch_offline_telemetry', {
        'driverId': firstDriverId,
        'count': burstBatch.length,
        'points': burstBatch,
        'syncedAt': DateTime.now().toUtc().toIso8601String(),
      });
      print('[SocketService] ⚡ GHAT MODE: Manually burst-synced ${burstBatch.length} buffered points!');
    }
  }

  static void emitLockedDashcamEvidence({
    required String driverId,
    String? driverName,
    required String reason,
    required List<Map<String, dynamic>> frames,
  }) {
    final payload = {
      'driverId': driverId,
      'driverName': driverName,
      'reason': reason,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'frames': frames,
    };
    if (_socket != null && _socket!.connected) {
      _socket?.emit('locked_dashcam_evidence', payload);
    }
    print('[SocketService] 📹 Locked dashcam evidence emitted: ${frames.length} frames');
  }

  static void emitTripAnalysis(Map<String, dynamic> data) {
    if (_socket != null && _socket!.connected) {
      _socket?.emit('trip_telemetry_analysis', data);
    }
  }

  static void emitAvatarUpdate(Map<String, dynamic> data) {
    if (_socket != null && _socket!.connected) {
      _socket?.emit('driver_avatar_update', data);
    }
  }

  static void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _connectedHost = null;
  }
}
