import 'dart:math' as math;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Low-latency in-memory mechanical sound synthesis engine & haptics coordinator
class SoundEffectService {
  SoundEffectService._();

  static final AudioPlayer _tickPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
  static final AudioPlayer _relayPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
  static final AudioPlayer _beepPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
  static final AudioPlayer _alertPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.stop);

  static Uint8List? _cachedNotchWav;
  static Uint8List? _cachedRelayWav;
  static Uint8List? _cachedBeepWav;
  static Uint8List? _cachedAlertWav;
  static Uint8List? _cachedSuccessWav;

  static bool _soundEnabled = true;
  static bool get isSoundEnabled => _soundEnabled;

  static void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
  }

  /// Initialize and pre-bake WAV byte arrays in memory
  static Future<void> init() async {
    _cachedNotchWav = _generateClickWav(durationMs: 16, freq: 1600, decayRate: 25);
    _cachedRelayWav = _generateRelayWav(durationMs: 40);
    _cachedBeepWav = _generateSineWav(durationMs: 45, freq: 1200);
    _cachedAlertWav = _generateDualToneWav(durationMs: 140, freq1: 880, freq2: 1760);
    _cachedSuccessWav = _generateChordWav(durationMs: 120);

    try {
      await _tickPlayer.setVolume(0.45);
      await _relayPlayer.setVolume(0.65);
      await _beepPlayer.setVolume(0.55);
      await _alertPlayer.setVolume(0.85);
    } catch (_) {}
  }

  /// Ultra-low latency rotary dial notch click (Mechanical tick + haptic click)
  static void playNotchTick() {
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}

    if (!_soundEnabled) return;
    if (_cachedNotchWav == null) init();
    try {
      if (_cachedNotchWav != null) {
        _tickPlayer.play(BytesSource(_cachedNotchWav!), volume: 0.45);
      }
    } catch (_) {}
  }

  /// Heavy mechanical toggle / latch switch snap
  static void playRelayLatch({bool isEngage = true}) {
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}

    if (!_soundEnabled) return;
    if (_cachedRelayWav == null) init();
    try {
      if (_cachedRelayWav != null) {
        _relayPlayer.play(BytesSource(_cachedRelayWav!), volume: 0.65);
      }
    } catch (_) {}
  }

  /// Telemetry / Sensor sync beep
  static void playTelemetryBeep() {
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}

    if (!_soundEnabled) return;
    if (_cachedBeepWav == null) init();
    try {
      if (_cachedBeepWav != null) {
        _beepPlayer.play(BytesSource(_cachedBeepWav!), volume: 0.55);
      }
    } catch (_) {}
  }

  /// Critical hardware safety alert alarm
  static void playAlertTone() {
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}

    if (!_soundEnabled) return;
    if (_cachedAlertWav == null) init();
    try {
      if (_cachedAlertWav != null) {
        _alertPlayer.play(BytesSource(_cachedAlertWav!), volume: 0.85);
      }
    } catch (_) {}
  }

  /// Operation confirmed chime
  static void playSuccess() {
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}

    if (!_soundEnabled) return;
    if (_cachedSuccessWav == null) init();
    try {
      if (_cachedSuccessWav != null) {
        _beepPlayer.play(BytesSource(_cachedSuccessWav!), volume: 0.6);
      }
    } catch (_) {}
  }

  // --- WAV Generation Math Helpers (16-bit Mono PCM) ---

  static Uint8List _generateClickWav({required int durationMs, required double freq, required double decayRate}) {
    const int sampleRate = 22050;
    final int numSamples = (sampleRate * (durationMs / 1000)).round();
    final Int16List pcm = Int16List(numSamples);

    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      final double env = math.exp(-decayRate * (i / numSamples));
      final double sample = math.sin(2 * math.pi * freq * t) * env;
      pcm[i] = (sample * 24000).clamp(-32767, 32767).toInt();
    }

    return _buildWavHeader(pcm, sampleRate);
  }

  static Uint8List _generateRelayWav({required int durationMs}) {
    const int sampleRate = 22050;
    final int numSamples = (sampleRate * (durationMs / 1000)).round();
    final Int16List pcm = Int16List(numSamples);
    final math.Random rand = math.Random(42);

    for (int i = 0; i < numSamples; i++) {
      final double t = i / numSamples;
      final double click = (i < numSamples * 0.25) ? (rand.nextDouble() * 2 - 1) * 0.9 : 0;
      final double tone = math.sin(2 * math.pi * 320 * (i / sampleRate)) * math.exp(-12 * t);
      final double combined = (click + tone * 0.8).clamp(-1.0, 1.0);
      pcm[i] = (combined * 28000).toInt();
    }

    return _buildWavHeader(pcm, sampleRate);
  }

  static Uint8List _generateSineWav({required int durationMs, required double freq}) {
    const int sampleRate = 22050;
    final int numSamples = (sampleRate * (durationMs / 1000)).round();
    final Int16List pcm = Int16List(numSamples);

    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      final double env = math.sin(math.pi * (i / numSamples)); // smooth window
      final double sample = math.sin(2 * math.pi * freq * t) * env;
      pcm[i] = (sample * 22000).toInt();
    }

    return _buildWavHeader(pcm, sampleRate);
  }

  static Uint8List _generateDualToneWav({required int durationMs, required double freq1, required double freq2}) {
    const int sampleRate = 22050;
    final int numSamples = (sampleRate * (durationMs / 1000)).round();
    final Int16List pcm = Int16List(numSamples);

    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      final double env = math.exp(-5 * (i / numSamples));
      final double sample = (math.sin(2 * math.pi * freq1 * t) + math.sin(2 * math.pi * freq2 * t)) * 0.5 * env;
      pcm[i] = (sample * 28000).toInt();
    }

    return _buildWavHeader(pcm, sampleRate);
  }

  static Uint8List _generateChordWav({required int durationMs}) {
    const int sampleRate = 22050;
    final int numSamples = (sampleRate * (durationMs / 1000)).round();
    final Int16List pcm = Int16List(numSamples);

    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      final double env = math.exp(-8 * (i / numSamples));
      final double sample = (
        math.sin(2 * math.pi * 523.25 * t) + // C5
        math.sin(2 * math.pi * 659.25 * t) + // E5
        math.sin(2 * math.pi * 783.99 * t)   // G5
      ) / 3.0 * env;
      pcm[i] = (sample * 26000).toInt();
    }

    return _buildWavHeader(pcm, sampleRate);
  }

  static Uint8List _buildWavHeader(Int16List pcmData, int sampleRate) {
    final int byteRate = sampleRate * 2;
    final int dataLength = pcmData.lengthInBytes;
    final int totalLength = 36 + dataLength;

    final ByteData header = ByteData(44);
    // RIFF chunk
    header.setUint8(0, 0x52); // R
    header.setUint8(1, 0x49); // I
    header.setUint8(2, 0x46); // F
    header.setUint8(3, 0x46); // F
    header.setUint32(4, totalLength, Endian.little);
    header.setUint8(8, 0x57);  // W
    header.setUint8(9, 0x41);  // A
    header.setUint8(10, 0x56); // V
    header.setUint8(11, 0x45); // E

    // fmt sub-chunk
    header.setUint8(12, 0x66); // f
    header.setUint8(13, 0x6D); // m
    header.setUint8(14, 0x74); // t
    header.setUint8(15, 0x20); // ' '
    header.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
    header.setUint16(20, 1, Endian.little);  // AudioFormat (1 = PCM)
    header.setUint16(22, 1, Endian.little);  // NumChannels (1 = Mono)
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, 2, Endian.little);  // BlockAlign
    header.setUint16(34, 16, Endian.little); // BitsPerSample (16 bits)

    // data sub-chunk
    header.setUint8(36, 0x64); // d
    header.setUint8(37, 0x61); // a
    header.setUint8(38, 0x74); // t
    header.setUint8(39, 0x61); // a
    header.setUint32(40, dataLength, Endian.little);

    final Uint8List result = Uint8List(44 + dataLength);
    result.setRange(0, 44, header.buffer.asUint8List());
    result.setRange(44, 44 + dataLength, pcmData.buffer.asUint8List());
    return result;
  }
}
