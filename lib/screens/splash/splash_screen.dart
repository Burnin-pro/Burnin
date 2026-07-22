import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_logo.dart';

/// Cinematic Splash Screen — BurnIn brand reveal.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  bool _navigated = false;
  bool _showSlogan = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Staggered reveal sequence for slogan
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) setState(() => _showSlogan = true);
    });

    // Navigate after splash (compulsory 4 seconds total)
    Future.delayed(const Duration(milliseconds: 4500), () {
      if (mounted && !_navigated) _checkAuthAndNavigate();
    });
  }

  void _checkAuthAndNavigate() {
    _navigated = true;
    final authState = ref.read(authStateProvider);
    final user = authState.valueOrNull;
    if (!mounted) return;
    if (user != null) {
      Navigator.of(context).pushReplacementNamed('/menu');
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (prev, next) {
      if (!next.isLoading && !_navigated) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && !_navigated) _checkAuthAndNavigate();
        });
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Animated radial glow behind the logo (soft colors for white bg)
          Center(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = 1.0 + (_pulseController.value * 0.15);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 350,
                    height: 350,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.maroonLight.withValues(alpha: 0.15),
                          AppColors.amber.withValues(alpha: 0.05),
                          Colors.white.withValues(alpha: 0),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Main content: Big Logo + Slogan
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo appears first with a scale-up + fade (No text inside)
                const AppLogo(size: 240, showTagline: false)
                    .animate()
                    .scale(
                      begin: const Offset(0.3, 0.3),
                      end: const Offset(1.0, 1.0),
                      duration: 900.ms,
                      curve: Curves.easeOutBack,
                    )
                    .fadeIn(duration: 700.ms),

                const SizedBox(height: 30),

                // Attractive slogan with typewriter effect
                if (_showSlogan)
                  const _TypewriterText(
                    text: 'Igniting Flavors.',
                  ),
              ],
            ),
          ),

          // Bottom branding line
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  width: 50,
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: AppColors.flameGradientHorizontal,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ).animate(delay: 2000.ms).scaleX(begin: 0, curve: Curves.easeOutCubic),
                const SizedBox(height: 12),
                Text(
                  'Staff Portal',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.maroon.withValues(alpha: 0.6),
                    letterSpacing: 3,
                    fontWeight: FontWeight.bold,
                  ),
                ).animate(delay: 2200.ms).fadeIn(duration: 500.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Typewriter Text Effect ──────────────────────────────────────────────────
class _TypewriterText extends StatefulWidget {
  final String text;

  const _TypewriterText({required this.text});

  @override
  State<_TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<_TypewriterText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<int> _charCount;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.text.length * 80),
    );
    _charCount = StepTween(begin: 0, end: widget.text.length).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _charCount,
      builder: (context, child) {
        String visibleText = widget.text.substring(0, _charCount.value);
        bool showCursor =
            _controller.isAnimating || (_controller.isCompleted && DateTime.now().millisecond < 500);

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              visibleText,
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.maroon,
                fontSize: 24,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
            ),
            // Blinking Cursor
            Opacity(
              opacity: showCursor ? 1.0 : 0.0,
              child: Container(
                width: 3,
                height: 28,
                margin: const EdgeInsets.only(left: 2),
                color: AppColors.orange,
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(duration: 300.ms),
          ],
        );
      },
    );
  }
}
