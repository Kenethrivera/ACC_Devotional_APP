import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AccBrandMark extends StatelessWidget {
  static const assetPath = 'asset/acc_logo.jpg';

  final double height;
  final bool onDark;
  final double? maxWidth;

  const AccBrandMark({
    super.key,
    this.height = 52,
    this.onDark = false,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final width = (maxWidth ?? height).clamp(0.0, double.infinity).toDouble();

    return Semantics(
      image: true,
      label: 'Adelina Christian Church logo',
      child: Container(
        width: width,
        height: height,
        padding: EdgeInsets.all(height * 0.06),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(height * 0.24),
          border: Border.all(
            color: onDark ? const Color(0x44FFFFFF) : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: onDark
                  ? const Color(0x3306182A)
                  : const Color(0x16102F4E),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
          excludeFromSemantics: true,
        ),
      ),
    );
  }
}
