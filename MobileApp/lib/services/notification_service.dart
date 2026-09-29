import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/order_model.dart';

class SafetyNotificationItem {
  final String title;
  final String body;
  final DateTime timestamp;
  final String type; // alert, warning, info, success

  SafetyNotificationItem({
    required this.title,
    required this.body,
    required this.timestamp,
    this.type = 'warning',
  });
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static final List<SafetyNotificationItem> _alertHistory = [
    SafetyNotificationItem(
      title: "SAFETY SYSTEM READY",
      body: "Telemetric sensors and safety zone shields armed.",
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      type: "info",
    ),
  ];

  static final StreamController<SafetyNotificationItem> _alertController =
      StreamController<SafetyNotificationItem>.broadcast();

  static Stream<SafetyNotificationItem> get alertStream => _alertController.stream;
  static List<SafetyNotificationItem> get alertHistory => List.unmodifiable(_alertHistory);

  static Function()? onConfirmSafeFromNotification;
  static Function()? onTriggerSosFromNotification;

  static Future<void> init() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (response) {
          if (response.actionId == 'confirm_safe') {
            onConfirmSafeFromNotification?.call();
          } else if (response.actionId == 'trigger_sos') {
            onTriggerSosFromNotification?.call();
          }
        },
      );
    } catch (_) {}
  }

  /// Displays an ongoing / high priority notification with active order details
  /// so the driver can pull down Android status bar and view order info while in Google Maps.
  static Future<void> showActiveOrderNotification(DeliveryOrder order) async {
    final title = "🚚 Active Order: ${order.packageItems}";
    final body = "Driver: ${order.driverName} (${order.driverPhone})\nDrop: ${order.dropAddress}\nFrom: ${order.pickupAddress}";
    await showSafetyAlert(title, body, type: 'info');
  }

  /// High-priority heads-up notification that drops down directly on top of Google Maps
  /// allowing the driver to tap "I AM SAFE" or "TRIGGER SOS" without leaving navigation!
  static Future<void> showEmergencyCrashHeadsUpAlert({
    required String reason,
    required int countdown,
  }) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'emergency_crash_channel',
        'Emergency Crash & Safety Verification',
        channelDescription: 'High-priority heads-up notification during navigation/Google Maps',
        importance: Importance.max,
        priority: Priority.max,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        ticker: 'CRITICAL SAFETY ALERT',
        playSound: true,
        enableVibration: true,
        ongoing: true,
        autoCancel: false,
        actions: [
          AndroidNotificationAction('confirm_safe', '✅ I AM SAFE', showsUserInterface: true),
          AndroidNotificationAction('trigger_sos', '🚨 TRIGGER SOS', showsUserInterface: true),
        ],
        styleInformation: BigTextStyleInformation(''),
      );

      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      await _notificationsPlugin.show(
        9999,
        '🚨 CRASH DETECTED - ARE YOU SAFE?',
        '$reason. Tap "I AM SAFE" or open app to confirm ($countdown s).',
        platformChannelSpecifics,
      );
    } catch (_) {}
  }

  static Future<void> cancelCrashNotification() async {
    try {
      await _notificationsPlugin.cancel(9999);
    } catch (_) {}
  }

  /// Dedicated Tow Truck & Roadside Breakdown Notification (Distinct from Crash SOS)
  static Future<void> showTowBreakdownAlert({
    required String issueType,
    String? nearestTowName,
    String? nearestTowPhone,
    String? eta,
  }) async {
    final towTitle = "🚜 TOW & BREAKDOWN SOS DISPATCHED";
    final towBody = (nearestTowName != null && nearestTowPhone != null)
        ? "Assistance active for: $issueType\nNearest Tow: $nearestTowName ($nearestTowPhone) • ETA: ${eta ?? '12 mins'}"
        : "Emergency tow truck & mobile mechanic requested for: $issueType.\nLocation & telemetry shared with nearest highway recovery unit.";

    final item = SafetyNotificationItem(
      title: towTitle,
      body: towBody,
      timestamp: DateTime.now(),
      type: "tow_sos",
    );
    _alertHistory.insert(0, item);
    _alertController.add(item);

    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'tow_breakdown_channel',
        'Tow & Breakdown Assistance',
        channelDescription: 'Emergency vehicle towing and roadside mechanic dispatch alerts',
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.status,
        ticker: 'TOW TRUCK ASSISTANCE DISPATCHED',
        playSound: true,
        enableVibration: true,
        styleInformation: BigTextStyleInformation(''),
      );

      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      await _notificationsPlugin.show(
        8888, // Distinct notification ID for Tow SOS
        towTitle,
        towBody,
        platformChannelSpecifics,
      );
    } catch (_) {}
  }

  static Future<void> showSafetyAlert(String title, String body, {String type = 'warning'}) async {
    final item = SafetyNotificationItem(
      title: title,
      body: body,
      timestamp: DateTime.now(),
      type: type,
    );
    _alertHistory.insert(0, item);
    _alertController.add(item);

    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'safety_alerts',
        'Safety Alerts',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        styleInformation: BigTextStyleInformation(''),
      );

      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      await _notificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        platformChannelSpecifics,
      );
    } catch (_) {}
  }
}

