import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_logo.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.maroon.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: AppColors.maroon, size: 22),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
                painter: _AboutWavyPainter(color: Colors.white),
              ),
            ),

            // Content
            SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    SizedBox(height: size.height * 0.05),

                    // Logo directly on the background
                    const AppLogo(size: 180, showTagline: false)
                        .animate()
                        .scale(
                          duration: 800.ms,
                          curve: Curves.easeOutBack,
                          begin: const Offset(0.5, 0.5),
                        )
                        .fadeIn(duration: 600.ms),

                    const SizedBox(height: 32),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'This app is private and only available as an Android APK.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: Colors.white,
                          height: 1.4,
                        ),
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
                    
                    const SizedBox(height: 12),
                    
                    const Icon(
                      Icons.android_rounded,
                      color: AppColors.vegGreen,
                      size: 40,
                    ).animate().fadeIn(delay: 300.ms).scale(curve: Curves.easeOutBack),

                    const SizedBox(height: 24),

                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        'Version 1.0',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ).animate().fadeIn(delay: 400.ms).scale(
                        curve: Curves.easeOutBack),

                    const Spacer(),

                    // Professional Attribution
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 2,
                          color: AppColors.amberLight.withValues(alpha: 0.5),
                          margin: const EdgeInsets.only(bottom: 16),
                        ),
                        Text(
                          '© 2026 all rights reserved by',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white70,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Image.asset(
                          'assets/images/codevara.png',
                          height: 40, // Adjust size as necessary for the Codevara logo
                        ),
                      ],
                    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutWavyPainter extends CustomPainter {
  final Color color;
  _AboutWavyPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    path.lineTo(0, size.height * 0.7);
    path.quadraticBezierTo(
        size.width * 0.25, size.height,
        size.width * 0.5, size.height * 0.8);
    path.quadraticBezierTo(
        size.width * 0.75, size.height * 0.6,
        size.width, size.height * 0.85);
    path.lineTo(size.width, 0);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _AboutWavyPainter oldDelegate) =>
      oldDelegate.color != color;
}
