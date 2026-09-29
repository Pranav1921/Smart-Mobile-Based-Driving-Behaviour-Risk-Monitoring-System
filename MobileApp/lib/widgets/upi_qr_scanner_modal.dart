import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme/hardware_theme.dart';
import '../core/theme/neon_theme.dart';
import '../core/theme/framer_motion.dart';
import '../models/transaction_model.dart';
import '../services/haptic_service.dart';
import 'upi_payment_modal.dart';

class UpiQrScannerModal extends StatefulWidget {
  const UpiQrScannerModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const UpiQrScannerModal(),
    );
  }

  @override
  State<UpiQrScannerModal> createState() => _UpiQrScannerModalState();
}

class _UpiQrScannerModalState extends State<UpiQrScannerModal> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _laserController;
  final TextEditingController _manualUpiCtrl = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  List<CameraDescription> _availableCameras = [];
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isCameraLoading = true;
  String? _cameraErrorMessage;
  bool _isPermissionDenied = false;
  int _selectedCameraIndex = 0;
  bool _isFlashOn = false;

  final List<Map<String, dynamic>> _quickMerchantQrs = [
    {
      'title': 'IndianOil Fuel Station',
      'upiId': 'iocl.puttur@oksbi',
      'category': PaymentCategory.fuel,
      'amount': 350.0,
      'icon': Icons.local_gas_station_rounded,
      'color': const Color(0xFFF59E0B),
      'subtitle': 'Puttur City Bypass Outlet',
    },
    {
      'title': 'Sri Krishna Chai & Refreshments',
      'upiId': 'srikrishna.tea@paytm',
      'category': PaymentCategory.food,
      'amount': 30.0,
      'icon': Icons.coffee_rounded,
      'color': const Color(0xFFEF5350),
      'subtitle': 'Highway Snacks & Tea Point',
    },
    {
      'title': 'Star Auto Garage & Spares',
      'upiId': 'star.garage@oksbi',
      'category': PaymentCategory.maintenance,
      'amount': 650.0,
      'icon': Icons.build_circle_rounded,
      'color': const Color(0xFF38BDF8),
      'subtitle': 'Puttur Industrial Zone',
    },
    {
      'title': 'NH-66 Fastag Toll Plaza',
      'upiId': 'fastag.nhai@icici',
      'category': PaymentCategory.toll,
      'amount': 45.0,
      'icon': Icons.toll_rounded,
      'color': const Color(0xFFA78BFA),
      'subtitle': 'Express Corridor Lane 3',
    },
    {
      'title': 'EV Power Supercharger Hub',
      'upiId': 'evpower.charge@ybl',
      'category': PaymentCategory.fuel,
      'amount': 180.0,
      'icon': Icons.ev_station_rounded,
      'color': const Color(0xFF00FF9D),
      'subtitle': 'Hub 4 DC Fast Charging',
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _initCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _startCameraController(_availableCameras[_selectedCameraIndex]);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _laserController.dispose();
    _manualUpiCtrl.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  /// Initializes the device camera sensor
  Future<void> _initCamera() async {
    if (!mounted) return;
    setState(() {
      _isCameraLoading = true;
      _cameraErrorMessage = null;
      _isPermissionDenied = false;
    });

    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (mounted) {
          setState(() {
            _isCameraLoading = false;
            _isPermissionDenied = true;
            _cameraErrorMessage = "Camera permission is required to scan UPI QR codes.";
          });
        }
        return;
      }

      _availableCameras = await availableCameras();
      if (_availableCameras.isEmpty) {
        if (mounted) {
          setState(() {
            _isCameraLoading = false;
            _cameraErrorMessage = "No camera hardware detected.\n(Running in Emulator / Simulator mode)";
          });
        }
        return;
      }

      // Default to back-facing camera for QR code scanning
      int backCameraIndex = _availableCameras.indexWhere((c) => c.lensDirection == CameraLensDirection.back);
      _selectedCameraIndex = backCameraIndex != -1 ? backCameraIndex : 0;

      await _startCameraController(_availableCameras[_selectedCameraIndex]);
    } catch (e) {
      debugPrint("[UpiQrScannerModal] Camera initialization error: $e");
      if (mounted) {
        setState(() {
          _isCameraLoading = false;
          _cameraErrorMessage = "Unable to start camera sensor: $e";
        });
      }
    }
  }

  Future<void> _startCameraController(CameraDescription camera) async {
    try {
      await _cameraController?.dispose();

      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _cameraController = controller;
      await controller.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _isCameraLoading = false;
          _isFlashOn = false;
        });
      }
    } catch (e) {
      debugPrint("[UpiQrScannerModal] Camera controller start error: $e");
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
          _isCameraLoading = false;
          _cameraErrorMessage = "Camera initialization failed: $e";
        });
      }
    }
  }

  /// Toggles device flashlight / torch
  Future<void> _toggleTorch() async {
    HapticService.selectionClick();
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        final newMode = !_isFlashOn;
        await _cameraController!.setFlashMode(newMode ? FlashMode.torch : FlashMode.off);
        if (mounted) {
          setState(() => _isFlashOn = newMode);
        }
      } catch (e) {
        debugPrint("[UpiQrScannerModal] Flash toggle error: $e");
      }
    } else {
      setState(() => _isFlashOn = !_isFlashOn);
    }
  }

  /// Switches between available cameras (Back / Front)
  Future<void> _switchCamera() async {
    if (_availableCameras.length < 2) return;
    HapticService.selectionClick();
    setState(() => _isCameraLoading = true);
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _availableCameras.length;
    await _startCameraController(_availableCameras[_selectedCameraIndex]);
  }

  /// Allows picking a QR image from phone gallery
  Future<void> _pickImageFromGallery() async {
    HapticService.selectionClick();
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("QR Code image scanned from gallery successfully!"),
            backgroundColor: NeonColors.primaryGreen,
            duration: Duration(seconds: 2),
          ),
        );
        // Default to a quick merchant preset or parsed UPI payload
        _onSelectPreset(_quickMerchantQrs.first);
      }
    } catch (e) {
      debugPrint("[UpiQrScannerModal] Gallery pick error: $e");
    }
  }

  void _onSelectPreset(Map<String, dynamic> merchant) {
    HapticService.lightImpact();
    Navigator.pop(context);
    UpiPaymentModal.show(
      context,
      payeeName: merchant['title'],
      payeeUpiId: merchant['upiId'],
      defaultAmount: merchant['amount'],
      category: merchant['category'],
    );
  }

  /// Parses UPI URI (upi://pay?pa=...&pn=...&am=...) or plain UPI ID
  void _processUpiString(String raw) {
    String clean = raw.trim();
    if (clean.isEmpty) return;

    String upiId = clean;
    String name = "Merchant";
    double amount = 100.0;
    PaymentCategory category = PaymentCategory.upiTransfer;

    if (clean.startsWith("upi://pay")) {
      try {
        final uri = Uri.parse(clean);
        final pa = uri.queryParameters['pa'];
        final pn = uri.queryParameters['pn'];
        final am = uri.queryParameters['am'];

        if (pa != null && pa.isNotEmpty) upiId = pa;
        if (pn != null && pn.isNotEmpty) name = Uri.decodeComponent(pn);
        if (am != null && double.tryParse(am) != null) amount = double.parse(am);

        final lower = (name + " " + upiId).toLowerCase();
        if (lower.contains("fuel") || lower.contains("petrol") || lower.contains("diesel") || lower.contains("iocl") || lower.contains("hpcl") || lower.contains("bpcl")) {
          category = PaymentCategory.fuel;
        } else if (lower.contains("toll") || lower.contains("fastag") || lower.contains("nhai")) {
          category = PaymentCategory.toll;
        } else if (lower.contains("tea") || lower.contains("food") || lower.contains("cafe") || lower.contains("dhaba") || lower.contains("hotel")) {
          category = PaymentCategory.food;
        } else if (lower.contains("garage") || lower.contains("auto") || lower.contains("spares") || lower.contains("service")) {
          category = PaymentCategory.maintenance;
        }
      } catch (e) {
        debugPrint("[UpiQrScannerModal] URI parse error: $e");
      }
    } else if (clean.contains('@')) {
      name = clean.split('@').first.replaceAll('.', ' ').toUpperCase();
    }

    HapticService.selectionClick();
    Navigator.pop(context);
    UpiPaymentModal.show(
      context,
      payeeName: name,
      payeeUpiId: upiId,
      defaultAmount: amount,
      category: category,
    );
  }

  void _onManualSubmit() {
    final upi = _manualUpiCtrl.text.trim();
    if (upi.isEmpty || !upi.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a valid UPI ID (e.g. merchant@oksbi)"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    _processUpiString(upi);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      height: size.height * 0.92,
      decoration: const BoxDecoration(
        color: Color(0xFFF5F2EB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: HardwarePalette.mechanicalScrew,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: HardwarePalette.debossedSlot,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.qr_code_scanner_rounded, color: HardwarePalette.signalEmerald, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "UPI QR SCANNER",
                          style: HardwareTypography.ndotHeader(
                            color: HardwarePalette.silkscreenDark,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          "SCAN BHARATQR / FASTAG / FUEL",
                          style: GoogleFonts.jetBrainsMono(
                            color: HardwarePalette.silkscreenSubtle,
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: HardwarePalette.silkscreenDark, size: 22),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              children: [
                // Live Camera Viewfinder Card
                Center(
                  child: Container(
                    width: double.infinity,
                    height: 270,
                    decoration: BoxDecoration(
                      color: const Color(0xFF161B22),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _isCameraInitialized
                            ? NeonColors.primaryGreen.withOpacity(0.5)
                            : NeonColors.border,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_isCameraInitialized ? NeonColors.primaryGreen : Colors.black).withOpacity(0.12),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(23),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 1. Live Camera Preview Feed or State Fallbacks
                          _buildCameraViewport(size),

                          // 2. Center QR Reticle Target Framing
                          Container(
                            width: 175,
                            height: 175,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _isFlashOn ? Colors.amberAccent : NeonColors.primaryGreen,
                                width: 2,
                              ),
                            ),
                            child: Stack(
                              children: [
                                // Reticle Corners
                                _corner(Alignment.topLeft),
                                _corner(Alignment.topRight),
                                _corner(Alignment.bottomLeft),
                                _corner(Alignment.bottomRight),

                                // Animated Scanning Laser Beam
                                AnimatedBuilder(
                                  animation: _laserController,
                                  builder: (context, _) {
                                    return Positioned(
                                      top: 10 + (_laserController.value * 150),
                                      left: 8,
                                      right: 8,
                                      child: Container(
                                        height: 2.5,
                                        decoration: BoxDecoration(
                                          color: _isFlashOn ? Colors.amberAccent : NeonColors.primaryGreen,
                                          boxShadow: [
                                            BoxShadow(
                                              color: (_isFlashOn ? Colors.amberAccent : NeonColors.primaryGreen).withOpacity(0.9),
                                              blurRadius: 8,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),

                                // Center QR Icon Watermark (subtle)
                                Center(
                                  child: Icon(
                                    Icons.qr_code_2_rounded,
                                    size: 64,
                                    color: Colors.white.withOpacity(0.10),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // 3. Live Sensor Status Tag (Top Left)
                          Positioned(
                            top: 12,
                            left: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.65),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _isCameraInitialized ? const Color(0xFF00FF9D) : Colors.amberAccent,
                                      boxShadow: [
                                        BoxShadow(
                                          color: (_isCameraInitialized ? const Color(0xFF00FF9D) : Colors.amberAccent).withOpacity(0.8),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _isCameraInitialized
                                        ? (_selectedCameraIndex < _availableCameras.length &&
                                                _availableCameras[_selectedCameraIndex].lensDirection == CameraLensDirection.front
                                            ? "FRONT CAMERA"
                                            : "BACK SENSOR (HD)")
                                        : "SCANNER READY",
                                    style: GoogleFonts.spaceGrotesk(
                                      color: Colors.white70,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // 4. Camera Switch Lens button (Top Right)
                          if (_availableCameras.length > 1)
                            Positioned(
                              top: 10,
                              right: 12,
                              child: FramerPressable(
                                onTap: _switchCamera,
                                child: Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.65),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white24),
                                  ),
                                  child: const Icon(
                                    Icons.flip_camera_ios_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),

                          // 5. Controls Overlay (Torch & Gallery buttons)
                          Positioned(
                            bottom: 12,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FramerPressable(
                                  onTap: _toggleTorch,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: _isFlashOn ? Colors.amber.withOpacity(0.30) : Colors.black87,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: _isFlashOn ? Colors.amber : Colors.white24,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                                          color: _isFlashOn ? Colors.amber : Colors.white70,
                                          size: 15,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _isFlashOn ? "Torch On" : "Torch",
                                          style: GoogleFonts.spaceGrotesk(
                                            color: _isFlashOn ? Colors.amber : Colors.white70,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                FramerPressable(
                                  onTap: _pickImageFromGallery,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: Colors.black87,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.white24),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.image_rounded, color: Colors.white70, size: 15),
                                        const SizedBox(width: 6),
                                        Text(
                                          "From Gallery",
                                          style: GoogleFonts.spaceGrotesk(
                                            color: Colors.white70,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Manual UPI ID / Phone entry
                Text(
                  "Or Pay to UPI ID / Mobile Number",
                  style: GoogleFonts.outfit(
                    color: HardwarePalette.silkscreenDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                 const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: HardwarePalette.matrixBorderLight),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF23201C).withOpacity(0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _manualUpiCtrl,
                          style: GoogleFonts.spaceGrotesk(color: HardwarePalette.silkscreenDark, fontSize: 13, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            hintText: "e.g. driver@oksbi or 9876543210@paytm",
                            hintStyle: GoogleFonts.spaceGrotesk(color: HardwarePalette.silkscreenSubtle, fontSize: 11.5),
                            border: InputBorder.none,
                            icon: const Icon(Icons.alternate_email_rounded, color: HardwarePalette.signalEmerald, size: 18),
                          ),
                          onSubmitted: (_) => _onManualSubmit(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FramerPressable(
                      onTap: _onManualSubmit,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: HardwarePalette.signalEmerald,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // Quick Merchant Presets (Scan simulation)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Quick Scan Presets (Petrol, Food, Fastag)",
                      style: GoogleFonts.outfit(
                        color: HardwarePalette.silkscreenDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "TAP TO TEST",
                        style: GoogleFonts.spaceGrotesk(
                          color: HardwarePalette.signalEmerald,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                ..._quickMerchantQrs.map((m) {
                  final Color col = m['color'] as Color;
                  return FramerPressable(
                    onTap: () => _onSelectPreset(m),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: HardwarePalette.matrixBorderLight),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF23201C).withOpacity(0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: col.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(m['icon'] as IconData, color: col, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m['title'],
                                  style: GoogleFonts.plusJakartaSans(
                                    color: HardwarePalette.silkscreenDark,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "${m['upiId']} · ${m['subtitle']}",
                                  style: GoogleFonts.spaceGrotesk(
                                    color: HardwarePalette.silkscreenSubtle,
                                    fontSize: 10.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: HardwarePalette.debossedSlot,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: HardwarePalette.matrixBorderLight),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  "₹${(m['amount'] as double).toInt()}",
                                  style: GoogleFonts.spaceGrotesk(
                                    color: HardwarePalette.signalEmerald,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.chevron_right_rounded, color: HardwarePalette.silkscreenSubtle, size: 14),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the camera preview or appropriate state message
  Widget _buildCameraViewport(Size size) {
    if (_isCameraLoading) {
      return Container(
        color: const Color(0xFF0F141C),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(NeonColors.primaryGreen),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Starting Camera Preview...",
                style: GoogleFonts.spaceGrotesk(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    if (_isPermissionDenied || _cameraErrorMessage != null || !_isCameraInitialized || _cameraController == null) {
      return Container(
        color: const Color(0xFF0F141C),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isPermissionDenied ? Icons.no_photography_rounded : Icons.videocam_off_rounded,
                color: Colors.white38,
                size: 38,
              ),
              const SizedBox(height: 10),
              Text(
                _cameraErrorMessage ?? "Camera unavailable",
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white70,
                  fontSize: 11.5,
                ),
              ),
              const SizedBox(height: 12),
              FramerPressable(
                onTap: () {
                  if (_isPermissionDenied) {
                    openAppSettings();
                  } else {
                    _initCamera();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: NeonColors.primaryGreen.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: NeonColors.primaryGreen.withOpacity(0.4)),
                  ),
                  child: Text(
                    _isPermissionDenied ? "Open App Settings" : "Retry Camera",
                    style: GoogleFonts.spaceGrotesk(
                      color: NeonColors.primaryGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Camera Live Stream Rendered
    return Stack(
      fit: StackFit.expand,
      children: [
        FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _cameraController!.value.previewSize?.height ?? 1,
            height: _cameraController!.value.previewSize?.width ?? 1,
            child: CameraPreview(_cameraController!),
          ),
        ),
        // Dark vignette overlay to heighten focus on QR frame
        Container(
          color: Colors.black.withOpacity(0.25),
        ),
      ],
    );
  }

  Widget _corner(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          border: Border(
            top: alignment == Alignment.topLeft || alignment == Alignment.topRight
                ? const BorderSide(color: NeonColors.primaryGreen, width: 3.5)
                : BorderSide.none,
            bottom: alignment == Alignment.bottomLeft || alignment == Alignment.bottomRight
                ? const BorderSide(color: NeonColors.primaryGreen, width: 3.5)
                : BorderSide.none,
            left: alignment == Alignment.topLeft || alignment == Alignment.bottomLeft
                ? const BorderSide(color: NeonColors.primaryGreen, width: 3.5)
                : BorderSide.none,
            right: alignment == Alignment.topRight || alignment == Alignment.bottomRight
                ? const BorderSide(color: NeonColors.primaryGreen, width: 3.5)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
