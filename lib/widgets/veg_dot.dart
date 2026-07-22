import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A small square dot indicating Veg (green) or Non-Veg (red),
/// following the FSSAI-style veg/non-veg indicator used across India.
class VegDot extends StatelessWidget {
  final bool isVeg;
  final double size;

  const VegDot({super.key, required this.isVeg, this.size = 14});

  @override
  Widget build(BuildContext context) {
    final color = isVeg ? AppColors.vegGreen : AppColors.nonVegRed;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Center(
        child: Container(
          width: size * 0.45,
          height: size * 0.45,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
