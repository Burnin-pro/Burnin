import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_logo.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Generate a list of recent notification times (simulating history)
    final now = DateTime.now();
    final List<DateTime> mockHistory = List.generate(
      6,
      (index) => now.subtract(Duration(hours: index * 2)),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // ── Premium Header ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                gradient: AppColors.flameGradientHorizontal,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Stack(
                children: [
                  // White/Dark wavy top background
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: size.height * 0.25,
                    child: CustomPaint(
                      painter: _NotificationWavyPainter(
                          color: Theme.of(context).scaffoldBackgroundColor),
                    ),
                  ),

                  // Header Content
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.of(context).pop(),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.1)
                                        : Colors.black.withValues(alpha: 0.05),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.arrow_back_rounded,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              const AppLogo(size: 100, showTagline: false),
                            ],
                          ).animate().fadeIn().slideY(begin: -0.2),
                          const SizedBox(height: 24),
                          Text(
                            'Notifications',
                            style: AppTextStyles.headlineLarge.copyWith(
                              color: isDark ? Colors.white : AppColors.textPrimaryLight,
                              fontSize: 32,
                            ),
                          ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
                          const SizedBox(height: 8),
                          Text(
                            'Your recent BurnIn alerts',
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
                            ),
                          ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Notification List ────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final time = mockHistory[index];
                  final isNew = index == 0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isNew
                            ? AppColors.amberLight
                            : Theme.of(context).colorScheme.outline,
                        width: isNew ? 1.5 : 0.5,
                      ),
                      boxShadow: isNew
                          ? [
                              BoxShadow(
                                color: AppColors.amberLight
                                    .withValues(alpha: 0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : [],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon Badge
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: AppColors.flameGradientHorizontal,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.local_fire_department_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    isNew ? 'Shop Closed' : 'BurnIn 🔥',
                                    style: AppTextStyles.headlineSmall.copyWith(
                                      fontSize: 18,
                                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                    ),
                                  ),
                                  if (isNew)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.vegGreen
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'NEW',
                                        style:
                                            AppTextStyles.labelSmall.copyWith(
                                          color: AppColors.vegGreen,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                    isNew ? 'Today\'s total income: ₹14500.00' : 'BurnIn is waiting for you',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                      height: 1.4,
                                    ),
                                  ),
                              const SizedBox(height: 12),
                              Text(
                                DateFormat('MMM dd, hh:mm a').format(time),
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black38,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: 400 + (index * 100)))
                      .slideY(begin: 0.2, end: 0);
                },
                childCount: mockHistory.length,
              ),
            ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

/// A custom painter for the wavy top background behind the gradient header
class _NotificationWavyPainter extends CustomPainter {
  final Color color;
  _NotificationWavyPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.lineTo(0, size.height * 0.7);

    path.quadraticBezierTo(
      size.width * 0.25,
      size.height,
      size.width * 0.5,
      size.height * 0.8,
    );

    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.6,
      size.width,
      size.height * 0.9,
    );

    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _NotificationWavyPainter oldDelegate) =>
      color != oldDelegate.color;
}
