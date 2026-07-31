import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../routes/app_routes.dart';
import '../core/constants/app_colors.dart';

// ── Animated background blob painter ────────────────────────────────────────
class _BlobPainter extends CustomPainter {
  final double t; // animation progress 0..1
  _BlobPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final shapePaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 4; i++) {
      // 4 large drifting space nebulas
      final double seedX = (i == 0) ? 0.15 : (i == 1) ? 0.85 : (i == 2) ? 0.25 : 0.75;
      final double seedY = (i == 0) ? 0.15 : (i == 1) ? 0.30 : (i == 2) ? 0.70 : 0.85;
      
      final double px = (seedX * w + math.sin(t * 2 * math.pi + i) * 35) % w;
      final double py = (seedY * h + math.cos(t * 2 * math.pi + i) * 35) % h;
      
      final double sizeVal = 160.0 + 80.0 * math.sin(t * math.pi + i).abs();
      
      final Color color = (i == 0 || i == 3)
          ? AppColors.primary.withOpacity(0.06)
          : AppColors.secondary.withOpacity(0.05);
          
      shapePaint.color = color;
      shapePaint.maskFilter = MaskFilter.blur(BlurStyle.normal, sizeVal * 0.5);

      canvas.drawCircle(Offset(px, py), sizeVal, shapePaint);
    }
  }

  @override
  bool shouldRepaint(_BlobPainter old) => old.t != t;
}

// ── Animated underline text field ────────────────────────────────────────────
class _GlowField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _GlowField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  State<_GlowField> createState() => _GlowFieldState();
}

class _GlowFieldState extends State<_GlowField>
    with SingleTickerProviderStateMixin {
  late AnimationController _ac;
  bool _focused = false;
  bool _obscured = true;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscure;
    _ac = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.primary;
    return Focus(
      onFocusChange: (f) {
        setState(() => _focused = f);
        if (f) {
          _ac.forward();
        } else {
          _ac.reverse();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _focused ? AppColors.primary : Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
            width: 1.0,
          ),
          boxShadow: _focused ? [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.12),
              offset: const Offset(0, 4),
              blurRadius: 16,
              spreadRadius: 0,
            ),
          ] : null,
        ),
        child: TextFormField(
          controller: widget.controller,
          obscureText: widget.obscure ? _obscured : false,
          keyboardType: widget.keyboardType,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          validator: widget.validator,
          decoration: InputDecoration(
            labelText: widget.label,
            labelStyle: TextStyle(
              color: _focused ? accent : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
            prefixIcon: Icon(widget.icon,
                color: _focused ? accent : Theme.of(context).colorScheme.onSurface.withOpacity(0.4), size: 20),
            suffixIcon: widget.obscure
                ? IconButton(
                    icon: Icon(
                      _obscured
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                      size: 18,
                    ),
                    onPressed: () => setState(() => _obscured = !_obscured),
                  )
                : null,
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            errorStyle: const TextStyle(color: AppColors.error, fontSize: 11),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          ),
        ),
      ),
    );
  }
}

// ── Main Login Screen ────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _blobCtrl;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  final _loginFormKey = GlobalKey<FormState>();
  final _idCtrl = TextEditingController(text: 'driver1@acmelogistics.com');
  final _pwCtrl = TextEditingController(text: 'FleetGuard2026!');

  bool _isLoginMode = true; // true = Login tab, false = Register hint

  @override
  void initState() {
    super.initState();
    _blobCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim =
        CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _blobCtrl.dispose();
    _fadeCtrl.dispose();
    _idCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    // Use driver ID as both company code placeholder and driver ID for simple login
    final success = await auth.login('FLEET', _idCtrl.text.trim(), _pwCtrl.text);
    if (!mounted) return;
    if (success) {
      if (auth.profile.isOnboarded) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.register);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Invalid credentials. Please try again.'),
          backgroundColor: const Color(0xFFFF5252),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final size = MediaQuery.of(context).size;
    final accent = AppColors.primary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ── Animated blob background ──────────────────────────────────────
          AnimatedBuilder(
            animation: _blobCtrl,
            builder: (context, _) => CustomPaint(
              painter: _BlobPainter(_blobCtrl.value),
              size: size,
            ),
          ),

          // ── Content ───────────────────────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                    28, size.height * 0.06, 28, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo area
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: accent.withOpacity(0.5), width: 1.5),
                              color: accent.withOpacity(0.07),
                            ),
                            child: Icon(Icons.local_shipping_outlined,
                                color: accent, size: 26),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'FLEETGUARD COMMAND',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Glowing neon horizontal line
                          Container(
                            width: 80,
                            height: 2,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, AppColors.secondary],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.5),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Enterprise Driving Analytics Platform',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: size.height * 0.05),

                    // ── Login form ───────────────────────────────────────────
                    Text(
                      'Welcome back',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sign in to your driver account',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 36),
                    Form(
                      key: _loginFormKey,
                      child: Column(
                        children: [
                          _GlowField(
                            controller: _idCtrl,
                            label: 'Driver ID or Email',
                            icon: Icons.person_outline_rounded,
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Enter your Driver ID' : null,
                          ),
                          const SizedBox(height: 20),
                          _GlowField(
                            controller: _pwCtrl,
                            label: 'Password',
                            icon: Icons.lock_outline_rounded,
                            obscure: true,
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Enter your password' : null,
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                  'Forgot password?',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                  ),
                                ),
                            ),
                          ),
                          const SizedBox(height: 36),
                          // Sign in button
                          auth.isLoading
                              ? SizedBox(
                                  height: 52,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                        color: accent, strokeWidth: 2),
                                  ),
                                )
                              : _GradientButton(
                                  label: 'Sign In',
                                  onTap: _handleLogin,
                                ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Don't have an account?  ",
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                fontSize: 12),
                          ),
                          GestureDetector(
                            onTap: () =>
                                Navigator.pushNamed(context, AppRoutes.register),
                            child: Text(
                              'Register',
                              style: TextStyle(
                                color: accent,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
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
        ],
      ),
    );
  }
}

// ── Tab button ───────────────────────────────────────────────────────────────
class _TabBtn extends StatelessWidget {
  final String label;
  final bool active;
  final Color accent;
  final VoidCallback onTap;

  const _TabBtn({
    required this.label,
    required this.active,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? accent : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
            color: active ? Colors.white : Colors.white38,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

// ── Gradient CTA button ──────────────────────────────────────────────────────
class _GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _GradientButton({required this.label, required this.onTap});

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                offset: const Offset(0, 6),
                blurRadius: 20,
                spreadRadius: -2,
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
      ),
    );
  }
}