import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants.dart';
import '../providers/disclosure_provider.dart';
import '../providers/watchlist_provider.dart';
import '../widgets/disclosure_card.dart';
import '../widgets/disclaimer_bar.dart';
import '../widgets/error_view.dart';
import '../widgets/skeleton_loader.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchlist = ref.watch(watchlistProvider);
    final disclosuresAsync = ref.watch(watchlistDisclosuresProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('다트레터'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: watchlist.isEmpty
                ? _EmptyWatchlist(onAdd: () => context.go('/explore'))
                : RefreshIndicator(
                    onRefresh: () =>
                        ref.refresh(watchlistDisclosuresProvider.future),
                    child: disclosuresAsync.when(
                      loading: () => const _DisclosureListSkeleton(),
                      error: (_, _) => ErrorView(
                        message: '공시를 불러오지 못했습니다',
                        onRetry: () =>
                            ref.invalidate(watchlistDisclosuresProvider),
                      ),
                      data: (disclosures) => disclosures.isEmpty
                          ? const Center(child: Text('최신 공시가 없습니다'))
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              itemCount: disclosures.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) =>
                                  DisclosureCard(disclosure: disclosures[index]),
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

class _EmptyWatchlist extends StatelessWidget {
  const _EmptyWatchlist({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_chart_outlined,
                size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            const Text(
              '관심 종목을 추가하면\n해당 종목의 공시를 모아볼 수 있어요',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('종목 추가하기'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DisclosureListSkeleton extends StatelessWidget {
  const _DisclosureListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: 6,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, _) => const DisclosureCardSkeleton(),
    );
  }
}
