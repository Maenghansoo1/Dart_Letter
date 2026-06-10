import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/news_item.dart';
import 'api_service.dart';

class NewsService {
  Future<List<String>> getCategories() async {
    final data = await ApiService.instance.get('/news/categories');
    return (data as List).cast<String>();
  }

  Future<List<NewsItem>> getLatest({String category = '전체'}) async {
    final data = await ApiService.instance.get(
      '/news/latest',
      queryParameters: {'category': category},
    );
    return (data as List).map((e) => NewsItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<NewsItem>> getByCompany(String corpName) async {
    final data = await ApiService.instance.get('/news/$corpName');
    return (data as List).map((e) => NewsItem.fromJson(e as Map<String, dynamic>)).toList();
  }
}

final newsServiceProvider = Provider((_) => NewsService());
