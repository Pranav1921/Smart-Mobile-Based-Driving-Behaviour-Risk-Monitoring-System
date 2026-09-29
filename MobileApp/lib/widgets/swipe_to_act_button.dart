import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_app/core/theme/neon_theme.dart';
import 'package:mobile_app/services/haptic_service.dart';

class SwipeToActButton extends StatefulWidget {
  final String label;
  final VoidCallback onCompleted;
  final Color backgroundColor;
  final Color thumbColor;
  final Color textColor;
  final IconData icon;
  final double height;

  const SwipeToActButton({
    super.key,
    required this.label,
    required this.onCompleted,
    this.backgroundColor = const Color(0xFF1E293B),
    this.thumbColor = NeonColors.primaryGreen,
    this.textColor = Colors.white,
    this.icon = Icons.chevron_right_rounded,
    this.height = 52.0,
  });

  @override
  State<SwipeToActButton> createState() => _SwipeToActButtonState();
}

class _SwipeToActButtonState extends State<SwipeToActButton> with SingleTickerProviderStateMixin {
  double _dragPosition = 0.0;
  bool _isCompleted = false;
  late AnimationController _resetController;
  late Animation<double> _resetAnimation;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details, double maxDrag) {
    if (_isCompleted) return;
    setState(() {
      _dragPosition = (_dragPosition + details.delta.dx).clamp(0.0, maxDrag);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details, double maxDrag) {
    if (_isCompleted) return;

    final velocity = details.primaryVelocity ?? 0.0;
    if (_dragPosition >= maxDrag * 0.45 || velocity > 120.0) {
      // Completed successfully
      setState(() {
        _dragPosition = maxDrag;
        _isCompleted = true;
      });
      HapticService.success();
      widget.onCompleted();

      // Reset after short delay
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            _dragPosition = 0.0;
            _isCompleted = false;
          });
        }
      });
    } else {
      // Snap back with spring animation
      HapticService.lightImpact();
      _resetAnimation = Tween<double>(begin: _dragPosition, end: 0.0).animate(
        CurvedAnimation(parent: _resetController, curve: Curves.easeOutCubic),
      )..addListener(() {
          setState(() {
            _dragPosition = _resetAnimation.value;
          });
        });
      _resetController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final thumbWidth = widget.height - 8.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxDrag = constraints.maxWidth - thumbWidth - 8.0;

        return Container(
          height: widget.height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFE2DFDC),
            borderRadius: BorderRadius.circular(widget.height / 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Direction Arrow / Label Background Track
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isCompleted ? "INITIALIZED" : widget.label.toUpperCase(),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: _isCompleted ? const Color(0xFFFF5722) : const Color(0xFF8E8883),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Draggable Slider Thumb
              Positioned(
                left: 4.0 + _dragPosition,
                child: GestureDetector(
                  onTap: () {
                    _onHorizontalDragEnd(DragEndDetails(velocity: const Velocity(pixelsPerSecond: Offset(300, 0))), maxDrag);
                  },
                  onHorizontalDragUpdate: (details) => _onHorizontalDragUpdate(details, maxDrag),
                  onHorizontalDragEnd: (details) => _onHorizontalDragEnd(details, maxDrag),
                  child: Container(
                    width: thumbWidth,
                    height: widget.height - 8.0,
                    decoration: BoxDecoration(
                      color: _isCompleted ? const Color(0xFFFF5722) : const Color(0xFF443F3C),
                      borderRadius: BorderRadius.circular((widget.height - 8.0) / 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF23201C).withOpacity(0.12),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        _isCompleted ? Icons.check_rounded : (widget.icon == Icons.chevron_right_rounded ? Icons.play_arrow_rounded : widget.icon),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
