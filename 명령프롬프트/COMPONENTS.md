# 재사용 컴포넌트

새로 만들지 말고 아래 공통 컴포넌트를 반드시 사용한다.

## 공통 위젯 목록

| 파일 | 용도 | 사용 위치 |
|------|------|----------|
| `stock_card.dart` | 종목 카드 (로고, 이름, 주가, 등락률) | 홈, 탐색, 관심종목 |
| `disclosure_card.dart` | 공시 카드 (제목, AI 요약, 배지) | 홈 피드, 공시 탭 |
| `news_item.dart` | 뉴스 아이템 (제목, 출처, 배지) | 홈 피드, 뉴스 화면 |
| `skeleton_loader.dart` | 스켈레톤 로딩 | 모든 로딩 구간 |
| `error_view.dart` | 에러 화면 + 재시도 버튼 | 모든 에러 상태 |
| `badge_chip.dart` | 배지 칩 | 전체 앱 |
| `disclaimer_bar.dart` | 투자 면책 문구 | 모든 화면 하단 |

## 색상 상수 (AppColors)
```dart
// core/constants.dart
class AppColors {
  static const primary   = Color(0xFF534AB7);
  static const primaryBg = Color(0xFFEEEDFE);
  static const up        = Color(0xFFE24B4A);  // 상승
  static const down      = Color(0xFF378ADD);  // 하락
  static const success   = Color(0xFF1D9E75);
  static const warning   = Color(0xFFBA7517);
  static const danger    = Color(0xFFA32D2D);
}
```

## 문자열 상수 (AppStrings)
```dart
class AppStrings {
  static const disclaimer  = "본 서비스는 투자 참고용이며 투자 권유가 아닙니다";
  static const priceLabel  = "전일 종가 기준";
  static const summaryFail = "요약을 생성할 수 없습니다";
}
```

## BadgeChip 사용법
```dart
enum BadgeType { disclosure, news, issue, etf, dividend, warning }

// 사용
BadgeChip(type: BadgeType.disclosure)
BadgeChip(type: BadgeType.warning, label: "관리종목")
BadgeChip(type: BadgeType.etf, label: "레버리지")
```

## 캐싱 전략
| 데이터 | TTL |
|--------|-----|
| 공시 AI 요약 | 영구 (한번 생성 후 불변) |
| 기업 기본정보 | 24시간 |
| 뉴스 | 1시간 |
| 주가 | 당일 장 마감 후 갱신 |
| 카테고리 분류 | 24시간 |

```python
# 캐시 패턴 (모든 외부 API에 적용)
async def get_with_cache(table, key, fetch_fn, ttl_hours):
    cached = await cache.get(table, key)
    if cached:
        return cached
    data = await fetch_fn()
    await cache.set(table, key, data, ttl_hours)
    return data
```
