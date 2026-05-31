import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../core/extensions.dart';
import '../models/post.dart';
import '../providers/community_provider.dart';
import '../widgets/error_view.dart';

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(recentPostsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('커뮤니티')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(recentPostsProvider.future),
        child: postsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => ErrorView(
            message: '게시글을 불러오지 못했습니다',
            onRetry: () => ref.invalidate(recentPostsProvider),
          ),
          data: (posts) => posts.isEmpty
              ? const Center(child: Text('게시글이 없습니다'))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: posts.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) =>
                      _PostTile(post: posts[index]),
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showWriteDialog(context, ref),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  void _showWriteDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _WritePostSheet(),
    );
  }
}

class _PostTile extends StatelessWidget {
  const _PostTile({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Text(
        post.title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Text(post.corpName,
                style: const TextStyle(fontSize: 12, color: AppColors.primary)),
            const SizedBox(width: 8),
            Text(post.createdAt.relativeTime,
                style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
            const Spacer(),
            const Icon(Icons.thumb_up_outlined, size: 14, color: AppColors.textHint),
            const SizedBox(width: 2),
            Text('${post.likeCount}',
                style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
          ],
        ),
      ),
    );
  }
}

class _WritePostSheet extends StatefulWidget {
  const _WritePostSheet();

  @override
  State<_WritePostSheet> createState() => _WritePostSheetState();
}

class _WritePostSheetState extends State<_WritePostSheet> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('글쓰기',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration:
                const InputDecoration(hintText: '제목', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contentController,
            decoration: const InputDecoration(
                hintText: '내용', border: OutlineInputBorder()),
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('등록'),
          ),
        ],
      ),
    );
  }
}
