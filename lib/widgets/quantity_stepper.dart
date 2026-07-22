import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// +/- quantity stepper used on menu item cards and in the cart.
class QuantityStepper extends StatelessWidget {
  final int value;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final double height;

  const QuantityStepper({
    super.key,
    required this.value,
    required this.onIncrement,
    required this.onDecrement,
    this.height = 32,
  });

  @override
  Widget build(BuildContext context) {
    if (value == 0) {
      // Show a single "ADD" pill when quantity is zero
      return GestureDetector(
        onTap: onIncrement,
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            gradient: AppColors.flameGradientHorizontal,
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: Center(
            child: Text(
              'ADD',
              style: AppTextStyles.labelSmall.copyWith(
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.maroon,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrement
          _StepperButton(
            icon: Icons.remove,
            onTap: onDecrement,
            height: height,
          ),
          // Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '$value',
              style: AppTextStyles.labelMedium.copyWith(
                color: Colors.white,
                fontSize: height * 0.44,
              ),
            ),
          ),
          // Increment
          _StepperButton(
            icon: Icons.add,
            onTap: onIncrement,
            height: height,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double height;

  const _StepperButton({
    required this.icon,
    required this.onTap,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: height,
        height: height,
        child: Center(
          child: Icon(icon, color: Colors.white, size: height * 0.5),
        ),
      ),
    );
  }
}
