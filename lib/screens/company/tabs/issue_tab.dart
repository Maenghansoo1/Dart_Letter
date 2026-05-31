import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants.dart';
import '../../../providers/news_provider.dart';
import '../../../widgets/error_view.dart';
import '../../../widgets/news_card.dart';
import '../../../widgets/skeleton_loader.dart';

class IssueTab extends ConsumerWidget {
  const IssueTab({super.key, required this.corpCode});

  final String corpCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(companyNewsProvider(corpCode));

    return newsAsync.when(
      loading: () => ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: 4,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (_, _) => const NewsCardSkeleton(),
      ),
      error: (_, _) => ErrorView(
        message: '이슈를 불러오지 못했습니다',
        onRetry: () => ref.invalidate(companyNewsProvider(corpCode)),
      ),
      data: (news) {
        final issues = news.where((n) => n.category == '과거이슈').toList();
        if (issues.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history, size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                const Text('등록된 과거 이슈가 없습니다',
                    style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: issues.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) => NewsCard(item: issues[index]),
        );
      },
    );
  }
}
