import 'package:flutter/material.dart';
import '../../stock_community_screen.dart';

class CommunityTab extends StatelessWidget {
  const CommunityTab({
    super.key,
    required this.corpCode,
    required this.corpName,
  });

  final String corpCode;
  final String corpName;

  @override
  Widget build(BuildContext context) {
    return StockCommunityScreen(corpCode: corpCode, corpName: corpName);
  }
}
