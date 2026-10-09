import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import '../models/order_model.dart';
import '../core/theme/hardware_theme.dart';
import '../core/theme/framer_motion.dart';
import '../services/haptic_service.dart';

/// Draggable Floating Delivery Bubble Widget that hovers on screen
/// displaying live mission details, customer contact, and delivery OTP.
class FloatingDeliveryBubble extends StatefulWidget {
  final DeliveryOrder order;
  final VoidCallback? onReturnToApp;
  final VoidCallback? onClose;
  final double currentSpeed;
  final double safetyScore;

  const FloatingDeliveryBubble({
    super.key,
    required this.order,
    this.onReturnToApp,
    this.onClose,
    this.currentSpeed = 0.0,
    this.safetyScore = 95.0,
  });

  @override
  State<FloatingDeliveryBubble> createState() => _FloatingDeliveryBubbleState();
}

class _FloatingDeliveryBubbleState extends State<FloatingDeliveryBubble> {
  bool _isExpanded = false;
  Offset _position = const Offset(16, 120);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Positioned(
      left: _position.dx.clamp(8.0, screenSize.width - (_isExpanded ? 320.0 : 160.0)),
      top: _position.dy.clamp(40.0, screenSize.height - (_isExpanded ? 260.0 : 80.0)),
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _position += details.delta;
          });
        },
        child: Material(
          color: Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            width: _isExpanded ? 310 : 150,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withOpacity(0.95),
              borderRadius: BorderRadius.circular(_isExpanded ? 20 : 30),
              border: Border.all(
                color: const Color(0xFF38BDF8),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF38BDF8).withOpacity(0.3),
                  blurRadius: 16,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _isExpanded ? _buildExpandedCard() : _buildCollapsedPill(),
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // COLLAPSED COMPACT PILL
  // ----------------------------------------------------
  Widget _buildCollapsedPill() {
    return InkWell(
      onTap: () {
        HapticService.selectionClick();
        setState(() => _isExpanded = true);
      },
      borderRadius: BorderRadius.circular(30),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: Color(0xFF0284C7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "OTP: ${widget.order.verificationOtp}",
                    style: GoogleFonts.spaceGrotesk(
                      color: const Color(0xFF38BDF8),
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    "₹${widget.order.payoutAmount.toInt()} · TAP",
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white70,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // EXPANDED TACTICAL CARD
  // ----------------------------------------------------
  Widget _buildExpandedCard() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withOpacity(0.25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF38BDF8)),
                    ),
                    child: const Icon(Icons.local_shipping_rounded, color: Color(0xFF38BDF8), size: 16),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "MISSION #${widget.order.id}",
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        "₹${widget.order.payoutAmount.toInt()} Payout",
                        style: GoogleFonts.spaceGrotesk(
                          color: const Color(0xFF10B981),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  HapticService.selectionClick();
                  setState(() => _isExpanded = false);
                },
                icon: const Icon(Icons.close_fullscreen_rounded, color: Colors.white60, size: 16),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Drop Address
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded, color: Color(0xFFF43F5E), size: 15),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.order.dropAddress,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // OTP Code & Client Call Row
          Row(
            children: [
              // OTP Badge
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.key_rounded, color: Color(0xFF38BDF8), size: 13),
                      const SizedBox(width: 6),
                      Text(
                        "OTP: ${widget.order.verificationOtp}",
                        style: GoogleFonts.spaceGrotesk(
                          color: const Color(0xFF38BDF8),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Call Customer Button
              FramerPressable(
                onTap: () async {
                  HapticService.mediumImpact();
                  final phoneUri = Uri.parse("tel:${widget.order.customerPhone}");
                  if (await url_launcher.canLaunchUrl(phoneUri)) {
                    await url_launcher.launchUrl(phoneUri);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.call_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        "CALL",
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Return to App CTA
          SizedBox(
            width: double.infinity,
            height: 36,
            child: ElevatedButton(
              onPressed: () {
                HapticService.selectionClick();
                widget.onReturnToApp?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: EdgeInsets.zero,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.open_in_browser_rounded, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    "OPEN IN-APP DASHBOARD",
                    style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
