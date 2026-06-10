import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/company.dart';
import '../models/watchlist_group.dart';

class WatchlistGroupNotifier extends Notifier<List<WatchlistGroup>> {
  @override
  List<WatchlistGroup> build() => [];

  void addGroup(String name) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    state = [...state, WatchlistGroup(id: id, name: name)];
  }

  void removeGroup(String id) {
    state = state.where((g) => g.id != id).toList();
  }

  void renameGroup(String id, String newName) {
    state = [
      for (final g in state) g.id == id ? g.copyWith(name: newName) : g,
    ];
  }

  void addCompany(String groupId, Company company) {
    state = [
      for (final g in state)
        g.id == groupId && !g.contains(company.corpCode)
            ? g.copyWith(companies: [...g.companies, company])
            : g,
    ];
  }

  void removeCompany(String groupId, String corpCode) {
    state = [
      for (final g in state)
        g.id == groupId
            ? g.copyWith(
                companies: g.companies
                    .where((c) => c.corpCode != corpCode)
                    .toList())
            : g,
    ];
  }

  bool isInAnyGroup(String corpCode) =>
      state.any((g) => g.contains(corpCode));

  List<WatchlistGroup> groupsContaining(String corpCode) =>
      state.where((g) => g.contains(corpCode)).toList();
}

final watchlistGroupsProvider =
    NotifierProvider<WatchlistGroupNotifier, List<WatchlistGroup>>(
  WatchlistGroupNotifier.new,
);

// 기존 코드 호환용 — 전체 즐겨찾기 corp_code 목록
final watchlistProvider = Provider<List<String>>((ref) {
  final groups = ref.watch(watchlistGroupsProvider);
  return groups.expand((g) => g.companies.map((c) => c.corpCode)).toSet().toList();
});
