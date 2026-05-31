import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/company.dart';
import '../services/company_service.dart';

class WatchlistNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [];

  void add(String corpCode) {
    if (!state.contains(corpCode)) state = [...state, corpCode];
  }

  void remove(String corpCode) {
    state = state.where((c) => c != corpCode).toList();
  }

  bool contains(String corpCode) => state.contains(corpCode);

  void toggle(String corpCode) {
    contains(corpCode) ? remove(corpCode) : add(corpCode);
  }
}

/// 관심 종목 코드 목록
final watchlistProvider =
    NotifierProvider<WatchlistNotifier, List<String>>(WatchlistNotifier.new);

/// 관심 종목 Company 객체 목록
final watchlistCompaniesProvider = FutureProvider<List<Company>>((ref) async {
  final codes = ref.watch(watchlistProvider);
  if (codes.isEmpty) return [];
  final service = ref.watch(companyServiceProvider);
  return Future.wait(codes.map(service.getDetail));
});
