import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Horizontal-scroll date chip for the History screen.
/// Shows day + month abbreviation; highlights the selected date.
class DateChip extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final VoidCallback onTap;

  const DateChip({
    super.key,
    required this.date,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final day = DateFormat('dd').format(date);
    final month = DateFormat('MMM').format(date).toUpperCase();
    final year = DateFormat('yyyy').format(date);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 60,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.maroon : AppColors.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.amber : AppColors.dividerDark,
            width: isSelected ? 1.5 : 0.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.maroon.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              day,
              style: AppTextStyles.headlineSmall.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondaryDark,
                fontSize: 18,
              ),
            ),
            Text(
              month,
              style: AppTextStyles.labelSmall.copyWith(
                color: isSelected ? AppColors.amberLight : AppColors.textSecondaryDark,
              ),
            ),
            Text(
              year,
              style: AppTextStyles.bodySmall.copyWith(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.7)
                    : AppColors.textSecondaryDark.withValues(alpha: 0.6),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
