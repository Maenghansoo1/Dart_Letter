import 'package:flutter/material.dart';
import '../core/constants.dart';

class DisclaimerBar extends StatelessWidget {
  const DisclaimerBar({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        child: Text(
          AppStrings.disclaimer,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: AppColors.textHint),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// 화면 하단에 고정하는 버전 — Scaffold bottomSheet 대신 Column 마지막에 삽입
class DisclaimerBottomBar extends StatelessWidget {
  const DisclaimerBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: const DisclaimerBar(),
    );
  }
}
