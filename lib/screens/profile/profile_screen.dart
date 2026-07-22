import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/auth_service.dart';
import '../../services/qr_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/primary_button.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldDark,
      body: CustomScrollView(
        slivers: [
          // ── Gradient Header with Avatar ────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.maroon,
                    AppColors.maroonLight,
                    AppColors.orange,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  child: Column(
                    children: [
                      // Title row
                      Row(
                        children: [
                          Text(
                            'PROFILE',
                            style: AppTextStyles.headlineSmall.copyWith(
                                color: Colors.white,
                                letterSpacing: 2,
                                fontSize: 20),
                          ),
                          const Spacer(),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Avatar with fire beam ring
                      _FireBeamAvatar(
                        size: 100,
                        initial: (user?.displayName ?? 'S')
                            .substring(0, 1)
                            .toUpperCase(),
                      ).animate().fadeIn(duration: 500.ms).scale(
                          begin: const Offset(0.85, 0.85),
                          curve: Curves.easeOutBack),

                      const SizedBox(height: 16),

                      // Name
                      Text(
                        user?.displayName ?? 'Staff',
                        style: AppTextStyles.headlineMedium
                            .copyWith(color: Colors.white, fontSize: 24),
                      ).animate().fadeIn(delay: 150.ms),

                      const SizedBox(height: 4),

                      // Email
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          user?.email ?? '',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white70,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ).animate().fadeIn(delay: 250.ms),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Settings ─────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _SectionHeader(label: 'SETTINGS'),
                const SizedBox(height: 8),

                _SettingsTile(
                  icon: Icons.dark_mode_outlined,
                  iconBg: AppColors.maroon,
                  title: 'Dark Mode',
                  subtitle: 'Toggle theme appearance',
                  trailing: Switch(
                    value: themeMode == ThemeMode.dark,
                    activeColor: AppColors.amber,
                    onChanged: (_) =>
                        ref.read(themeModeProvider.notifier).toggle(),
                  ),
                ).animate().fadeIn(delay: 100.ms),

                _SettingsTile(
                  icon: Icons.lock_outline_rounded,
                  iconBg: AppColors.orange,
                  title: 'Change Password',
                  subtitle: 'Update your credentials',
                  trailing: const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textSecondaryDark),
                  onTap: () => _showChangePasswordSheet(context),
                ).animate().fadeIn(delay: 150.ms),

                _SettingsTile(
                  icon: Icons.notifications_none_rounded,
                  iconBg: AppColors.amber,
                  title: 'Notifications',
                  subtitle: 'Manage alerts',
                  trailing: const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textSecondaryDark),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 28),

                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  iconBg: AppColors.vegGreen,
                  title: 'About',
                  subtitle: 'App version and info',
                  trailing: const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textSecondaryDark),
                  onTap: () => Navigator.of(context).pushNamed('/about'),
                ).animate().fadeIn(delay: 250.ms),

                const SizedBox(height: 32),

                // ── Log Out Button ──────────────────────────────────────
                GestureDetector(
                  onTap: () async {
                    final confirm = await _confirmLogout(context);
                    if (confirm == true) {
                      await AuthService.instance.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                            '/login', (r) => false);
                      }
                    }
                  },
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.errorRed.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.errorRed.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.logout_rounded,
                            color: AppColors.errorRed, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          'LOG OUT',
                          style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.errorRed, letterSpacing: 1.5),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 350.ms),

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmLogout(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Log Out',
            style: AppTextStyles.headlineSmall.copyWith(color: Colors.white)),
        content: Text('Are you sure you want to log out?',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondaryDark)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: AppTextStyles.labelMedium
                    .copyWith(color: AppColors.textSecondaryDark)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Log Out',
                style:
                    AppTextStyles.labelMedium.copyWith(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _ChangePasswordSheet(),
    );
  }
}

// ── Animated Fire Beam Avatar ───────────────────────────────────────────────
class _FireBeamAvatar extends StatefulWidget {
  final double size;
  final String initial;

  const _FireBeamAvatar({required this.size, required this.initial});

  @override
  State<_FireBeamAvatar> createState() => _FireBeamAvatarState();
}

class _FireBeamAvatarState extends State<_FireBeamAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.size + 8,
          height: widget.size + 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              colors: const [
                AppColors.maroonDark,
                AppColors.amber,
                AppColors.amberLight,
                Colors.white,
                AppColors.orange,
                AppColors.maroon,
                AppColors.maroonDark,
              ],
              stops: const [0.0, 0.15, 0.3, 0.5, 0.7, 0.85, 1.0],
              transform:
                  GradientRotation(_controller.value * 2 * math.pi),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.amber.withValues(alpha: 0.3),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.flameGradientHorizontal,
        ),
        child: Center(
          child: Text(
            widget.initial,
            style: AppTextStyles.headlineLarge.copyWith(
              color: Colors.white,
              fontSize: widget.size * 0.4,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Change password bottom sheet ────────────────────────────────────────────
class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _currentPwController = TextEditingController();
  final _newPwController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _obscureCurrent = true;
  bool _obscureNew = true;

  Future<void> _changePassword() async {
    if (_newPwController.text.length < 6) {
      setState(() => _error = 'New password must be at least 6 characters');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final email = FirebaseAuth.instance.currentUser?.email ?? '';
      await AuthService.instance.reauthenticate(
        email: email,
        password: _currentPwController.text,
      );
      await AuthService.instance.changePassword(_newPwController.text);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.maroon,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text('Password changed successfully!',
                    style:
                        AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
              ],
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = AuthService.friendlyError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _currentPwController.dispose();
    _newPwController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.dividerDark,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('CHANGE PASSWORD',
              style: AppTextStyles.headlineSmall
                  .copyWith(color: Colors.white, letterSpacing: 1.5)),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.dividerDark),
            ),
            child: TextField(
              controller: _currentPwController,
              obscureText: _obscureCurrent,
              style: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Current Password',
                hintStyle: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondaryDark),
                prefixIcon:
                    const Icon(Icons.lock_outline, color: AppColors.amber),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscureCurrent
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textSecondaryDark),
                  onPressed: () =>
                      setState(() => _obscureCurrent = !_obscureCurrent),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.dividerDark),
            ),
            child: TextField(
              controller: _newPwController,
              obscureText: _obscureNew,
              style: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'New Password',
                hintStyle: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondaryDark),
                prefixIcon: const Icon(Icons.lock_reset_outlined,
                    color: AppColors.amber),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscureNew
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textSecondaryDark),
                  onPressed: () =>
                      setState(() => _obscureNew = !_obscureNew),
                ),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.errorRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.errorRed, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_error!,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.errorRed)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Update Password',
            isLoading: _isLoading,
            onPressed: _changePassword,
            icon: Icons.check_circle_outline,
          ),
        ],
      ),
    );
  }
}

// ── Section header ──────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.amber,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondaryDark, letterSpacing: 2)),
      ],
    );
  }
}

// ── Settings tile ───────────────────────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerDark, width: 0.5),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: iconBg.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconBg, size: 22),
        ),
        title: Text(title,
            style: AppTextStyles.labelMedium.copyWith(color: Colors.white)),
        subtitle: Text(subtitle,
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondaryDark)),
        trailing: trailing,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
