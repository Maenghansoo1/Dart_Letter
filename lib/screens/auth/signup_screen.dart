import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _nicknameCtrl.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await ref.read(authProvider.notifier).signup(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
            nickname: _nicknameCtrl.text.trim(),
          );
      if (mounted) {
        context.pushReplacement('/auth/confirm',
            extra: {'email': _emailCtrl.text.trim()});
      }
    } catch (e) {
      if (!mounted) return;
      final msg = ref.read(authProvider).error ?? '회원가입에 실패했습니다';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 닉네임
                TextFormField(
                  controller: _nicknameCtrl,
                  decoration: const InputDecoration(
                    labelText: '닉네임',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                    helperText: '커뮤니티에서 표시될 이름 (최대 20자)',
                  ),
                  maxLength: 20,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return '닉네임을 입력하세요';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
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
                    helperText: '6자 이상',
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return '비밀번호를 입력하세요';
                    if (v.length < 6) return '비밀번호는 6자 이상이어야 합니다';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // 비밀번호 확인
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: '비밀번호 확인',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v != _passwordCtrl.text) return '비밀번호가 일치하지 않습니다';
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: isLoading ? null : _signup,
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
                      : const Text('회원가입',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('이미 계정이 있으신가요?',
                        style: TextStyle(color: AppColors.textSecondary)),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('로그인',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
