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

  Future<Company> getDetail(String corpCode) async {
    final data = await ApiService.instance.get('/companies/$corpCode');
    return Company.fromJson(data as Map<String, dynamic>);
  }
}

final companyServiceProvider = Provider((_) => CompanyService());
