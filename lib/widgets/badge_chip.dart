import 'package:flutter/material.dart';
import '../core/constants.dart';

class BadgeChip extends StatelessWidget {
  const BadgeChip({
    super.key,
    required this.label,
    this.color = AppColors.primary,
    this.filled = false,
  });

  final String label;
  final Color color;

  /// true: 배경색 채움 / false: 연한 배경 + 진한 텍스트
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: filled ? Colors.white : color,
        ),
      ),
    );
  }
}

/// 카테고리별 색상을 자동으로 잡아주는 뉴스 전용 배지
class NewsCategoryBadge extends StatelessWidget {
  const NewsCategoryBadge({super.key, required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final color = CategoryNames.newsCategory[category] ?? AppColors.textSecondary;
    return BadgeChip(label: category, color: color);
  }
}
