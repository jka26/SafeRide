import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../models/student_model.dart';
import 'dashboard/dashboard_screen.dart';

class OnboardingStep2Screen extends StatefulWidget {
  final String fullName;
  final String phone;

  const OnboardingStep2Screen({
    super.key,
    required this.fullName,
    required this.phone,
  });

  @override
  State<OnboardingStep2Screen> createState() => _OnboardingStep2ScreenState();
}

class _OnboardingStep2ScreenState extends State<OnboardingStep2Screen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  final _formKey = GlobalKey<FormState>();

  // Driver fields
  final _busNumberCtrl = TextEditingController();
  final _routeNameCtrl = TextEditingController();
  final _driverEmergencyNameCtrl = TextEditingController();
  final _driverEmergencyPhoneCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _busNumberCtrl.dispose();
    _routeNameCtrl.dispose();
    _driverEmergencyNameCtrl.dispose();
    _driverEmergencyPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final onboarding = context.read<OnboardingProvider>();

    await onboarding.submitDriverDetails(
      fullName: widget.fullName,
      phone: widget.phone,
      busNumber: _busNumberCtrl.text.trim(),
      routeName: _routeNameCtrl.text.trim(),
      emergencyContactName: _driverEmergencyNameCtrl.text.trim(),
      emergencyContactPhone: _driverEmergencyPhoneCtrl.text.trim(),
    );

    if (onboarding.isSuccess && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (route) => false,
      );
    }
  }

  void _goToDashboard() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().selectedRole;
    final isDriver = role?.name == 'driver';
    final onboarding = context.watch<OnboardingProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D2B55), Color(0xFF1A4080)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: SlideTransition(
              position: _slideUp,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ───────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Step indicator + back
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(children: [
                              _StepDot(active: false),
                              const SizedBox(width: 6),
                              _StepDot(active: true),
                              const SizedBox(width: 12),
                              Text('Step 2 of 2',
                                style: TextStyle(fontFamily: 'Outfit',
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.5))),
                            ]),
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.arrow_back_rounded,
                                  color: Colors.white, size: 16),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          isDriver
                              ? 'DRIVER DETAILS'
                              : 'CHILD DETAILS',
                          style: TextStyle(fontFamily: 'Outfit', fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withOpacity(0.5),
                            letterSpacing: 1.5)),
                        const SizedBox(height: 6),
                        Text(
                          isDriver
                              ? 'Your route\ninformation'
                              : 'About your\nchild',
                          style: const TextStyle(fontFamily: 'Outfit',
                            fontSize: 28, fontWeight: FontWeight.bold,
                            color: Colors.white, letterSpacing: -0.5,
                            height: 1.15)),
                        const SizedBox(height: 8),
                        Text(
                          isDriver
                              ? 'This helps us assign you to the correct route and bus.'
                              : 'This helps us track your child and send you the right alerts.',
                          style: TextStyle(fontFamily: 'Outfit', fontSize: 13,
                            color: Colors.white.withOpacity(0.5))),
                      ],
                    ),
                  ),

                  // ── White card body ───────────────────────
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(28),
                          topRight: Radius.circular(28),
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Render fields based on role
                              if (isDriver) ...[
                                _DriverFields(
                                  busNumberCtrl: _busNumberCtrl,
                                  routeNameCtrl: _routeNameCtrl,
                                  emergencyNameCtrl: _driverEmergencyNameCtrl,
                                  emergencyPhoneCtrl: _driverEmergencyPhoneCtrl,
                                ),

                                // Error banner (driver only)
                                if (onboarding.errorMessage != null) ...[
                                  const SizedBox(height: 16),
                                  _ErrorBanner(message: onboarding.errorMessage!),
                                ],

                                const SizedBox(height: 32),

                                _SubmitButton(
                                  isLoading: onboarding.isLoading,
                                  onTap: _handleSubmit,
                                ),

                                const SizedBox(height: 20),

                                Center(
                                  child: Text(
                                    'You can update these details later in your profile',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontFamily: 'Outfit',
                                      fontSize: 12, color: AppColors.textHint),
                                  ),
                                ),
                              ] else
                                _ParentSearchSection(onLinked: _goToDashboard),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Parent search section ─────────────────────────────────────────────────────

class _ParentSearchSection extends StatefulWidget {
  final VoidCallback onLinked;
  const _ParentSearchSection({required this.onLinked});

  @override
  State<_ParentSearchSection> createState() => _ParentSearchSectionState();
}

class _ParentSearchSectionState extends State<_ParentSearchSection> {
  final _codeCtrl = TextEditingController();

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onboarding = context.watch<OnboardingProvider>();
    final result = onboarding.searchResult;

    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Phase 1: code input ──────────────────────────────
          const _FieldLabel(label: 'Student code'),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _codeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    letterSpacing: 1.5,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. SR-001',
                    hintStyle: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14,
                      color: AppColors.textHint,
                      letterSpacing: 0,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.tag_rounded,
                        size: 18, color: AppColors.textSecondary),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 18),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.divider)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.divider)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.primaryLight, width: 2)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: onboarding.isSearching
                      ? null
                      : () {
                          final code = _codeCtrl.text.trim();
                          if (code.isEmpty) return;
                          context
                              .read<OnboardingProvider>()
                              .searchStudent(code);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    elevation: 0,
                  ),
                  child: onboarding.isSearching
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Search',
                          style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Ask your school admin for the student code',
            style: TextStyle(fontFamily: 'Outfit', fontSize: 12, color: AppColors.textHint),
          ),

          // ── Search error ─────────────────────────────────────
          if (onboarding.searchStatus == SearchStatus.error &&
              onboarding.searchError != null) ...[
            const SizedBox(height: 16),
            _ErrorBanner(message: onboarding.searchError!),
          ],

          // ── Phase 2: result card + link button ───────────────
          if (result != null) ...[
            const SizedBox(height: 20),
            _StudentResultCard(student: result),
            const SizedBox(height: 20),
            _LinkButton(
              isLoading: onboarding.isLoading,
              onTap: () async {
                final provider = context.read<OnboardingProvider>();
                await provider.linkStudent(result.id);
                if (provider.isSuccess && context.mounted) {
                  widget.onLinked();
                }
              },
            ),
            if (onboarding.errorMessage != null) ...[
              const SizedBox(height: 16),
              _ErrorBanner(message: onboarding.errorMessage!),
            ],
          ],
        ],
      ),
    );
  }
}

// ── Student result card ───────────────────────────────────────────────────────

class _StudentResultCard extends StatelessWidget {
  final StudentSearchResult student;
  const _StudentResultCard({required this.student});

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      student.grade,
      if (student.routeName != null) student.routeName!,
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A4080).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1A4080).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.child_care_rounded,
                color: AppColors.primaryLight, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.fullName,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  student.studentCode,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textHint,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded,
              color: AppColors.secondary, size: 22),
        ],
      ),
    );
  }
}

// ── Link button ───────────────────────────────────────────────────────────────

class _LinkButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onTap;
  const _LinkButton({required this.isLoading, required this.onTap});

  @override
  State<_LinkButton> createState() => _LinkButtonState();
}

class _LinkButtonState extends State<_LinkButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        if (!widget.isLoading) widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: AppColors.primaryDark, strokeWidth: 2.5))
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.link_rounded,
                          color: AppColors.primaryDark, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Link my child',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Driver fields ─────────────────────────────────────────────────────────────

class _DriverFields extends StatelessWidget {
  final TextEditingController busNumberCtrl;
  final TextEditingController routeNameCtrl;
  final TextEditingController emergencyNameCtrl;
  final TextEditingController emergencyPhoneCtrl;

  const _DriverFields({
    required this.busNumberCtrl,
    required this.routeNameCtrl,
    required this.emergencyNameCtrl,
    required this.emergencyPhoneCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel(label: 'Bus number'),
        const SizedBox(height: 6),
        _InputField(
          controller: busNumberCtrl,
          hint: 'e.g. B-42',
          icon: Icons.directions_bus_rounded,
          validator: (v) => v == null || v.trim().isEmpty
              ? 'Bus number is required' : null,
        ),

        const SizedBox(height: 16),

        const _FieldLabel(label: 'Route name'),
        const SizedBox(height: 6),
        _InputField(
          controller: routeNameCtrl,
          hint: 'e.g. Route North',
          icon: Icons.route_rounded,
          validator: (v) => v == null || v.trim().isEmpty
              ? 'Route name is required' : null,
        ),

        const SizedBox(height: 24),

        // Emergency contact section
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.error.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [
                Icon(Icons.emergency_rounded, color: AppColors.error, size: 16),
                SizedBox(width: 6),
                Text('Emergency Contact',
                  style: TextStyle(fontFamily: 'Outfit', fontSize: 13,
                    fontWeight: FontWeight.w700, color: AppColors.error)),
              ]),
              const SizedBox(height: 12),
              const _FieldLabel(label: 'Contact name'),
              const SizedBox(height: 6),
              _InputField(
                controller: emergencyNameCtrl,
                hint: 'e.g. James Davis',
                icon: Icons.person_outline_rounded,
                keyboardType: TextInputType.name,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Emergency contact name is required' : null,
              ),
              const SizedBox(height: 12),
              const _FieldLabel(label: 'Contact phone'),
              const SizedBox(height: 6),
              _InputField(
                controller: emergencyPhoneCtrl,
                hint: '+233 XX XXX XXXX',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d+\s]')),
                ],
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return 'Emergency contact phone is required';
                  if (v.trim().length < 10)
                    return 'Enter a valid phone number';
                  return null;
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Submit button ─────────────────────────────────────────────────────────────

class _SubmitButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _SubmitButton({
    required this.isLoading,
    required this.onTap,
  });

  @override
  State<_SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<_SubmitButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        if (!widget.isLoading) widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(
              color: AppColors.accent.withOpacity(0.35),
              blurRadius: 14, offset: const Offset(0, 5))],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(
                      color: AppColors.primaryDark, strokeWidth: 2.5))
                : const Text(
                    'Complete Setup',
                    style: TextStyle(fontFamily: 'Outfit', fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark)),
          ),
        ),
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _StepDot extends StatelessWidget {
  final bool active;
  const _StepDot({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: active ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? AppColors.accent : Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label,
      style: const TextStyle(fontFamily: 'Outfit', fontSize: 12,
        fontWeight: FontWeight.w600, color: AppColors.textPrimary,
        letterSpacing: 0.2));
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: const TextStyle(fontFamily: 'Outfit', fontSize: 14,
        fontWeight: FontWeight.w500, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 14,
          color: AppColors.textHint),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2)),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(message,
            style: const TextStyle(fontFamily: 'Outfit', fontSize: 13,
              color: AppColors.error, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}