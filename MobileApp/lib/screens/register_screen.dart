import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../routes/app_routes.dart';
import '../core/constants/app_colors.dart';
import '../services/api_service.dart';

// ── Background blob painter (reused from login) ──────────────────────────────
class _BlobPainter extends CustomPainter {
  final double t;
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

// ── Underline glow input ─────────────────────────────────────────────────────
class _GlowField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final TextCapitalization textCapitalization;

  const _GlowField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  State<_GlowField> createState() => _GlowFieldState();
}

class _GlowFieldState extends State<_GlowField>
    with SingleTickerProviderStateMixin {
  bool _focused = false;
  bool _obscured = true;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscure;
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.primary;
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
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
          textCapitalization: widget.textCapitalization,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15),
          validator: widget.validator,
          decoration: InputDecoration(
            labelText: widget.label,
            labelStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontSize: 13,
            ),
            prefixIcon: Icon(widget.icon,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), size: 20),
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
            errorStyle: const TextStyle(color: Color(0xFFFF6E6E), fontSize: 11),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          ),
        ),
      ),
    );
  }
}

// ── Chip selector row ────────────────────────────────────────────────────────
class _ChipRow extends StatelessWidget {
  final List<String> items;
  final String selected;
  final ValueChanged<String> onSelect;

  const _ChipRow({
    required this.items,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.primary;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final sel = item == selected;
        return GestureDetector(
          onTap: () => onSelect(item),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: sel
                  ? accent.withOpacity(0.12)
                  : AppColors.divider,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: sel ? accent : AppColors.border,
                width: sel ? 1.5 : 1,
              ),
            ),
            child: Text(
              item,
              style: TextStyle(
                color: sel ? accent : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Gradient CTA button ──────────────────────────────────────────────────────
class _GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool loading;

  const _GradientButton(
      {required this.label, required this.onTap, this.loading = false});

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
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
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
          if (!widget.loading) widget.onTap();
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
            child: widget.loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                : Text(
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

// ── Register Screen ──────────────────────────────────────────────────────────
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  late AnimationController _blobCtrl;
  late AnimationController _stepCtrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  int _step = 0; // 0..3
  final int _totalSteps = 4;
  bool _registering = false;

  // Step 1 – Identity
  final _step1Key = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _driverIdCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _pw2Ctrl = TextEditingController();

  // Step 2 – Fleet
  final _step2Key = GlobalKey<FormState>();
  final _companyCtrl = TextEditingController();
  final _managerEmailCtrl = TextEditingController();

  // Step 3 – Vehicle
  final _step3Key = GlobalKey<FormState>();
  String _vehicleType = 'Van';
  final _vehicleNameCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  final List<String> _vehicleTypes = [
    'Scooty',
    'Motorcycle',
    'Car',
    'Van',
    'Truck',
    'Pickup',
  ];

  // Step 4 – Industry
  final _step4Key = GlobalKey<FormState>();
  String _industry = 'Logistics';
  final List<String> _industries = [
    'Food Delivery',
    'Courier',
    'Logistics',
    'Ride Sharing',
    'Enterprise Fleet',
  ];

  @override
  void initState() {
    super.initState();
    _blobCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _stepCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _stepCtrl, curve: Curves.easeOutCubic));
    _fadeAnim = CurvedAnimation(parent: _stepCtrl, curve: Curves.easeOut);
    _stepCtrl.forward();
  }

  @override
  void dispose() {
    _blobCtrl.dispose();
    _stepCtrl.dispose();
    _nameCtrl.dispose();
    _driverIdCtrl.dispose();
    _pwCtrl.dispose();
    _pw2Ctrl.dispose();
    _companyCtrl.dispose();
    _managerEmailCtrl.dispose();
    _vehicleNameCtrl.dispose();
    _plateCtrl.dispose();
    super.dispose();
  }

  void _animateToNextStep(int next) {
    _stepCtrl.reset();
    setState(() => _step = next);
    _stepCtrl.forward();
  }

  void _nextStep() {
    bool valid = false;
    switch (_step) {
      case 0:
        valid = _step1Key.currentState?.validate() ?? false;
        break;
      case 1:
        valid = _step2Key.currentState?.validate() ?? false;
        break;
      case 2:
        valid = _step3Key.currentState?.validate() ?? false;
        break;
      case 3:
        valid = true;
        break;
    }
    if (!valid) return;
    if (_step < _totalSteps - 1) {
      _animateToNextStep(_step + 1);
    } else {
      _handleRegister();
    }
  }

  Future<void> _handleRegister() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    setState(() => _registering = true);

    final String driverId = _driverIdCtrl.text.trim();
    final String email = '$driverId@acmelogistics.com';

    final List<String> nameParts = _nameCtrl.text.trim().split(' ');
    final String firstName = nameParts.isNotEmpty ? nameParts[0] : 'Driver';
    final String lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : 'User';

    // Register user first
    final regSuccess = await ApiService.register(
      email: email,
      password: _pwCtrl.text,
      firstName: firstName,
      lastName: lastName,
      licenseNumber: 'DL-${math.Random().nextInt(900000) + 100000}',
      licenseExpiry: '2030-12-31',
      emergencyContactName: 'Fleet HQ',
      emergencyContactPhone: '+919999999999',
    );

    if (!regSuccess) {
      setState(() => _registering = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Registration failed. Username might be taken.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    // Login and complete onboarding
    final loginSuccess = await auth.login('FLEET', driverId, _pwCtrl.text);
    setState(() => _registering = false);

    if (loginSuccess) {
      await auth.completeOnboarding(
        name: _nameCtrl.text.trim(),
        industry: _industry,
        vehicleType: _vehicleType,
        vehicleName: _vehicleNameCtrl.text.trim(),
        vehiclePlateNumber: _plateCtrl.text.trim().toUpperCase(),
        companyCode: _companyCtrl.text.trim().toUpperCase(),
      );
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Login failed after registration.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  static const _stepTitles = [
    'Your Identity',
    'Fleet Details',
    'Your Vehicle',
    'Industry & Done',
  ];

  static const _stepSubs = [
    'Set up your driver credentials',
    'Connect to your fleet company',
    'Tell us what you drive',
    'Almost there — pick your domain',
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final accent = AppColors.primary;
    final bg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bg,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Animated background blobs
          AnimatedBuilder(
            animation: _blobCtrl,
            builder: (_, __) => CustomPaint(
              painter: _BlobPainter(_blobCtrl.value),
              size: size,
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top bar ──────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (_step > 0) {
                            _animateToNextStep(_step - 1);
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.divider,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.arrow_back_rounded,
                              color: AppColors.textPrimary, size: 20),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Step ${_step + 1} of $_totalSteps',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Progress bar ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_step + 1) / _totalSteps,
                      backgroundColor: AppColors.divider,
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                      minHeight: 3,
                    ),
                  ),
                ),

                // ── Step content ─────────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 32, 28, 40),
                    child: SlideTransition(
                      position: _slideAnim,
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Step heading
                            Text(
                              _stepTitles[_step],
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _stepSubs[_step],
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.45),
                              ),
                            ),
                            const SizedBox(height: 36),

                            // Step body
                            _buildStepBody(),

                            const SizedBox(height: 40),

                            // CTA
                            Consumer<AuthProvider>(
                              builder: (_, auth, __) => _GradientButton(
                                label: _step == _totalSteps - 1
                                    ? 'Create Account'
                                    : 'Continue',
                                loading: _registering || auth.isLoading,
                                onTap: _nextStep,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepBody() {
    switch (_step) {
      case 0:
        return Form(
          key: _step1Key,
          child: Column(
            children: [
              _GlowField(
                controller: _nameCtrl,
                label: 'Full Name',
                icon: Icons.person_outline_rounded,
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter your full name' : null,
              ),
              const SizedBox(height: 20),
              _GlowField(
                controller: _driverIdCtrl,
                label: 'Driver ID / Username',
                icon: Icons.badge_outlined,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Choose a Driver ID' : null,
              ),
              const SizedBox(height: 20),
              _GlowField(
                controller: _pwCtrl,
                label: 'Password',
                icon: Icons.lock_outline_rounded,
                obscure: true,
                validator: (v) => v == null || v.length < 6
                    ? 'Minimum 6 characters'
                    : null,
              ),
              const SizedBox(height: 20),
              _GlowField(
                controller: _pw2Ctrl,
                label: 'Confirm Password',
                icon: Icons.lock_outline_rounded,
                obscure: true,
                validator: (v) => v != _pwCtrl.text
                    ? 'Passwords do not match'
                    : null,
              ),
            ],
          ),
        );

      case 1:
        return Form(
          key: _step2Key,
          child: Column(
            children: [
              _GlowField(
                controller: _companyCtrl,
                label: 'Fleet Company Code',
                icon: Icons.business_outlined,
                textCapitalization: TextCapitalization.characters,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter fleet code' : null,
              ),
              const SizedBox(height: 20),
              _GlowField(
                controller: _managerEmailCtrl,
                label: 'Fleet Manager Email (optional)',
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 28),
              _InfoTile(
                icon: Icons.info_outline_rounded,
                text:
                    'Your Fleet Company Code is provided by your dispatch manager. It links your account to your company fleet.',
              ),
            ],
          ),
        );

      case 2:
        return Form(
          key: _step3Key,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'VEHICLE TYPE',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              _ChipRow(
                items: _vehicleTypes,
                selected: _vehicleType,
                onSelect: (v) => setState(() => _vehicleType = v),
              ),
              const SizedBox(height: 28),
              _GlowField(
                controller: _vehicleNameCtrl,
                label: 'Vehicle Name / Model',
                icon: Icons.directions_car_outlined,
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter vehicle name' : null,
              ),
              const SizedBox(height: 20),
              _GlowField(
                controller: _plateCtrl,
                label: 'License Plate Number',
                icon: Icons.credit_card_outlined,
                textCapitalization: TextCapitalization.characters,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter plate number' : null,
              ),
            ],
          ),
        );

      case 3:
      default:
        return Form(
          key: _step4Key,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'INDUSTRY DOMAIN',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              _ChipRow(
                items: _industries,
                selected: _industry,
                onSelect: (v) => setState(() => _industry = v),
              ),
              const SizedBox(height: 36),
              // Summary card
              const Text(
                'ACCOUNT SUMMARY',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              _SummaryCard(
                rows: [
                  _SummaryRow('Name', _nameCtrl.text),
                  _SummaryRow('Driver ID', _driverIdCtrl.text),
                  _SummaryRow('Fleet Code', _companyCtrl.text.toUpperCase()),
                  _SummaryRow('Vehicle', '$_vehicleType — ${_vehicleNameCtrl.text}'),
                  _SummaryRow('Plate', _plateCtrl.text.toUpperCase()),
                  _SummaryRow('Industry', _industry),
                ],
              ),
            ],
          ),
        );
    }
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoTile({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textMuted, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow {
  final String label;
  final String value;
  const _SummaryRow(this.label, this.value);
}

class _SummaryCard extends StatelessWidget {
  final List<_SummaryRow> rows;
  const _SummaryCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: rows.map((r) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 90,
                  child: Text(
                    r.label,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 11),
                  ),
                ),
                Expanded(
                  child: Text(
                    r.value.isNotEmpty ? r.value : '—',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
