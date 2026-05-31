import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/disclosure.dart';
import 'badge_chip.dart';

class DisclosureCard extends StatelessWidget {
  const DisclosureCard({super.key, required this.disclosure});

  final Disclosure disclosure;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              BadgeChip(label: disclosure.corpName),
              const SizedBox(width: 8),
              Text(
                disclosure.formattedDate,
                style: const TextStyle(fontSize: 12, color: AppColors.textHint),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            disclosure.reportNm,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (disclosure.summary != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.summaryBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                disclosure.summary!,
                style: const TextStyle(
                    fontSize: 13, height: 1.5, color: AppColors.textSecondary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
