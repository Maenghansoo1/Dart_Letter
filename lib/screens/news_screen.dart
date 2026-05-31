import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/news_provider.dart';
import '../widgets/error_view.dart';
import '../widgets/news_card.dart';
import '../widgets/skeleton_loader.dart';

class NewsScreen extends ConsumerWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(latestNewsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('뉴스')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(latestNewsProvider.future),
        child: newsAsync.when(
          loading: () => ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: 6,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, _) => const NewsCardSkeleton(),
          ),
          error: (_, _) => ErrorView(
            message: '뉴스를 불러오지 못했습니다',
            onRetry: () => ref.invalidate(latestNewsProvider),
          ),
          data: (news) => news.isEmpty
              ? const Center(child: Text('최신 뉴스가 없습니다'))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  itemCount: news.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) => NewsCard(item: news[index]),
                ),
        ),
      ),
    );
  }
}
