# API 명세

## 기업
- `GET /companies` — 전체 기업 목록 (카테고리 필터, 페이지네이션)
- `GET /companies/{corp_code}` — 기업 상세 (대표이사, 업종, 설립일)

## 공시
- `GET /disclosures/{corp_code}` — 기업별 공시 목록
- `GET /disclosures/{rcept_no}/detail` — 공시 원문
- `POST /disclosures/{rcept_no}/summarize` — AI 요약 생성

## 재무
- `GET /financials/{corp_code}` — 재무제표 (매출, 영업이익, PER, PBR, 부채비율)

## 뉴스
- `GET /news/{corp_name}` — 기업명으로 뉴스 검색 (최신 20개)
- `GET /news/latest` — 관심종목 통합 뉴스 피드

## 카테고리
- `GET /categories` — 전체 카테고리 목록 + 종목 수
- `GET /categories/{category_name}/stocks` — 카테고리별 종목 (정렬, 페이지네이션)
- `POST /categories/refresh` — 전체 종목 카테고리 재분류

## 커뮤니티 (인증 필요)
- `GET /community/{corp_code}/posts` — 종목별 게시글
- `POST /community/posts` — 게시글 작성
- `POST /community/posts/{post_id}/comments` — 댓글 작성
- `POST /community/posts/{post_id}/like` — 좋아요

## 공통 응답 형식
```json
{
  "success": true,
  "data": { },
  "error": null
}
```

## 페이지네이션
```
GET /companies?page=1&limit=20&category=배당주&sort=market_cap
```

## 외부 API 한도
| API | 일 한도 | 주의 |
|-----|--------|------|
| DART | 10,000건 | 실적 시즌(1,4,7,10월) 집중 |
| 네이버 | 25,000건 | 인기 종목 우선 캐싱 |
| KRX | 1,000건 | 일별 데이터, 캐싱 필수 |
| Gemini | 무제한 | 비용 발생, 캐싱 철저히 |
