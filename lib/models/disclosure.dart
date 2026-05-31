class Disclosure {
  final String rcptNo;
  final String corpCode;
  final String corpName;
  final String reportNm;
  final String rcptDt;
  final String? summary;
  final String? rawContent;

  const Disclosure({
    required this.rcptNo,
    required this.corpCode,
    required this.corpName,
    required this.reportNm,
    required this.rcptDt,
    this.summary,
    this.rawContent,
  });

  factory Disclosure.fromJson(Map<String, dynamic> json) => Disclosure(
        rcptNo: json['rcept_no'] as String,
        corpCode: json['corp_code'] as String? ?? '',
        corpName: json['corp_name'] as String,
        reportNm: json['report_nm'] as String,
        rcptDt: json['rcept_dt'] as String,
        summary: json['summary'] as String?,
        rawContent: json['raw_content'] as String?,
      );

  String get formattedDate {
    if (rcptDt.length != 8) return rcptDt;
    return '${rcptDt.substring(0, 4)}.${rcptDt.substring(4, 6)}.${rcptDt.substring(6, 8)}';
  }
}
