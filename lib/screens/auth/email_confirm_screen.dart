import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';

class EmailConfirmScreen extends StatelessWidget {
  const EmailConfirmScreen({super.key, required this.email});
  final String email;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.mark_email_unread_outlined,
                  size: 72, color: AppColors.primary),
              const SizedBox(height: 24),
              const Text(
                '이메일을 확인해주세요',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Text(
                '$email\n로 인증 메일을 발송했습니다.\n메일함을 확인하고 링크를 클릭하면 인증이 완료됩니다.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.6),
              ),
              const SizedBox(height: 40),
              FilledButton(
                onPressed: () => context.go('/auth/login'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('로그인으로 이동',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 16),
              const Text(
                '메일이 오지 않은 경우 스팸함을 확인해주세요.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textHint),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
