import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/news_item.dart';
import 'api_service.dart';

class NewsService {
  Future<List<NewsItem>> getLatest() async {
    final data = await ApiService.instance.get('/news/latest');
    return (data as List).map((e) => NewsItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<NewsItem>> getByCompany(String corpName) async {
    final data = await ApiService.instance.get('/news/$corpName');
    return (data as List).map((e) => NewsItem.fromJson(e as Map<String, dynamic>)).toList();
  }
}

final newsServiceProvider = Provider((_) => NewsService());
