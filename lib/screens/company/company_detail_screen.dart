import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../core/extensions.dart';
import '../../providers/company_provider.dart';
import '../../widgets/disclaimer_bar.dart';
import '../../widgets/error_view.dart';
import 'tabs/summary_tab.dart';
import 'tabs/disclosure_tab.dart';
import 'tabs/news_tab.dart';
import 'tabs/issue_tab.dart';
import 'tabs/community_tab.dart';

class CompanyDetailScreen extends ConsumerWidget {
  const CompanyDetailScreen({super.key, required this.corpCode});

  final String corpCode;

  static const _tabs = ['요약', '공시', '뉴스', '이슈', '커뮤니티'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companyAsync = ref.watch(companyDetailProvider(corpCode));

    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: companyAsync.maybeWhen(
            data: (c) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.corpName),
                if (c.market != null)
                  Text(
                    c.market!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
            orElse: () => const Text('기업 정보'),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.bookmark_border),
              onPressed: () {},
            ),
          ],
          bottom: TabBar(
            tabs: _tabs.map((t) => Tab(text: t)).toList(),
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            labelStyle: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: companyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => ErrorView(
            message: '기업 정보를 불러오지 못했습니다',
            onRetry: () => ref.invalidate(companyDetailProvider(corpCode)),
          ),
          data: (company) => Column(
            children: [
              _StockPriceBar(closePrice: company.closePrice),
              Expanded(
                child: TabBarView(
                  children: [
                    SummaryTab(corpCode: corpCode),
                    DisclosureTab(corpCode: corpCode),
                    NewsTab(corpName: company.corpName),
                    IssueTab(corpCode: corpCode),
                    CommunityTab(corpCode: corpCode),
                  ],
                ),
              ),
              const DisclaimerBottomBar(),
            ],
          ),
        ),
      ),
    );
  }
}

class _StockPriceBar extends StatelessWidget {
  const _StockPriceBar({required this.closePrice});

  final int? closePrice;

  @override
  Widget build(BuildContext context) {
    if (closePrice == null) return const SizedBox.shrink();
    return Container(
      color: AppColors.cardBg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Text(
            closePrice!.formatted,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 4),
          const Text('원',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const Spacer(),
          const Text(
            AppStrings.priceBasis,
            style: TextStyle(fontSize: 12, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}
