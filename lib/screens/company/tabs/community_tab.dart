import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants.dart';
import '../../../core/extensions.dart';
import '../../../providers/community_provider.dart';
import '../../../widgets/error_view.dart';

class CommunityTab extends ConsumerWidget {
  const CommunityTab({super.key, required this.corpCode});

  final String corpCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(companyPostsProvider(corpCode));

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(companyPostsProvider(corpCode).future),
        child: postsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => ErrorView(
            message: '게시글을 불러오지 못했습니다',
            onRetry: () => ref.invalidate(companyPostsProvider(corpCode)),
          ),
          data: (posts) {
            if (posts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.forum_outlined,
                        size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    const Text('첫 번째 글을 작성해보세요',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: posts.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final post = posts[index];
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(
                    post.title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Text(post.createdAt.relativeTime,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textHint)),
                        const Spacer(),
                        const Icon(Icons.thumb_up_outlined,
                            size: 13, color: AppColors.textHint),
                        const SizedBox(width: 2),
                        Text('${post.likeCount}',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textHint)),
                        const SizedBox(width: 8),
                        const Icon(Icons.chat_bubble_outline,
                            size: 13, color: AppColors.textHint),
                        const SizedBox(width: 2),
                        Text('${post.commentCount}',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textHint)),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }
}
