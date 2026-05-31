import 'package:flutter/material.dart';
import '../core/constants.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.onRetry,
    this.message = '데이터를 불러오지 못했습니다',
  });

  final VoidCallback onRetry;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(message,
              style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onRetry,
            child: const Text(AppStrings.errorRetry),
          ),
        ],
      ),
    );
  }
}
