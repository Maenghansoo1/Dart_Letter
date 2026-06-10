import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants.dart';
import '../models/company.dart';
import '../providers/watchlist_provider.dart';
import '../services/company_service.dart';

class WatchlistGroupDetailScreen extends ConsumerWidget {
  const WatchlistGroupDetailScreen({super.key, required this.groupId});
  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(watchlistGroupsProvider);
    final group = groups.where((g) => g.id == groupId).firstOrNull;

    if (group == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.pop());
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final notifier = ref.read(watchlistGroupsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(group.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: '이름 변경',
            onPressed: () => _showRenameDialog(context, ref, group.name),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: '폴더 삭제',
            onPressed: () => _showDeleteDialog(context, ref),
          ),
        ],
      ),
      body: group.companies.isEmpty
          ? _EmptyBody(onAdd: () => _showAddSheet(context, ref, groupId))
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: group.companies.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, indent: 72, endIndent: 16),
              itemBuilder: (context, i) {
                final c = group.companies[i];
                return _StockRow(
                  company: c,
                  onTap: () => context.push('/company/${c.corpCode}'),
                  onRemove: () => notifier.removeCompany(groupId, c.corpCode),
                );
              },
            ),
      floatingActionButton: group.companies.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _showAddSheet(context, ref, groupId),
              icon: const Icon(Icons.add),
              label: const Text('종목 추가'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref, String current) {
    final ctrl = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('이름 변경'),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          FilledButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                ref.read(watchlistGroupsProvider.notifier).renameGroup(groupId, name);
                Navigator.pop(ctx);
              }
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('폴더 삭제'),
        content: const Text('폴더를 삭제하면 포함된 종목도 모두 제거됩니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(watchlistGroupsProvider.notifier).removeGroup(groupId);
              Navigator.pop(ctx);
              context.pop();
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  static void _showAddSheet(BuildContext context, WidgetRef ref, String groupId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _AddStockSheet(groupId: groupId),
    );
  }
}

// ─── 빈 상태 ──────────────────────────────────────────────────────

class _EmptyBody extends StatelessWidget {
  const _EmptyBody({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_outlined, size: 56, color: AppColors.textHint),
          const SizedBox(height: 16),
          const Text('아직 종목이 없어요',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('종목을 추가해 관리해보세요',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('종목 추가'),
          ),
        ],
      ),
    );
  }
}

// ─── 종목 행 ──────────────────────────────────────────────────────

class _StockRow extends StatelessWidget {
  const _StockRow({
    required this.company,
    required this.onTap,
    required this.onRemove,
  });
  final Company company;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final market = company.market;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primaryLight,
              child: Text(
                company.corpName.isNotEmpty ? company.corpName[0] : '?',
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(company.corpName,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (market != null)
                    Text(
                      market == 'KOSPI' ? '코스피' : market == 'KOSDAQ' ? '코스닥' : market,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline,
                  size: 20, color: AppColors.textHint),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 종목 추가 바텀시트 ───────────────────────────────────────────

class _AddStockSheet extends ConsumerStatefulWidget {
  const _AddStockSheet({required this.groupId});
  final String groupId;

  @override
  ConsumerState<_AddStockSheet> createState() => _AddStockSheetState();
}

class _AddStockSheetState extends ConsumerState<_AddStockSheet> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  final List<Company> _results = [];
  int _page = 1;
  int _total = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String _query = '';
  int _fetchId = 0; // 오래된 응답 무시용

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _search('');
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 150 &&
        !_isLoadingMore &&
        _results.length < _total) {
      _loadMore();
    }
  }

  Future<void> _search(String query) async {
    final id = ++_fetchId;
    setState(() {
      _query = query;
      _isLoading = true;
      _results.clear();
      _page = 1;
      _total = 0;
    });
    await _fetch(id);
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    await _fetch(_fetchId);
  }

  Future<void> _fetch(int id) async {
    try {
      final service = ref.read(companyServiceProvider);
      final res = await service.getCompaniesPage(
        search: _query.isEmpty ? null : _query,
        page: _page,
        limit: 30,
      );
      if (!mounted || id != _fetchId) return; // 오래된 응답이면 무시
      setState(() {
        _results.addAll(res.items);
        _total = res.total;
        _page++;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted || id != _fetchId) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(watchlistGroupsProvider);
    final group = groups.where((g) => g.id == widget.groupId).firstOrNull;
    final notifier = ref.read(watchlistGroupsProvider.notifier);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          // 핸들
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text('종목 추가',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ),
          // 검색바
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SearchBar(
              controller: _searchCtrl,
              hintText: '기업명 검색',
              leading: const Icon(Icons.search, size: 20),
              trailing: _query.isNotEmpty
                  ? [
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          _search('');
                        },
                      )
                    ]
                  : null,
              onChanged: (v) => _search(v.trim()),
              elevation: const WidgetStatePropertyAll(0),
              backgroundColor:
                  const WidgetStatePropertyAll(AppColors.surface),
            ),
          ),
          // 목록
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? const Center(child: Text('검색 결과가 없습니다'))
                    : ListView.separated(
                        controller: _scrollCtrl,
                        itemCount:
                            _results.length + (_isLoadingMore ? 1 : 0),
                        separatorBuilder: (_, _) => const Divider(
                            height: 1, indent: 72, endIndent: 16),
                        itemBuilder: (context, i) {
                          if (i == _results.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                  child: CircularProgressIndicator()),
                            );
                          }
                          final c = _results[i];
                          final inGroup = group?.contains(c.corpCode) ?? false;
                          return _SearchResultRow(
                            company: c,
                            inGroup: inGroup,
                            onToggle: () {
                              if (inGroup) {
                                notifier.removeCompany(widget.groupId, c.corpCode);
                              } else {
                                notifier.addCompany(widget.groupId, c);
                              }
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _SearchResultRow extends StatelessWidget {
  const _SearchResultRow({
    required this.company,
    required this.inGroup,
    required this.onToggle,
  });
  final Company company;
  final bool inGroup;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final market = company.market;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primaryLight,
        child: Text(
          company.corpName.isNotEmpty ? company.corpName[0] : '?',
          style: const TextStyle(
              fontWeight: FontWeight.w700, color: AppColors.primary),
        ),
      ),
      title: Text(company.corpName,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: market != null
          ? Text(
              market == 'KOSPI' ? '코스피' : market == 'KOSDAQ' ? '코스닥' : market,
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textSecondary))
          : null,
      trailing: inGroup
          ? const Icon(Icons.check_circle, color: AppColors.primary)
          : const Icon(Icons.add_circle_outline, color: AppColors.textHint),
      onTap: onToggle,
    );
  }
}
