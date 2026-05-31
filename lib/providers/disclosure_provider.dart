import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/disclosure.dart';
import '../services/disclosure_service.dart';
import 'watchlist_provider.dart';

final latestDisclosuresProvider = FutureProvider<List<Disclosure>>((ref) {
  return ref.watch(disclosureServiceProvider).getLatest();
});

final watchlistDisclosuresProvider = FutureProvider<List<Disclosure>>((ref) {
  final corpCodes = ref.watch(watchlistProvider);
  if (corpCodes.isEmpty) return Future.value([]);
  return ref.watch(disclosureServiceProvider).getByCorpCodes(corpCodes);
});

final companyDisclosuresProvider =
    FutureProvider.family<List<Disclosure>, String>((ref, corpCode) {
  return ref.watch(disclosureServiceProvider).getByCompany(corpCode);
});

final disclosureSummaryProvider =
    FutureProvider.family<String, String>((ref, rcptNo) {
  return ref.watch(disclosureServiceProvider).summarize(rcptNo);
});
