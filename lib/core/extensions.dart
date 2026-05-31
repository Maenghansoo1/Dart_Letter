extension StringExt on String {
  String get htmlStripped => replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>');

  // "20240315" → "2024.03.15"
  String get dartDateFormatted {
    if (length != 8) return this;
    return '${substring(0, 4)}.${substring(4, 6)}.${substring(6, 8)}';
  }
}

extension DateTimeExt on DateTime {
  String get relativeTime {
    final diff = DateTime.now().difference(this);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return '$month.$day';
  }

  String get shortDate => '$month.$day';
}

extension IntExt on int {
  // 1234567 → "1,234,567"
  String get formatted {
    final s = toString();
    final buffer = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(',');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }
}
