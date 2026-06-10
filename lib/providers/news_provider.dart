import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/news_item.dart';
import '../services/news_service.dart';

final newsCategoriesProvider = FutureProvider<List<String>>((ref) {
  return ref.watch(newsServiceProvider).getCategories();
});

final latestNewsProvider =
    FutureProvider.family<List<NewsItem>, String>((ref, category) {
  return ref.watch(newsServiceProvider).getLatest(category: category);
});

final companyNewsProvider =
    FutureProvider.family<List<NewsItem>, String>((ref, corpName) {
  return ref.watch(newsServiceProvider).getByCompany(corpName);
});
