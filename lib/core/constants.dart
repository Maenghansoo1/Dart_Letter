import 'package:flutter/material.dart';

class AppColors {
  // Brand
  static const primary = Color(0xFF534AB7);
  static const primaryLight = Color(0xFFF0EFFE);

  // Stock price
  static const priceUp = Color(0xFFE24B4A);
  static const priceDown = Color(0xFF378ADD);

  // Text
  static const textPrimary = Color(0xFF1A1A2E);
  static const textSecondary = Color(0xFF666666);
  static const textHint = Color(0xFF9E9E9E);

  // UI
  static const divider = Color(0xFFEEEEEE);
  static const surface = Color(0xFFF5F5F5);
  static const cardBg = Colors.white;
  static const summaryBg = Color(0xFFF8F8FF);
}

class AppStrings {
  static const appName = '다트레터';
  static const disclaimer = '본 서비스는 투자 참고용이며 투자 권유가 아닙니다';
  static const priceBasis = '전일 종가 기준';
  static const errorRetry = '다시 시도';
}

class CategoryNames {
  static const List<String> market = ['전체', '대형주', '소형주', '배당주', '고배당', 'ETF', '신규상장'];

  static const Map<String, Color> newsCategory = {
    '공시': AppColors.primary,
    '과거이슈': Color(0xFFE65100),
    '뉴스': Color(0xFF2E7D32),
  };
}
