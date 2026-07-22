import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_logo.dart';

/// Splash Screen — Phase 0 stub.
/// Shows logo centered on dark scaffold; auto-navigates after 2.5s
/// to Login or Menu depending on auth state.
/// Full cinematic animation is implemented in Phase 2.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    // Navigate after splash duration
    Future.delayed(const Duration(milliseconds: 3000), () {
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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Also listen for auth state in case it resolves before timer
    ref.listen(authStateProvider, (prev, next) {
      if (!next.isLoading && !_navigated) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && !_navigated) _checkAuthAndNavigate();
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.scaffoldDark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background glow
          Center(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.maroon.withValues(alpha: 0.3),
                    AppColors.scaffoldDark.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          // Logo + tagline
          FadeTransition(
            opacity: _fadeIn,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppLogo(size: 160, showTagline: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
