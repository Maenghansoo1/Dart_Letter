import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/disclosure_provider.dart';
import '../../../widgets/disclosure_card.dart';
import '../../../widgets/error_view.dart';
import '../../../widgets/skeleton_loader.dart';

class DisclosureTab extends ConsumerWidget {
  const DisclosureTab({super.key, required this.corpCode});

  final String corpCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disclosuresAsync = ref.watch(companyDisclosuresProvider(corpCode));

    return RefreshIndicator(
      onRefresh: () => ref.refresh(companyDisclosuresProvider(corpCode).future),
      child: disclosuresAsync.when(
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: 5,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, _) => const DisclosureCardSkeleton(),
        ),
        error: (_, _) => ErrorView(
          message: '공시를 불러오지 못했습니다',
          onRetry: () => ref.invalidate(companyDisclosuresProvider(corpCode)),
        ),
        data: (list) => list.isEmpty
            ? const Center(child: Text('등록된 공시가 없습니다'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) =>
                    DisclosureCard(disclosure: list[index]),
              ),
      ),
    );
  }
}
