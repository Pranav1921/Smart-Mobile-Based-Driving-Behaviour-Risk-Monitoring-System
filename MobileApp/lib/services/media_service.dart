import 'dart:io';
import 'package:camera/camera.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

class MediaService {
  static CameraController? _cameraController;
  static final AudioRecorder _audioRecorder = AudioRecorder();
  static bool _isRecording = false;

  static bool get isRecording => _isRecording;

  static Future<void> init() async {
    if (_cameraController != null && _cameraController!.value.isInitialized) return;

    try {
      final permStatus = await Permission.camera.request();
      if (!permStatus.isGranted && !permStatus.isLimited) {
        print("[MediaService] ⚠️ Camera permission not granted ($permStatus)");
      }
    } catch (_) {}

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        print("[MediaService] ⚠️ No cameras found on device.");
        return;
      }

      CameraDescription selectedCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        selectedCamera,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();
      print("[MediaService] ✅ Camera initialized on ${selectedCamera.lensDirection}");
    } catch (e) {
      print("[MediaService] Camera init error: $e");
      // Fallback try with first camera if front failed
      try {
        final cameras = await availableCameras();
        if (cameras.isNotEmpty) {
          _cameraController = CameraController(
            cameras.first,
            ResolutionPreset.low,
            enableAudio: false,
            imageFormatGroup: ImageFormatGroup.jpeg,
          );
          await _cameraController!.initialize();
          print("[MediaService] ✅ Fallback camera initialized");
        }
      } catch (err2) {
        print("[MediaService] Fallback camera init error: $err2");
      }
    }
  }

  static Future<void> startRecording() async {
    if (_isRecording) return;

    try {
      await init();

      final tempDir = await getTemporaryDirectory();
      final videoPath = p.join(tempDir.path, "sos_video_${DateTime.now().millisecondsSinceEpoch}.mp4");
      final audioPath = p.join(tempDir.path, "sos_audio_${DateTime.now().millisecondsSinceEpoch}.m4a");

      // Start Video
      await _cameraController!.startVideoRecording();

      // Start Audio
      if (await _audioRecorder.hasPermission()) {
        await _audioRecorder.start(const RecordConfig(), path: audioPath);
      }

      _isRecording = true;
      print("[MediaService] Recording started: $videoPath");
    } catch (e) {
      print("[MediaService] Start recording error: $e");
    }
  }

  static Future<Map<String, String?>> stopRecording() async {
    if (!_isRecording) return {"video": null, "audio": null};

    String? videoPath;
    String? audioPath;

    try {
      // Stop Video
      final XFile videoFile = await _cameraController!.stopVideoRecording();
      videoPath = videoFile.path;

      // Stop Audio
      audioPath = await _audioRecorder.stop();

      _isRecording = false;
      print("[MediaService] Recording stopped. Video: $videoPath, Audio: $audioPath");
    } catch (e) {
      print("[MediaService] Stop recording error: $e");
    } finally {
      // Release camera hardware immediately after recording finishes
      await releaseCamera();
    }

    return {"video": videoPath, "audio": audioPath};
  }

  static Future<List<int>?> captureFrame() async {
    try {
      await init();
      if (_cameraController == null || !_cameraController!.value.isInitialized) return null;
      if (_cameraController!.value.isTakingPicture) return null;

      final XFile image = await _cameraController!.takePicture();
      final bytes = await image.readAsBytes();

      // Clean up temporary image file on disk immediately
      try {
        final f = File(image.path);
        if (await f.exists()) await f.delete();
      } catch (_) {}

      return bytes;
    } catch (e) {
      print("[MediaService] Frame capture error: $e");
      return null;
    }
  }

  /// Completely releases and powers down the camera hardware sensor
  static Future<void> releaseCamera() async {
    if (_cameraController != null) {
      try {
        final controller = _cameraController;
        _cameraController = null;
        await controller?.dispose();
        print("[MediaService] 📷 Camera hardware completely released and powered OFF.");
      } catch (e) {
        print("[MediaService] Camera release error: $e");
      }
    }
  }

  static Future<void> dispose() async {
    await releaseCamera();
    await _audioRecorder.dispose();
  }
}
