import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants.dart';
import '../providers/company_provider.dart';
import '../providers/watchlist_provider.dart';
import '../widgets/company_card.dart';
import '../widgets/error_view.dart';
import '../widgets/skeleton_loader.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = '전체';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final companiesAsync = ref.watch(companiesProvider(_selectedCategory));

    return Scaffold(
      appBar: AppBar(title: const Text('탐색')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: SearchBar(
              controller: _searchController,
              hintText: '기업명 검색',
              leading: const Icon(Icons.search),
              onChanged: (_) => setState(() {}),
              elevation: const WidgetStatePropertyAll(0),
              backgroundColor: const WidgetStatePropertyAll(AppColors.surface),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              itemCount: CategoryNames.market.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = CategoryNames.market[index];
                final selected = cat == _selectedCategory;
                return ChoiceChip(
                  label: Text(cat),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedCategory = cat),
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : null,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: companiesAsync.when(
              loading: () => ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: 8,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, _) => const CompanyCardSkeleton(),
              ),
              error: (_, _) => ErrorView(
                message: '기업 목록을 불러오지 못했습니다',
                onRetry: () => ref.invalidate(companiesProvider),
              ),
              data: (companies) {
                final query = _searchController.text.trim().toLowerCase();
                final filtered = query.isEmpty
                    ? companies
                    : companies
                        .where((c) => c.corpName.toLowerCase().contains(query))
                        .toList();
                if (filtered.isEmpty) {
                  return const Center(child: Text('검색 결과가 없습니다'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final company = filtered[index];
                    final watchlist = ref.watch(watchlistProvider);
                    final inWatchlist = watchlist.contains(company.corpCode);
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
                              onPressed: () => ref
                                  .read(watchlistProvider.notifier)
                                  .toggle(company.corpCode),
                            ),
                          ),
                        ],
                      ),
                    );
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
