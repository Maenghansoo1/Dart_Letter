import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../models/comment.dart';
import '../models/post.dart';
import '../providers/community_provider.dart';
import '../services/community_service.dart';
import '../widgets/error_view.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({super.key, required this.postId});
  final String postId;

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  Post? _post;
  List<Comment> _comments = [];
  bool _loading = true;
  String? _error;

  final _commentCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController(text: '익명');
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    _nicknameCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final svc = CommunityService();
      final results = await Future.wait([
        svc.getPost(widget.postId),
        svc.getComments(widget.postId),
      ]);
      if (!mounted) return;
      setState(() {
        _post = results[0] as Post;
        _comments = results[1] as List<Comment>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = '게시글을 불러오지 못했습니다'; _loading = false; });
    }
  }

  Future<void> _like() async {
    final liked = ref.read(likedPostsProvider).contains(widget.postId);
    if (liked) return;
    try {
      final newCount = await CommunityService().likePost(widget.postId);
      ref.read(likedPostsProvider.notifier).update((s) => {...s, widget.postId});
      if (!mounted) return;
      setState(() => _post = _post?.copyWith(likesCount: newCount));
    } catch (_) {}
  }

  Future<void> _submitComment() async {
    final content = _commentCtrl.text.trim();
    if (content.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    try {
      final comment = await CommunityService().createComment(
        widget.postId,
        nickname: _nicknameCtrl.text.trim().isEmpty ? '익명' : _nicknameCtrl.text.trim(),
        content: content,
      );
      if (!mounted) return;
      setState(() {
        _comments.add(comment);
        _post = _post?.copyWith(commentsCount: (_post?.commentsCount ?? 0) + 1);
        _commentCtrl.clear();
        _submitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('댓글 등록에 실패했습니다')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: ErrorView(message: _error!, onRetry: _fetch),
      );
    }

    final post = _post!;
    final liked = ref.watch(likedPostsProvider).contains(widget.postId);

    return Scaffold(
      appBar: AppBar(
        title: Text(post.corpName ?? '정보 공유'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 태그 + 닉네임 + 날짜
                Row(
                  children: [
                    if (post.corpName != null)
                      _Badge(label: post.corpName!, color: AppColors.primary)
                    else
                      const _Badge(label: '정보 공유', color: Color(0xFF2E7D32)),
                    const Spacer(),
                    Text(post.nickname,
                        style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                    const SizedBox(width: 6),
                    Text(post.relativeTime,
                        style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(post.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                Text(post.content,
                    style: const TextStyle(fontSize: 15, height: 1.6)),
                const SizedBox(height: 20),
                // 좋아요 버튼
                Center(
                  child: OutlinedButton.icon(
                    onPressed: liked ? null : _like,
                    icon: Icon(
                      liked ? Icons.thumb_up : Icons.thumb_up_outlined,
                      color: liked ? AppColors.primary : AppColors.textSecondary,
                    ),
                    label: Text(
                      '${post.likesCount}',
                      style: TextStyle(
                        color: liked ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: liked ? AppColors.primary : AppColors.divider),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                // 댓글 목록
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('댓글 ${_comments.length}',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                ),
                if (_comments.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text('첫 댓글을 남겨보세요',
                          style: TextStyle(color: AppColors.textHint)),
                    ),
                  )
                else
                  ..._comments.map((c) => _CommentTile(comment: c)),
                const SizedBox(height: 80),
              ],
            ),
          ),
          // 댓글 입력창
          _CommentInput(
            commentCtrl: _commentCtrl,
            nicknameCtrl: _nicknameCtrl,
            submitting: _submitting,
            onSubmit: _submitComment,
          ),
        ],
      ),
    );
  }
}

// ─── 댓글 타일 ────────────────────────────────────────────────────────────────

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});
  final Comment comment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(comment.nickname,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Text(comment.relativeTime,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textHint)),
            ],
          ),
          const SizedBox(height: 4),
          Text(comment.content,
              style: const TextStyle(fontSize: 14, height: 1.4)),
          const SizedBox(height: 10),
          const Divider(height: 1),
        ],
      ),
    );
  }
}

// ─── 댓글 입력창 ──────────────────────────────────────────────────────────────

class _CommentInput extends StatelessWidget {
  const _CommentInput({
    required this.commentCtrl,
    required this.nicknameCtrl,
    required this.submitting,
    required this.onSubmit,
  });

  final TextEditingController commentCtrl;
  final TextEditingController nicknameCtrl;
  final bool submitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 8,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: TextField(
              controller: nicknameCtrl,
              decoration: const InputDecoration(
                hintText: '닉네임',
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: commentCtrl,
              decoration: const InputDecoration(
                hintText: '댓글을 입력하세요',
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              maxLines: 1,
              onSubmitted: (_) => onSubmit(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: submitting ? null : onSubmit,
            icon: submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

// ─── 배지 ─────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
