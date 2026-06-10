import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/company.dart';
import 'api_service.dart';

class CompanyService {
  Future<List<Company>> getCompanies({String? category}) async {
    final data = await ApiService.instance.get(
      '/companies',
      queryParameters:
          (category == null || category == '전체') ? null : {'category': category},
    );
    final items = (data as Map<String, dynamic>)['items'] as List;
    return items.map((e) => Company.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<({List<Company> items, int total})> getCompaniesPage({
    String? market,
    String? search,
    String? industryCategory,
    int page = 1,
    int limit = 30,
  }) async {
    final params = <String, dynamic>{'page': page, 'limit': limit};
    if (market != null && market != '전체') params['market'] = market;
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (industryCategory != null && industryCategory != '전체') {
      params['industry_category'] = industryCategory;
    }

    final data = await ApiService.instance.get('/companies', queryParameters: params);
    final json = data as Map<String, dynamic>;
    final items = (json['items'] as List)
        .map((e) => Company.fromJson(e as Map<String, dynamic>))
        .toList();
    return (items: items, total: (json['total'] as num?)?.toInt() ?? 0);
  }

  Future<Company> getDetail(String corpCode) async {
    final data = await ApiService.instance.get('/companies/$corpCode');
    return Company.fromJson(data as Map<String, dynamic>);
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final data = await ApiService.instance.get('/categories');
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<List<Company>> getCategoryStocks(String category, {int page = 1}) async {
    final data = await ApiService.instance.get(
      '/categories/$category/stocks',
      queryParameters: {'page': page, 'limit': 20},
    );
    final items = (data as Map<String, dynamic>)['items'] as List;
    return items.map((e) => Company.fromJson(e as Map<String, dynamic>)).toList();
  }
}

final companyServiceProvider = Provider((_) => CompanyService());
