import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await ref.read(authProvider.notifier).login(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
          );
      if (mounted) context.go('/');
    } catch (e) {
      if (!mounted) return;
      final msg = ref.read(authProvider).error ?? '로그인에 실패했습니다';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                // 로고
                const Icon(Icons.bar_chart_rounded,
                    size: 56, color: AppColors.primary),
                const SizedBox(height: 12),
                const Text(
                  '다트레터',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary),
                ),
                const SizedBox(height: 6),
                const Text(
                  'DART 공시를 AI가 쉽게 풀어드립니다',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 48),
                // 이메일
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: '이메일',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return '이메일을 입력하세요';
                    if (!v.contains('@')) return '올바른 이메일 형식이 아닙니다';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // 비밀번호
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: '비밀번호',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return '비밀번호를 입력하세요';
                    return null;
                  },
                  onFieldSubmitted: (_) => _login(),
                ),
                const SizedBox(height: 24),
                // 로그인 버튼
                FilledButton(
                  onPressed: isLoading ? null : _login,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('로그인',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 16),
                // 회원가입 이동
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('계정이 없으신가요?',
                        style: TextStyle(color: AppColors.textSecondary)),
                    TextButton(
                      onPressed: () => context.push('/auth/signup'),
                      child: const Text('회원가입',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                const Text(
                  AppStrings.disclaimer,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: AppColors.textHint),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
