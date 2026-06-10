import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants.dart';
import '../models/company.dart';
import '../providers/watchlist_provider.dart';
import '../services/company_service.dart';
import '../widgets/company_card.dart';
import '../widgets/error_view.dart';
import '../widgets/skeleton_loader.dart';

const _pageSize = 30;

// ─── 메인 탐색 화면 ───────────────────────────────────────────────

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  // null = 시장 목록 화면, 'KOSPI'/'KOSDAQ' = 종목 목록 화면
  String? _selectedMarket;
  String _search = '';

  void _onSearchChanged(String value) {
    setState(() => _search = value.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedMarket == null
            ? '탐색'
            : _selectedMarket == 'KOSPI'
                ? '코스피'
                : _selectedMarket == 'KOSDAQ'
                    ? '코스닥'
                    : '전체'),
        leading: _selectedMarket != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() {
                  _selectedMarket = null;
                  _search = '';
                }),
              )
            : null,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: _SearchBar(
              search: _search,
              onChanged: _onSearchChanged,
              onClear: () => _onSearchChanged(''),
            ),
          ),
          Expanded(
            child: _selectedMarket == null
                ? _MarketList(
                    search: _search,
                    onMarketTap: (m) => setState(() {
                      _selectedMarket = m;
                      _search = '';
                    }),
                  )
                : _CompanyList(
                    market: _selectedMarket!,
                    search: _search,
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── 검색바 ───────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.search,
    required this.onChanged,
    required this.onClear,
  });

  final String search;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return SearchBar(
      hintText: '기업명 검색',
      leading: const Icon(Icons.search),
      trailing: search.isNotEmpty
          ? [IconButton(icon: const Icon(Icons.close), onPressed: onClear)]
          : null,
      onChanged: onChanged,
      elevation: const WidgetStatePropertyAll(0),
      backgroundColor: const WidgetStatePropertyAll(AppColors.surface),
    );
  }
}

// ─── 시장 선택 리스트 ─────────────────────────────────────────────

class _MarketList extends StatelessWidget {
  const _MarketList({required this.search, required this.onMarketTap});

  final String search;
  final ValueChanged<String> onMarketTap;

  static const _items = [
    (market: 'ALL', label: '전체', icon: Icons.list_alt, desc: '코스피·코스닥 전체 종목'),
    (market: 'KOSPI', label: '코스피', icon: Icons.trending_up, desc: '유가증권시장 상장 종목'),
    (market: 'KOSDAQ', label: '코스닥', icon: Icons.bar_chart, desc: '코스닥시장 상장 종목'),
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = search.isEmpty
        ? _items
        : _items.where((e) => e.label.contains(search)).toList();

    if (filtered.isEmpty) {
      return const Center(child: Text('검색 결과가 없습니다'));
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _MarketTile(
        item: filtered[i],
        onTap: () => onMarketTap(filtered[i].market),
      ),
    );
  }
}

class _MarketTile extends StatelessWidget {
  const _MarketTile({required this.item, required this.onTap});

  final ({String market, String label, IconData icon, String desc}) item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.label,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(item.desc,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

// ─── 업종 카테고리 ────────────────────────────────────────────────

const _industryCategories = [
  '전체', '반도체', '바이오', '2차전지', '자동차', '은행',
  '보험', '증권', '건설', '화학', '철강', '유통',
  '게임/엔터', '통신', '부동산', '식품', '에너지', '항공/운송', 'IT서비스',
];

// ─── 종목 목록 (무한 스크롤) ──────────────────────────────────────

class _CompanyList extends ConsumerStatefulWidget {
  const _CompanyList({required this.market, required this.search});

  final String market;
  final String search;

  @override
  ConsumerState<_CompanyList> createState() => _CompanyListState();
}

class _CompanyListState extends ConsumerState<_CompanyList> {
  final _scrollController = ScrollController();

  final List<Company> _companies = [];
  int _page = 1;
  int _total = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  int _fetchId = 0; // 오래된 응답 무시용
  String _selectedCategory = '전체';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load(reset: true);
  }

  @override
  void didUpdateWidget(_CompanyList old) {
    super.didUpdateWidget(old);
    if (widget.market != old.market || widget.search != old.search) {
      _selectedCategory = '전체';
      _load(reset: true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool get _hasMore => _companies.length < _total;

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _load();
    }
  }

  Future<void> _load({bool reset = false}) async {
    final int id;
    if (reset) {
      id = ++_fetchId;
      setState(() {
        _isLoading = true;
        _error = null;
        _companies.clear();
        _page = 1;
        _total = 0;
      });
    } else {
      if (_isLoadingMore) return;
      id = _fetchId;
      setState(() => _isLoadingMore = true);
    }

    try {
      final service = ref.read(companyServiceProvider);
      final result = await service.getCompaniesPage(
        market: widget.market == 'ALL' ? null : widget.market,
        search: widget.search.isEmpty ? null : widget.search,
        industryCategory: _selectedCategory == '전체' ? null : _selectedCategory,
        page: _page,
        limit: _pageSize,
      );
      if (!mounted || id != _fetchId) return; // 오래된 응답이면 무시
      setState(() {
        _companies.addAll(result.items);
        _total = result.total;
        _page++;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted || id != _fetchId) return;
      setState(() {
        _error = '기업 목록을 불러오지 못했습니다';
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: _industryCategories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final cat = _industryCategories[i];
          final selected = cat == _selectedCategory;
          return ChoiceChip(
            label: Text(cat),
            selected: selected,
            onSelected: (_) {
              if (cat == _selectedCategory) return;
              setState(() => _selectedCategory = cat);
              _load(reset: true);
            },
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontSize: 13,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
          );
        },
      ),
    );
  }

  void _showGroupPicker(BuildContext context, Company company) {
    final groups = ref.read(watchlistGroupsProvider);
    final notifier = ref.read(watchlistGroupsProvider.notifier);
    final nameCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text('리스트에 추가: ${company.corpName}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            if (groups.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text('아직 리스트가 없어요. 새로 만들어보세요.',
                    style: TextStyle(color: AppColors.textSecondary)),
              )
            else
              ...groups.map((g) {
                final has = g.contains(company.corpCode);
                return ListTile(
                  leading: const Icon(Icons.folder_outlined,
                      color: AppColors.primary),
                  title: Text(g.name),
                  trailing: has
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    if (has) {
                      notifier.removeCompany(g.id, company.corpCode);
                    } else {
                      notifier.addCompany(g.id, company);
                    }
                    Navigator.pop(ctx);
                  },
                );
              }),
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                          hintText: '새 리스트 이름', isDense: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) return;
                      notifier.addGroup(name);
                      final newGroup = ref.read(watchlistGroupsProvider).last;
                      notifier.addCompany(newGroup.id, company);
                      Navigator.pop(ctx);
                    },
                    child: const Text('만들기'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Column(
        children: [
          _buildCategoryChips(),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: 8,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, _) => const CompanyCardSkeleton(),
            ),
          ),
        ],
      );
    }

    if (_error != null) {
      return ErrorView(message: _error!, onRetry: () => _load(reset: true));
    }

    if (_companies.isEmpty) {
      return const Center(child: Text('검색 결과가 없습니다'));
    }

    return Column(
      children: [
        _buildCategoryChips(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('총 $_total 종목',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _load(reset: true),
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              itemCount: _companies.length + (_isLoadingMore ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                if (i == _companies.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final company = _companies[i];
                final inWatchlist = ref
                    .watch(watchlistGroupsProvider.notifier)
                    .isInAnyGroup(company.corpCode);
                return GestureDetector(
                  onTap: () => context.push('/company/${company.corpCode}'),
                  child: Stack(
                    children: [
                      CompanyCard(company: company),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          icon: Icon(
                            inWatchlist
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            color: inWatchlist
                                ? AppColors.primary
                                : AppColors.textHint,
                          ),
                          onPressed: () => _showGroupPicker(context, company),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
