import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants.dart';
import 'watchlist_group_detail_screen.dart';
import '../providers/news_provider.dart';
import '../providers/watchlist_provider.dart';
import '../widgets/disclaimer_bar.dart';
import '../widgets/error_view.dart';
import '../widgets/news_card.dart';
import '../widgets/skeleton_loader.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _WatchlistBox(),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: _PopularNewsBox(),
            ),
          ),
          const DisclaimerBottomBar(),
        ],
      ),
    );
  }
}

// ─── 내 관심종목 박스 ─────────────────────────────────────────────

class _WatchlistBox extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(watchlistGroupsProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BoxHeader(
            title: '내 관심종목',
            icon: Icons.bookmarks_outlined,
            trailing: TextButton.icon(
              onPressed: () => _showAddGroupDialog(context, ref),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('폴더 추가'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
          const Divider(height: 1),
          if (groups.isEmpty)
            InkWell(
              onTap: () => _showAddGroupDialog(context, ref),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(16)),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.create_new_folder_outlined,
                          size: 36, color: AppColors.textHint),
                      SizedBox(height: 8),
                      Text('폴더를 만들고 종목을 담아보세요',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: groups.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, indent: 56, endIndent: 16),
                itemBuilder: (context, i) {
                  final g = groups[i];
                  final isLast = i == groups.length - 1;
                  return _FolderRow(
                    name: g.name,
                    count: g.companies.length,
                    isLast: isLast,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WatchlistGroupDetailScreen(groupId: g.id),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _showAddGroupDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('새 폴더'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '예: 배당주 모음'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref.read(watchlistGroupsProvider.notifier).addGroup(name);
                Navigator.pop(ctx);
              }
            },
            child: const Text('만들기'),
          ),
        ],
      ),
    );
  }
}

class _FolderRow extends StatelessWidget {
  const _FolderRow({
    required this.name,
    required this.count,
    required this.isLast,
    required this.onTap,
  });

  final String name;
  final int count;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: isLast
          ? const BorderRadius.vertical(bottom: Radius.circular(16))
          : BorderRadius.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.folder_outlined,
                  size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(name,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            Text('$count 종목',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

// ─── 인기뉴스 박스 ────────────────────────────────────────────────

class _PopularNewsBox extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(latestNewsProvider('전체'));

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          _BoxHeader(
            title: '인기뉴스',
            icon: Icons.newspaper_outlined,
            trailing: TextButton(
              onPressed: () => context.go('/news'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Row(
                children: [
                  Text('전체보기', style: TextStyle(fontSize: 13)),
                  Icon(Icons.chevron_right, size: 16),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: newsAsync.when(
              loading: () => ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                itemCount: 5,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, _) => const NewsCardSkeleton(),
              ),
              error: (_, _) => ErrorView(
                message: '뉴스를 불러오지 못했습니다',
                onRetry: () => ref.invalidate(latestNewsProvider('전체')),
              ),
              data: (news) {
                final items = news.take(5).toList();
                if (items.isEmpty) {
                  return const Center(child: Text('뉴스가 없습니다'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) => NewsCard(item: items[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 공통 박스 헤더 ───────────────────────────────────────────────

class _BoxHeader extends StatelessWidget {
  const _BoxHeader({
    required this.title,
    required this.icon,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          trailing ?? const SizedBox.shrink(),
        ],
      ),
    );
  }
}
