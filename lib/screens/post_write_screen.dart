import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants.dart';
import '../services/community_service.dart';

class PostWriteScreen extends StatefulWidget {
  const PostWriteScreen({super.key, this.corpCode, this.corpName});
  final String? corpCode;
  final String? corpName;

  @override
  State<PostWriteScreen> createState() => _PostWriteScreenState();
}

class _PostWriteScreenState extends State<PostWriteScreen> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController(text: '익명');
  bool _submitting = false;

  // 종목 커뮤니티에서 진입하면 종목 고정, 아니면 정보공유
  late final String? _corpCode = widget.corpCode;
  late final String? _corpName = widget.corpName;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _nicknameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();
    final nickname = _nicknameCtrl.text.trim().isEmpty ? '익명' : _nicknameCtrl.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목을 입력하세요')));
      return;
    }
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('내용을 입력하세요')));
      return;
    }

    setState(() => _submitting = true);
    try {
      await CommunityService().createPost(
        corpCode: _corpCode,
        corpName: _corpName,
        nickname: nickname,
        title: title,
        content: content,
      );
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('글 등록에 실패했습니다')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_corpName != null ? '$_corpName 커뮤니티 글쓰기' : '정보 공유 글쓰기'),
        actions: [
          TextButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('등록',
                    style: TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 카테고리 표시
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.label_outline,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    _corpName ?? '정보 공유',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 닉네임
            TextField(
              controller: _nicknameCtrl,
              decoration: const InputDecoration(
                labelText: '닉네임',
                border: OutlineInputBorder(),
              ),
              maxLength: 20,
            ),
            const SizedBox(height: 12),
            // 제목
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: '제목',
                border: OutlineInputBorder(),
              ),
              maxLength: 100,
            ),
            const SizedBox(height: 12),
            // 내용
            TextField(
              controller: _contentCtrl,
              decoration: const InputDecoration(
                labelText: '내용',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 10,
              maxLength: 2000,
            ),
            const SizedBox(height: 8),
            const Text(
              AppStrings.disclaimer,
              style: TextStyle(fontSize: 11, color: AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }
}
