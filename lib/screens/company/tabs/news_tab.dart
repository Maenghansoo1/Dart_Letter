import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/news_provider.dart';
import '../../../widgets/error_view.dart';
import '../../../widgets/news_card.dart';
import '../../../widgets/skeleton_loader.dart';

class NewsTab extends ConsumerWidget {
  const NewsTab({super.key, required this.corpName});

  final String corpName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(companyNewsProvider(corpName));

    return RefreshIndicator(
      onRefresh: () => ref.refresh(companyNewsProvider(corpName).future),
      child: newsAsync.when(
        loading: () => ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: 5,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (_, _) => const NewsCardSkeleton(),
        ),
        error: (_, _) => ErrorView(
          message: '뉴스를 불러오지 못했습니다',
          onRetry: () => ref.invalidate(companyNewsProvider(corpName)),
        ),
        data: (news) => news.isEmpty
            ? const Center(child: Text('관련 뉴스가 없습니다'))
            : ListView.separated(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                itemCount: news.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) => NewsCard(item: news[index]),
              ),
      ),
    );
  }
}
