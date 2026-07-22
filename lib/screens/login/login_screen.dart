import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_strings.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  late AnimationController _btnGlowController;

  @override
  void initState() {
    super.initState();
    _nameFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
    _btnGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await Future.delayed(const Duration(milliseconds: 600));

    if (_nameController.text.trim() == 'Muthupandi' &&
        _passwordController.text == 'Realmec13') {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/menu');
      }
    } else {
      setState(() {
        _errorMessage = 'Incorrect name or password.';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _nameFocus.dispose();
    _passwordFocus.dispose();
    _btnGlowController.dispose();
    super.dispose();
  }

  Widget _buildField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputAction action = TextInputAction.next,
    String? Function(String?)? validator,
    void Function(String)? onSubmitted,
  }) {
    final focused = focusNode.hasFocus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: focused ? Colors.white : Colors.white60,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: focused
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: focused
                  ? AppColors.amberLight
                  : Colors.white.withValues(alpha: 0.15),
              width: focused ? 1.5 : 1,
            ),
            boxShadow: focused
                ? [
                    BoxShadow(
                      color: AppColors.amber.withValues(alpha: 0.15),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            obscureText: obscure,
            textInputAction: action,
            onFieldSubmitted: onSubmitted,
            style: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.bodyMedium
                  .copyWith(color: Colors.white38),
              prefixIcon: Icon(icon,
                  color: focused ? AppColors.amberLight : Colors.white54,
                  size: 22),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const topColor = Colors.white;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.flameGradient,
        ),
        child: Stack(
          children: [
            // White wavy top
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: size.height * 0.45,
              child: CustomPaint(
                painter: _WavyTopPainter(color: topColor),
              ),
            ),

            // Main Content
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            // Logo on white
                            SizedBox(
                              height: size.height * 0.33,
                              child: Center(
                                child: AppLogo(
                                  size: math.min(240, size.height * 0.28),
                                  showTagline: false,
                                ),
                              ),
                            ).animate().fadeIn(duration: 600.ms).slideY(
                                begin: -0.15,
                                end: 0,
                                curve: Curves.easeOutCubic),

                            // Form on flame
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 28),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 28),
                                      Text(
                                        'Sign in',
                                        style: AppTextStyles.headlineLarge
                                            .copyWith(
                                          color: Colors.white,
                                          fontSize: 34,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ).animate().fadeIn(delay: 150.ms),
                                      Container(
                                        width: 36,
                                        height: 3,
                                        margin: const EdgeInsets.only(
                                            top: 6, bottom: 28),
                                        decoration: BoxDecoration(
                                          color: AppColors.amberLight,
                                          borderRadius:
                                              BorderRadius.circular(2),
                                        ),
                                      ).animate().scaleX(
                                          delay: 300.ms,
                                          alignment:
                                              Alignment.centerLeft),

                                      // Name
                                      _buildField(
                                        controller: _nameController,
                                        focusNode: _nameFocus,
                                        label: 'Name',
                                        hint: 'Enter your name',
                                        icon:
                                            Icons.person_outline_rounded,
                                        validator: (v) => v == null ||
                                                v.isEmpty
                                            ? 'Please enter your name'
                                            : null,
                                      ).animate().fadeIn(delay: 250.ms).slideY(
                                          begin: 0.08, end: 0),

                                      const SizedBox(height: 20),

                                      // Password
                                      _buildField(
                                        controller: _passwordController,
                                        focusNode: _passwordFocus,
                                        label: 'Password',
                                        hint: 'Enter your password',
                                        icon: Icons.lock_outline_rounded,
                                        obscure: _obscurePassword,
                                        action: TextInputAction.done,
                                        onSubmitted: (_) => _signIn(),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons
                                                    .visibility_off_outlined
                                                : Icons
                                                    .visibility_outlined,
                                            color: Colors.white54,
                                            size: 20,
                                          ),
                                          onPressed: () => setState(() =>
                                              _obscurePassword =
                                                  !_obscurePassword),
                                        ),
                                        validator: (v) => v == null ||
                                                v.isEmpty
                                            ? 'Please enter your password'
                                            : null,
                                      ).animate().fadeIn(delay: 350.ms).slideY(
                                          begin: 0.08, end: 0),

                                      if (_errorMessage != null) ...[
                                        const SizedBox(height: 14),
                                        Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 10),
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                  Icons.error_outline,
                                                  color: Colors.white,
                                                  size: 18),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  _errorMessage!,
                                                  style: AppTextStyles
                                                      .bodySmall
                                                      .copyWith(
                                                          color: Colors
                                                              .white),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ).animate().fadeIn().shake(hz: 2),
                                      ],

                                      const SizedBox(height: 36),
                                      const Spacer(),

                                      // Login Button with animated glow
                                      AnimatedBuilder(
                                        animation: _btnGlowController,
                                        builder: (context, child) {
                                          return Container(
                                            width: double.infinity,
                                            height: 56,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      16),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppColors
                                                      .amberLight
                                                      .withValues(
                                                          alpha: 0.2 +
                                                              _btnGlowController
                                                                      .value *
                                                                  0.25),
                                                  blurRadius: 20 +
                                                      _btnGlowController
                                                              .value *
                                                          10,
                                                  offset: const Offset(
                                                      0, 4),
                                                ),
                                              ],
                                            ),
                                            child: child,
                                          );
                                        },
                                        child: ElevatedButton(
                                          onPressed:
                                              _isLoading ? null : _signIn,
                                          style: ElevatedButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            backgroundColor: Colors.white,
                                            foregroundColor:
                                                AppColors.maroon,
                                            disabledBackgroundColor:
                                                Colors.white70,
                                            shape:
                                                RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      16),
                                            ),
                                            elevation: 0,
                                          ),
                                          child: _isLoading
                                              ? const SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child:
                                                      CircularProgressIndicator(
                                                    color:
                                                        AppColors.orange,
                                                    strokeWidth: 2.5,
                                                  ),
                                                )
                                              : Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .center,
                                                  children: [
                                                    Text(
                                                      'LOGIN',
                                                      style: AppTextStyles
                                                          .labelLarge
                                                          .copyWith(
                                                        color: AppColors
                                                            .maroon,
                                                        fontSize: 17,
                                                        letterSpacing: 2,
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                        width: 10),
                                                    const Icon(
                                                      Icons
                                                          .arrow_forward_rounded,
                                                      color:
                                                          AppColors.maroon,
                                                      size: 20,
                                                    ),
                                                  ],
                                                ),
                                        ),
                                      ).animate().fadeIn(delay: 450.ms).scale(
                                          begin:
                                              const Offset(0.92, 0.92),
                                          curve: Curves.easeOutBack),

                                      const SizedBox(height: 28),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          ],
        ),
      ),
    );
  }
}

// ── Wavy top painter ────────────────────────────────────────────────────────
class _WavyTopPainter extends CustomPainter {
  final Color color;
  _WavyTopPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    path.lineTo(0, size.height * 0.7);
    path.quadraticBezierTo(
        size.width * 0.25, size.height * 0.95,
        size.width * 0.5, size.height * 0.7);
    path.quadraticBezierTo(
        size.width * 0.75, size.height * 0.45,
        size.width, size.height * 0.85);
    path.lineTo(size.width, 0);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavyTopPainter oldDelegate) =>
      oldDelegate.color != color;
}
