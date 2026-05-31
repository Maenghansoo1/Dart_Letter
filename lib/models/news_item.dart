class NewsItem {
  final String title;
  final String link;
  final String description;
  final String pubDate;
  final String category; // '공시' | '과거이슈' | '뉴스'

  const NewsItem({
    required this.title,
    required this.link,
    required this.description,
    required this.pubDate,
    required this.category,
  });

  factory NewsItem.fromJson(Map<String, dynamic> json) => NewsItem(
        title: _stripHtml(json['title'] as String),
        link: json['link'] as String,
        description: _stripHtml(json['description'] as String? ?? ''),
        pubDate: json['pub_date'] as String? ?? '',
        category: json['category'] as String? ?? '뉴스',
      );

  static String _stripHtml(String html) =>
      html.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll('&amp;', '&').replaceAll('&quot;', '"');
}
