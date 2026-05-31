import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants.dart';
import '../../../providers/company_provider.dart';
import '../../../providers/disclosure_provider.dart';
import '../../../widgets/badge_chip.dart';
import '../../../widgets/disclosure_card.dart';
import '../../../widgets/error_view.dart';

class SummaryTab extends ConsumerWidget {
  const SummaryTab({super.key, required this.corpCode});

  final String corpCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companyAsync = ref.watch(companyDetailProvider(corpCode));
    final disclosuresAsync = ref.watch(companyDisclosuresProvider(corpCode));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        companyAsync.when(
          loading: () => const _InfoCardSkeleton(),
          error: (_, _) => ErrorView(
            message: '기업 정보를 불러오지 못했습니다',
            onRetry: () => ref.invalidate(companyDetailProvider(corpCode)),
          ),
          data: (company) => _CompanyInfoCard(company: company),
        ),
        const SizedBox(height: 16),
        const _SectionTitle(title: '최근 공시'),
        const SizedBox(height: 8),
        disclosuresAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => ErrorView(
            message: '공시를 불러오지 못했습니다',
            onRetry: () => ref.invalidate(companyDisclosuresProvider(corpCode)),
          ),
          data: (list) {
            final recent = list.take(3).toList();
            if (recent.isEmpty) return const Text('등록된 공시가 없습니다');
            return Column(
              children: recent
                  .map((d) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: DisclosureCard(disclosure: d),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _CompanyInfoCard extends StatelessWidget {
  const _CompanyInfoCard({required this.company});

  final dynamic company;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  company.corpName as String,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              if (company.market != null)
                BadgeChip(label: company.market as String),
            ],
          ),
          if (company.sector != null) ...[
            const SizedBox(height: 4),
            Text(company.sector as String,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
          ],
          const Divider(height: 24),
          _InfoRow(label: '종목코드', value: company.stockCode as String),
          if (company.dividendYield != null)
            _InfoRow(
              label: '배당수익률',
              value:
                  '${(company.dividendYield as double).toStringAsFixed(2)}%',
            ),
          if (company.listedDate != null)
            _InfoRow(
              label: '상장일',
              value: (company.listedDate as DateTime)
                  .toString()
                  .substring(0, 10),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
          ),
          Text(value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700));
  }
}

class _InfoCardSkeleton extends StatelessWidget {
  const _InfoCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
