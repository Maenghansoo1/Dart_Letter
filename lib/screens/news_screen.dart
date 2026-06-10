import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../providers/news_provider.dart';
import '../widgets/disclaimer_bar.dart';
import '../widgets/error_view.dart';
import '../widgets/news_card.dart';
import '../widgets/skeleton_loader.dart';

class NewsScreen extends ConsumerStatefulWidget {
  const NewsScreen({super.key});

  @override
  ConsumerState<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends ConsumerState<NewsScreen> {
  String _selectedCategory = '전체';

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(newsCategoriesProvider);
    final newsAsync = ref.watch(latestNewsProvider(_selectedCategory));

    return Scaffold(
      appBar: AppBar(title: const Text('뉴스')),
      body: Column(
        children: [
          // 카테고리 칩
          SizedBox(
            height: 44,
            child: categoriesAsync.when(
              loading: () => const SizedBox(),
              error: (_, _) => const SizedBox(),
              data: (cats) => ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                itemCount: cats.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final cat = cats[i];
                  final selected = cat == _selectedCategory;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: selected,
                    onSelected: (_) =>
                        setState(() => _selectedCategory = cat),
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : null,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  );
                },
              ),
            ),
          ),
          const Divider(height: 1),
          // 뉴스 리스트
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  ref.refresh(latestNewsProvider(_selectedCategory).future),
              child: newsAsync.when(
                loading: () => ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  itemCount: 6,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, _) => const NewsCardSkeleton(),
                ),
                error: (_, _) => ErrorView(
                  message: '뉴스를 불러오지 못했습니다',
                  onRetry: () =>
                      ref.invalidate(latestNewsProvider(_selectedCategory)),
                ),
                data: (news) => news.isEmpty
                    ? const Center(child: Text('뉴스가 없습니다'))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        itemCount: news.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, i) =>
                            NewsCard(item: news[i]),
                      ),
              ),
            ),
          ),
          const DisclaimerBottomBar(),
        ],
      ),
    );
  }
}
