import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/auth_service.dart';
import '../../services/qr_service.dart';
import '../menu/menu_screen.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/primary_button.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  String _getInitials(String name) {
    if (name.isEmpty) return 'B';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
    }
    return parts[0].substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          _FireBeamAvatar(
                            size: 100,
                            initial: _getInitials(user?.displayName != null && user!.displayName!.isNotEmpty && user.displayName != 'Burnin' ? user.displayName! : (user?.email?.split('@').first ?? 'User')),
                          ).animate().fadeIn(duration: 500.ms).scale(
                              begin: const Offset(0.85, 0.85),
                              curve: Curves.easeOutBack),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: AppColors.orange,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add_a_photo_rounded, color: Colors.white, size: 18),
                            ).animate().scale(delay: 600.ms, curve: Curves.elasticOut),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Name
                      Text(
                        user?.displayName != null && user!.displayName!.isNotEmpty && user.displayName != 'Burnin' 
                            ? user.displayName! 
                            : (user?.email?.split('@').first ?? 'User'),
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
                  trailing: Icon(Icons.chevron_right_rounded,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                  onTap: () => _showChangePasswordSheet(context),
                ).animate().fadeIn(delay: 150.ms),

                _SettingsTile(
                  icon: Icons.query_stats_rounded,
                  iconBg: AppColors.amber,
                  title: 'Sales & Analytics',
                  subtitle: 'View your performance',
                  trailing: Icon(Icons.chevron_right_rounded,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                  onTap: () => Navigator.of(context).pushNamed('/sales'),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 28),

                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  iconBg: AppColors.vegGreen,
                  title: 'About',
                  subtitle: 'App version and info',
                  trailing: Icon(Icons.chevron_right_rounded,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                  onTap: () => Navigator.of(context).pushNamed('/about'),
                ).animate().fadeIn(delay: 250.ms),

                const SizedBox(height: 32),

                // ── Log Out Button ──────────────────────────────────────
                GestureDetector(
                  onTap: () async {
                    final confirm = await _confirmLogout(context);
                    if (confirm == true) {
                      // Providers will be auto-disposed when MainScreen is unmounted.
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

                SizedBox(height: MediaQuery.of(context).padding.bottom + 120),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmLogout(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Log Out',
            style: AppTextStyles.headlineSmall.copyWith(
                color: Theme.of(context).colorScheme.onSurface)),
        content: Text('Are you sure you want to log out?',
            style: AppTextStyles.bodyMedium.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: AppTextStyles.labelMedium.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
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
      backgroundColor: Theme.of(context).cardColor,
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

  String? _base64Image;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  Future<void> _loadProfileImage() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final prefs = await SharedPreferences.getInstance();
      final savedImage = prefs.getString('profile_image_$uid');
      if (savedImage != null && mounted) {
        setState(() {
          _base64Image = savedImage;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        
        setState(() {
          _base64Image = base64String;
        });

        // Save persistently to local storage instead of Firebase Auth photoURL
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('profile_image_$uid', base64String);
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _pickImage,
      child: AnimatedBuilder(
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
          image: _base64Image != null && _base64Image!.contains(',')
              ? DecorationImage(
                  image: MemoryImage(base64Decode(_base64Image!.split(',').last)),
                  fit: BoxFit.cover)
              : null,
        ),
        child: Center(
          child: _base64Image == null
              ? Text(
                  widget.initial,
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: Colors.white,
                    fontSize: widget.size * 0.4,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ),
    ));
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
        bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 24,
      ),
      child: SingleChildScrollView(
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
              style: AppTextStyles.headlineSmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurface, letterSpacing: 1.5)),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: TextField(
              controller: _currentPwController,
              obscureText: _obscureCurrent,
              style: AppTextStyles.bodyLarge.copyWith(
                  color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Current Password',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? AppColors.textSecondaryDark 
                        : AppColors.textSecondaryLight),
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
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: TextField(
              controller: _newPwController,
              obscureText: _obscureNew,
              style: AppTextStyles.bodyLarge.copyWith(
                  color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'New Password',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? AppColors.textSecondaryDark 
                        : AppColors.textSecondaryLight),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, letterSpacing: 2)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outline, width: 0.5),
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
            style: AppTextStyles.labelMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface)),
        subtitle: Text(subtitle,
            style: AppTextStyles.bodySmall.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
        trailing: trailing,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
