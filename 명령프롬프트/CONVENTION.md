# 코드 컨벤션

## Python 네이밍
```python
corp_code = "005930"           # 변수: snake_case
def get_disclosure(): ...      # 함수: snake_case
class DisclosureService: ...   # 클래스: PascalCase
MAX_RETRY = 3                  # 상수: UPPER_SNAKE_CASE
```

## Python 함수 규칙
- 함수 하나는 한 가지 일만
- 50줄 초과 시 분리
- 타입 힌트 필수
- docstring 작성 (한국어 허용)

```python
async def get_disclosure_summary(rcept_no: str) -> dict:
    """
    공시 번호로 AI 요약을 반환한다.
    캐시 확인 → 없으면 Gemini API 호출 → 저장 후 반환.
    """
    ...
```

## Python 에러 처리
```python
async def fetch_dart(rcept_no: str) -> dict:
    try:
        res = await httpx.get(DART_URL, params={"rcept_no": rcept_no})
        res.raise_for_status()
        return res.json()
    except httpx.TimeoutException:
        logger.error(f"DART 타임아웃: {rcept_no}")
        raise HTTPException(status_code=504, detail="시간이 초과됐습니다")
    except httpx.HTTPStatusError as e:
        logger.error(f"DART 오류: {e.response.status_code}")
        raise HTTPException(status_code=502, detail="데이터를 불러올 수 없습니다")
```

## Dart 네이밍
```dart
String corpCode = '005930';       // 변수: camelCase
Future<void> fetchData() {}       // 함수: camelCase
class DisclosureCard {}           // 클래스: PascalCase
const primaryColor = Color(...);  // 상수: camelCase
// 파일명: snake_case → disclosure_card.dart
```

## Flutter 위젯 규칙
- build() 50줄 초과 시 위젯 분리
- 재사용 UI는 widgets/ 에 공통 컴포넌트로 분리
- 리스트는 반드시 ListView.builder 사용
- 이미지는 CachedNetworkImage 사용

## Riverpod 상태 관리
```dart
// Provider 정의
@riverpod
Future<List<Disclosure>> disclosures(DisclosuresRef ref, String corpCode) async {
  return ref.read(disclosureServiceProvider).getDisclosures(corpCode);
}

// 화면에서 사용 — 로딩/에러/데이터 세 가지 상태 항상 처리
state.when(
  loading: () => SkeletonLoader(),
  error: (e, _) => ErrorView(e),
  data: (list) => DisclosureList(list),
);
```

## 에러 코드 표준
| 상황 | 코드 | 메시지 |
|------|------|--------|
| DART 한도 초과 | 429 | 잠시 후 다시 시도해주세요 |
| 타임아웃 | 504 | 시간이 초과됐습니다 |
| 데이터 없음 | 404 | 데이터를 찾을 수 없습니다 |
| 인증 실패 | 401 | 로그인이 필요합니다 |
| 권한 없음 | 403 | 접근 권한이 없습니다 |
