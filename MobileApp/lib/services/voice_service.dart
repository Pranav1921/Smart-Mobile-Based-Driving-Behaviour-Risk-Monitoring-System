import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VoiceService {
  static final FlutterTts _tts = FlutterTts();
  static bool _initialized = false;
  static DateTime? _lastGlobalSpokenTime;
  static final Map<String, DateTime> _categoryTimestamps = {};
  static final Set<String> _announcedZoneIds = {};

  /// When true (default), voice talks ONLY when it's an emergency (SOS, Crash, Accident, Escalation).
  /// Non-emergency voice announcements (routine tips, points, mission accepted, etc.) are silenced.
  static bool emergencyOnlyMode = true;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      emergencyOnlyMode = prefs.getBool('sd_voice_emergency_only') ?? true;

      await _tts.setLanguage("en-US");
      await _tts.setSpeechRate(0.48);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      _initialized = true;
      print('[VoiceService] Text-To-Speech initialized (emergencyOnly: $emergencyOnlyMode).');
    } catch (e) {
      print('[VoiceService] TTS Init warning: $e');
    }
  }

  static Future<void> setEmergencyOnlyMode(bool enabled) async {
    emergencyOnlyMode = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('sd_voice_emergency_only', enabled);
      print('[VoiceService] Voice emergency-only mode changed to: $enabled');
    } catch (_) {}
  }

  static bool _isEmergencyAlert(String message, bool isCritical) {
    if (isCritical) return true;
    final lower = message.toLowerCase();
    return lower.contains('crash') ||
           lower.contains('emergency') ||
           lower.contains('sos') ||
           lower.contains('accident') ||
           lower.contains('stillness anomaly') ||
           lower.contains('collision') ||
           lower.contains('admin is calling') ||
           lower.contains('escalation');
  }

  /// Speak a message with intelligent global and per-category throttling.
  /// If [emergencyOnlyMode] is true, it ONLY speaks for emergencies.
  static Future<void> speak(
    String message, {
    String? category,
    bool isCritical = false,
    int cooldownSeconds = 25,
  }) async {
    final isEmergency = _isEmergencyAlert(message, isCritical);

    // If emergency-only mode is active, completely silence all non-emergency voice announcements
    if (emergencyOnlyMode && !isEmergency) {
      print('[VoiceService] 🔇 Silenced non-emergency voice announcement: "$message"');
      return;
    }

    final now = DateTime.now();

    // Emergency alerts bypass cooldowns
    if (!isEmergency) {
      // 1. Global Cooldown: Prevent any two voice alerts within 10 seconds of each other
      if (_lastGlobalSpokenTime != null && now.difference(_lastGlobalSpokenTime!).inSeconds < 10) {
        print('[VoiceService] 🔇 Dropped non-critical voice alert (Global 10s cooldown active): "$message"');
        return;
      }

      // 2. Category Cooldown: Prevent repeating the same type of warning within cooldownSeconds
      final catKey = category ?? _deriveCategory(message);
      final lastCatTime = _categoryTimestamps[catKey];
      if (lastCatTime != null && now.difference(lastCatTime).inSeconds < cooldownSeconds) {
        print('[VoiceService] 🔇 Dropped repetitive voice alert for "$catKey" (${cooldownSeconds}s cooldown active)');
        return;
      }

      _categoryTimestamps[catKey] = now;
    }

    _lastGlobalSpokenTime = now;

    try {
      await init();
      // Stop any ongoing speech so messages don't overlap
      await _tts.stop();
      print('[VoiceService] 🚨🔊 Spoken Alert: "$message"');
      await _tts.speak(message);
    } catch (e) {
      print('[VoiceService] Speak error: $e');
    }
  }

  static String _deriveCategory(String msg) {
    final lower = msg.toLowerCase();
    if (lower.contains('brake') || lower.contains('braking')) return 'harsh_brake';
    if (lower.contains('speed') || lower.contains('overspeed')) return 'speed_limit';
    if (lower.contains('turn')) return 'sharp_turn';
    if (lower.contains('accel')) return 'acceleration';
    if (lower.contains('school')) return 'school_zone';
    if (lower.contains('pothole') || lower.contains('road hazard') || lower.contains('rough road')) return 'road_hazard';
    if (lower.contains('one way') || lower.contains('wrong way')) return 'wrong_way';
    if (lower.contains('silence') || lower.contains('hospital')) return 'hospital_zone';
    if (lower.contains('admin')) return 'admin_inquiry';
    return lower.split(' ').take(3).join('_');
  }

  /// Trigger voice warning once upon entering a hazard/school zone
  static void checkAndAnnounceProximityHazard({
    required String hazardId,
    required String hazardName,
    required String hazardType,
    required int speedLimit,
  }) {
    if (_announcedZoneIds.contains(hazardId)) return;
    _announcedZoneIds.add(hazardId);

    final type = hazardType.toLowerCase();
    String msg;
    if (type.contains('school')) {
      msg = "School zone ahead. Limit speed to $speedLimit kilometers per hour.";
    } else if (type.contains('pothole') || type.contains('bad') || type.contains('road')) {
      msg = "Caution. Damaged road and potholes reported ahead. Reduce speed.";
    } else if (type.contains('accident')) {
      msg = "Caution. High accident hotspot ahead at $hazardName. Maintain safe distance.";
    } else if (type.contains('traffic')) {
      msg = "Heavy traffic congestion ahead near $hazardName.";
    } else {
      msg = "Caution. Approaching $hazardName zone.";
    }

    speak(msg, category: 'zone_$hazardId', cooldownSeconds: 45);
  }

  /// Trigger voice alert for driving behavior infractions (Harsh Brake, G-Force, Speed)
  static void announceDrivingWarning(String warningType, {double? val}) {
    final lower = warningType.toLowerCase();

    if (lower.contains('crash')) {
      speak("Critical emergency. Crash detected. Alerting fleet command.", isCritical: true);
      return;
    }

    if (lower.contains('brak')) {
      speak("Harsh braking detected. Please ease on the brakes.", category: 'harsh_brake', cooldownSeconds: 30);
    } else if (lower.contains('speed') || lower.contains('over')) {
      speak("Speed limit warning. Please reduce vehicle speed.", category: 'speed_limit', cooldownSeconds: 30);
    } else if (lower.contains('gforce') || lower.contains('accel')) {
      speak("Rapid acceleration detected. Smooth your driving.", category: 'acceleration', cooldownSeconds: 30);
    } else if (lower.contains('turn')) {
      speak("Sharp turn detected. Slow down prior to turning.", category: 'sharp_turn', cooldownSeconds: 30);
    }
  }

  /// Reset zone tracking when a shift ends
  static void resetSession() {
    _categoryTimestamps.clear();
    _announcedZoneIds.clear();
    _lastGlobalSpokenTime = null;
  }
}
