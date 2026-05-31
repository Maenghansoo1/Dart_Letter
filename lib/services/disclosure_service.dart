import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/disclosure.dart';
import 'api_service.dart';

class DisclosureService {
  Future<List<Disclosure>> getLatest() async {
    final data = await ApiService.instance.get('/disclosures/latest');
    final items = (data as Map<String, dynamic>)['items'] as List;
    return items.map((e) => Disclosure.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Disclosure>> getByCompany(String corpCode) async {
    final data = await ApiService.instance.get('/disclosures/$corpCode');
    final items = (data as Map<String, dynamic>)['items'] as List;
    return items.map((e) => Disclosure.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Disclosure>> getByCorpCodes(List<String> corpCodes) async {
    final data = await ApiService.instance.get(
      '/disclosures/watchlist',
      queryParameters: {'corp_codes': corpCodes.join(',')},
    );
    final items = (data as Map<String, dynamic>)['items'] as List;
    return items.map((e) => Disclosure.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<String> summarize(String rcptNo) async {
    final data = await ApiService.instance.post('/disclosures/$rcptNo/summarize');
    return (data as Map<String, dynamic>)['summary'] as String? ?? '요약을 생성할 수 없습니다';
  }
}

final disclosureServiceProvider = Provider((_) => DisclosureService());
