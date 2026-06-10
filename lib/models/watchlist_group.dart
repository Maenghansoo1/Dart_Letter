import 'company.dart';

class WatchlistGroup {
  final String id;
  final String name;
  final List<Company> companies;

  const WatchlistGroup({
    required this.id,
    required this.name,
    this.companies = const [],
  });

  WatchlistGroup copyWith({String? name, List<Company>? companies}) =>
      WatchlistGroup(
        id: id,
        name: name ?? this.name,
        companies: companies ?? this.companies,
      );

  bool contains(String corpCode) =>
      companies.any((c) => c.corpCode == corpCode);
}
