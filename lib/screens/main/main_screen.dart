import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_logo.dart';

// Import the sub-screens
import '../menu/menu_screen.dart';
import '../add_item/add_item_screen.dart';
import '../history/history_screen.dart';
import '../profile/profile_screen.dart';

/// Abstract interface so child screens can call switchToMenuAndShowSuccess
abstract class MainScreenState {
  void switchToMenuAndShowSuccess(String itemName);
}

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> implements MainScreenState {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    MenuScreen(),
    AddItemScreen(),
    HistoryScreen(),
    ProfileScreen(),
  ];

  @override
  void switchToMenuAndShowSuccess(String itemName) {
    setState(() => _currentIndex = 0);
    // Show the success popup after switching tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'ItemAdded',
        barrierColor: Colors.black.withValues(alpha: 0.6),
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) =>
            _ItemAddedPopup(itemName: itemName),
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return Transform.scale(
            scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack).value,
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          child: _FloatingNavBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() => _currentIndex = index);
            },
          ),
        ),
      ),
    );
  }
}

class _FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _FloatingNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withValues(alpha: 0.5) 
                : AppColors.maroon.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: isDark 
              ? AppColors.dividerDark 
              : AppColors.maroon.withValues(alpha: 0.1),
          width: 0.5,
        ),
      ),
      child: Stack(
        children: [
          // Animated Sliding Indicator
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            top: 0,
            bottom: 0,
            // Calculate left position based on current index
            // Assuming 4 tabs, each gets 25% of width
            left: (MediaQuery.of(context).size.width - 32) * (currentIndex / 4),
            width: (MediaQuery.of(context).size.width - 32) / 4,
            child: Center(
              child: Container(
                height: 4,
                width: 30,
                decoration: BoxDecoration(
                  gradient: AppColors.flameGradientHorizontal,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.amber.withValues(alpha: 0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
              ).animate(target: 1).fadeIn().moveY(begin: -10, end: -30), // Top indicator
            ),
          ),
          
          // Tab Items
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavBarItem(
                icon: Icons.local_fire_department_rounded,
                label: 'Menu',
                isSelected: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavBarItem(
                icon: Icons.add_circle_outline_rounded,
                label: 'Add',
                isSelected: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavBarItem(
                icon: Icons.history_rounded,
                label: 'History',
                isSelected: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _NavBarItem(
                icon: Icons.person_outline_rounded,
                label: 'Profile',
                isSelected: currentIndex == 3,
                onTap: () => onTap(3),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected 
        ? AppColors.amber 
        : Theme.of(context).brightness == Brightness.dark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondaryLight;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 26,
            )
            .animate(target: isSelected ? 1 : 0)
            .scale(begin: const Offset(1, 1), end: const Offset(1.15, 1.15), curve: Curves.easeOutBack, duration: 300.ms)
            .tint(color: AppColors.amber, end: isSelected ? 1 : 0),
            
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            )
            .animate(target: isSelected ? 1 : 0)
            .fadeIn(duration: 200.ms),
          ],
        ),
      ),
    );
  }
}

// ── Item Added Success Popup ─────────────────────────────────────────────────
class _ItemAddedPopup extends StatefulWidget {
  final String itemName;
  const _ItemAddedPopup({required this.itemName});

  @override
  State<_ItemAddedPopup> createState() => _ItemAddedPopupState();
}

class _ItemAddedPopupState extends State<_ItemAddedPopup> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 5), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 340,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFF2E7D32), // Rich green
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1B5E20).withValues(alpha: 0.5),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Wavy top (White)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 220,
                child: CustomPaint(
                  painter: _SuccessWavyPainter(),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Green check icon
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF43A047),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2E7D32).withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 50,
                      ),
                    ).animate().scale(
                      begin: const Offset(0.3, 0.3),
                      duration: 600.ms,
                      curve: Curves.easeOutBack,
                    ),
                    const SizedBox(height: 70),

                    Text(
                      'Added Successfully!',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: Colors.white,
                        letterSpacing: 1.5,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 10),

                    Text(
                      '"${widget.itemName}" has been added to the menu.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ).animate().fadeIn(delay: 300.ms),
                    const SizedBox(height: 32),

                    // Close Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF2E7D32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                        child: Text(
                          'CLOSE',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: const Color(0xFF2E7D32),
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 400.ms).scale(curve: Curves.easeOutBack),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Wavy Painter for Success Popup ──────────────────────────────────────────
class _SuccessWavyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final path = Path();
    path.lineTo(0, size.height * 0.6);
    path.quadraticBezierTo(
        size.width * 0.25, size.height * 0.9,
        size.width * 0.5, size.height * 0.6);
    path.quadraticBezierTo(
        size.width * 0.75, size.height * 0.3,
        size.width, size.height * 0.8);
    path.lineTo(size.width, 0);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
