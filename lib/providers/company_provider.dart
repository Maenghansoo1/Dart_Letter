import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/company.dart';
import '../services/company_service.dart';

final companiesProvider =
    FutureProvider.family<List<Company>, String>((ref, category) {
  if (category == '전체') {
    return ref.watch(companyServiceProvider).getCompanies();
  }
  return ref.watch(companyServiceProvider).getCategoryStocks(category);
});

final companyDetailProvider =
    FutureProvider.family<Company, String>((ref, corpCode) {
  return ref.watch(companyServiceProvider).getDetail(corpCode);
});

final categoriesProvider = FutureProvider<List<String>>((ref) async {
  final raw = await ref.watch(companyServiceProvider).getCategories();
  return ['전체', ...raw.map((e) => e['category'] as String)];
});
