class Company {
  final String corpCode;
  final String corpName;
  final String stockCode;
  final String? market;
  final String? sector;
  final double? marketCap;
  final double? dividendYield;
  final DateTime? listedDate;
  final int? closePrice;

  const Company({
    required this.corpCode,
    required this.corpName,
    required this.stockCode,
    this.market,
    this.sector,
    this.marketCap,
    this.dividendYield,
    this.listedDate,
    this.closePrice,
  });

  factory Company.fromJson(Map<String, dynamic> json) => Company(
        corpCode: json['corp_code'] as String,
        corpName: json['corp_name'] as String,
        stockCode: json['stock_code'] as String? ?? '',
        market: json['market'] as String?,
        sector: json['sector'] as String?,
        marketCap: (json['market_cap'] as num?)?.toDouble(),
        dividendYield: (json['dividend_yield'] as num?)?.toDouble(),
        listedDate: json['listed_date'] != null
            ? DateTime.parse(json['listed_date'] as String)
            : null,
        closePrice: json['close_price'] as int?,
      );
}
