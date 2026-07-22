import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';

/// BurnIn logo widget — renders the burninlogo.png asset with wordmark.
/// Used in splash screen, login screen AppBar, and bill header.
class AppLogo extends StatelessWidget {
  /// [size] controls the width of the logo image. Height is proportional.
  final double size;

  /// Show the "HOTFIRE" tagline below the wordmark (splash/login).
  final bool showTagline;

  const AppLogo({super.key, this.size = 100, this.showTagline = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/burninlogo.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.local_fire_department,
            size: size,
            color: const Color(0xFFFF8C00),
          ),
        ),
        if (showTagline) ...[
          const SizedBox(height: 4),
          Text(
            'H O T F I R E',
            style: AppTextStyles.tagline,
          ),
        ],
      ],
    );
  }
}
