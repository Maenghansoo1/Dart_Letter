import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/company.dart';
import '../services/company_service.dart';

final companiesProvider =
    FutureProvider.family<List<Company>, String>((ref, category) {
  return ref.watch(companyServiceProvider).getCompanies(category: category);
});

final companyDetailProvider =
    FutureProvider.family<Company, String>((ref, corpCode) {
  return ref.watch(companyServiceProvider).getDetail(corpCode);
});
