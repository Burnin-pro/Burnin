import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      appBar: AppBar(title: const Text('PROFILE')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── User card ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.dividerDark, width: 0.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: AppColors.flameGradientHorizontal,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      (user?.displayName ?? 'S').substring(0, 1).toUpperCase(),
                      style: AppTextStyles.headlineMedium
                          .copyWith(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.displayName ?? 'Staff',
                          style: AppTextStyles.headlineSmall
                              .copyWith(color: Colors.white)),
                      const SizedBox(height: 2),
                      Text(user?.email ?? '',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondaryDark)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Settings section ─────────────────────────────────────────
          _SectionHeader(label: 'SETTINGS'),
          _SettingsTile(
            icon: Icons.dark_mode_outlined,
            title: 'Dark Mode',
            trailing: Switch(
              value: themeMode == ThemeMode.dark,
              onChanged: (_) =>
                  ref.read(themeModeProvider.notifier).toggle(),
            ),
          ),
          _SettingsTile(
            icon: Icons.lock_outline_rounded,
            title: 'Change Password',
            trailing:
                const Icon(Icons.chevron_right, color: AppColors.textSecondaryDark),
            onTap: () => _showChangePasswordSheet(context),
          ),
          const SizedBox(height: 24),

          // ── About section ────────────────────────────────────────────
          _SectionHeader(label: 'ABOUT'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.dividerDark, width: 0.5),
            ),
            child: Column(
              children: [
                const AppLogo(size: 60),
                const SizedBox(height: 8),
                Text('BURNIN',
                    style: AppTextStyles.wordmark.copyWith(fontSize: 22)),
                Text('HOTFIRE',
                    style: AppTextStyles.tagline.copyWith(fontSize: 11)),
                const SizedBox(height: 12),
                Text(
                  'Private staff ordering & billing app.\nAll rights reserved.',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondaryDark),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'UPI: ${QrService.kShopUpiId}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.amber,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 4),
                Text('v1.0.0',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondaryDark.withValues(alpha: 0.5))),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ── Log Out ──────────────────────────────────────────────────
          OutlinedButton.icon(
            onPressed: () async {
              final confirm = await _confirmLogout(context);
              if (confirm == true) {
                await AuthService.instance.signOut();
                if (context.mounted) {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/login', (r) => false);
                }
              }
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('LOG OUT'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.errorRed,
              side: const BorderSide(color: AppColors.errorRed),
              minimumSize: const Size.fromHeight(52),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<bool?> _confirmLogout(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text('Log Out',
            style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to log out?',
            style: TextStyle(color: AppColors.textSecondaryDark)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Log Out',
                style: TextStyle(color: AppColors.errorRed)),
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
      // Re-authenticate first
      final email = FirebaseAuth.instance.currentUser?.email ?? '';
      await AuthService.instance.reauthenticate(
        email: email,
        password: _currentPwController.text,
      );
      await AuthService.instance.changePassword(_newPwController.text);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed successfully!')),
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
          TextField(
            controller: _currentPwController,
            obscureText: _obscureCurrent,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Current Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscureCurrent
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                onPressed: () =>
                    setState(() => _obscureCurrent = !_obscureCurrent),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _newPwController,
            obscureText: _obscureNew,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'New Password',
              prefixIcon: const Icon(Icons.lock_reset_outlined),
              suffixIcon: IconButton(
                icon: Icon(_obscureNew
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                onPressed: () =>
                    setState(() => _obscureNew = !_obscureNew),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.errorRed)),
          ],
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Update Password',
            isLoading: _isLoading,
            onPressed: _changePassword,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(label,
          style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondaryDark, letterSpacing: 2)),
    );
  }
}

// ── Settings tile ───────────────────────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.dividerDark, width: 0.5),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppColors.amber),
        title: Text(title,
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
        trailing: trailing,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
