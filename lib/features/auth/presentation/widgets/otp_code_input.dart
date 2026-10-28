import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';

import '../../../../core/theme/app_theme.dart';

class OtpCodeInput extends StatelessWidget {
  final TextEditingController controller;

  const OtpCodeInput({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final defaultTheme = PinTheme(
      width: 43,
      height: 54,
      textStyle: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.navy,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
    );

    return Pinput(
      length: 6,
      controller: controller,
      autofocus: true,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      separatorBuilder: (_) => const SizedBox(width: 6),
      defaultPinTheme: defaultTheme,
      focusedPinTheme: defaultTheme.copyDecorationWith(
        border: Border.all(color: AppColors.blue, width: 2),
      ),
      submittedPinTheme: defaultTheme.copyDecorationWith(
        color: AppColors.iceBlue,
      ),
      enableInteractiveSelection: false,
      showCursor: true,
    );
  }
}
