import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/news_item.dart';
import '../services/news_service.dart';

final latestNewsProvider = FutureProvider<List<NewsItem>>((ref) {
  return ref.watch(newsServiceProvider).getLatest();
});

final companyNewsProvider =
    FutureProvider.family<List<NewsItem>, String>((ref, corpName) {
  return ref.watch(newsServiceProvider).getByCompany(corpName);
});
