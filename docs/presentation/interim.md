---
marp: true
theme: default
paginate: true
style: |
  :root {
    --primary: #534AB7;
    --primary-light: #7B74D4;
    --primary-bg: #EEEDFE;
    --bg: #0A0A0F;
    --bg2: #12121A;
    --text: #FFFFFF;
    --text2: #A0A0B8;
    --done: #1D9E75;
    --active: #F5A623;
    --danger: #E24B4A;
  }
  section {
    background: #0A0A0F;
    color: #FFFFFF;
    font-family: 'Noto Sans KR', sans-serif;
    padding: 60px 72px;
  }
  h1 { color: #7B74D4; font-size: 2.2em; margin-bottom: 8px; }
  h2 { color: #FFFFFF; font-size: 1.6em; border-left: 4px solid #534AB7; padding-left: 16px; margin-bottom: 32px; }
  h3 { color: #7B74D4; font-size: 1.1em; }
  p, li { color: #A0A0B8; font-size: 0.95em; line-height: 1.8; }
  strong { color: #FFFFFF; }
  table { width: 100%; border-collapse: collapse; font-size: 0.85em; }
  th { background: #534AB7; color: #FFFFFF; padding: 10px 16px; text-align: left; }
  td { padding: 10px 16px; border-bottom: 1px solid #1A1A26; color: #A0A0B8; }
  code { background: #1A1A26; color: #7B74D4; padding: 2px 8px; border-radius: 4px; font-size: 0.85em; }
  blockquote { border-left: 3px solid #534AB7; padding-left: 20px; margin: 16px 0; background: #12121A; padding: 16px 20px; border-radius: 0 8px 8px 0; }
  blockquote p { color: #FFFFFF; font-size: 1em; }
  .cover-sub { color: #A0A0B8; font-size: 1em; margin-top: 8px; }
  header, footer { color: #5A5A7A; font-size: 0.75em; }
  section::after { color: #5A5A7A; font-size: 0.75em; }
---

<!-- 표지 -->
# 다트레터 (DartLetter)
## 중간 발표

<br>

**DART 공시를 AI가 쉽게 풀어주는 기업분석 앱**

<br>

발표자: [이름] · 2025년 5월

---

## 1. 문제 정의

<br>

**국내 개인 투자자 1,400만 명** — 하지만 공시를 제대로 이해하는 사람은 극소수

<br>

| 문제 | 내용 |
|------|------|
| 📄 난해한 언어 | 공시 원문은 법률·회계 전문용어로 가득, 평균 32페이지 |
| ⏰ 정보 지연 | 중요한 공시가 올라와도 알림 없음, 평균 2.3시간 지연 |
| 🔍 분산된 정보 | 공시는 DART, 뉴스는 포털, 주가는 증권앱 — 3~5개 앱 오가야 함 |

<br>

> **한 줄 가치 제안:**
> AI가 어려운 공시를 쉬운 말로 풀어주어 누구나 기업을 분석할 수 있게 한다

---

## 2. 사용자 시나리오

<br>

> 직장인 김수현(32세)이 퇴근 후 관심 종목 삼성전자의
> 새 공시 알림을 받고 앱을 열면,
> AI가 "반도체 업황 회복으로 영업이익이 38% 증가했으며
> HBM 수요 증가가 주요 원인입니다" 라고 쉽게 풀어준다.

<br>

**핵심 사용 흐름**

1. 탐색에서 종목 검색 → 즐겨찾기 등록
2. 공시 등록 시 푸시 알림 수신
3. AI 쉬운 설명 + 핵심 요약 3줄 확인
4. 관련 뉴스 및 주주 커뮤니티 확인

---

## 3. 기술 스택과 아키텍처

<br>

| 영역 | 선택 기술 | 선택 이유 |
|------|----------|----------|
| 프론트엔드 | Flutter (Dart) | iOS/Android 동시 개발, 차트 성능 우수 |
| 상태관리 | Riverpod | Flutter 표준, 비동기 상태 처리 용이 |
| 백엔드 | Python FastAPI | API 파싱 라이브러리 풍부, 빠른 개발 |
| 데이터베이스 | Supabase (PostgreSQL) | 무료, 인증 내장, Realtime 지원 |
| AI 요약 | Gemini API | 무료 플랜 일 1,500건, 카드 불필요 |
| 공시 데이터 | DART Open API | 금감원 공식, 무료 일 10,000건 |
| 뉴스 | 네이버 검색 API | 무료 일 25,000건, 국내 커버리지 우수 |
| 푸시 알림 | Firebase FCM | 무료 무제한 |

---

## 4. 아키텍처 다이어그램

```
┌─────────────────────────────────────────────────┐
│              Flutter 앱 (iOS / Android)          │
│   홈 · 탐색 · 뉴스 · 커뮤니티 · 마이페이지       │
└────────────────────┬────────────────────────────┘
                     │ HTTPS
┌────────────────────▼────────────────────────────┐
│              FastAPI 백엔드                      │
│  companies · disclosures · news · categories    │
└──┬──────────┬──────────┬──────────┬─────────────┘
   │          │          │          │
┌──▼──┐  ┌───▼──┐  ┌────▼──┐  ┌───▼──────┐
│DART │  │Naver │  │Gemini │  │Supabase  │
│API  │  │News  │  │  AI   │  │PostgreSQL│
└─────┘  └──────┘  └───────┘  └──────────┘
```

> 모든 외부 API 결과는 Supabase에 캐싱
> DART 공시 → Gemini AI 분석 → Flutter 표시

---

## 5. 진행 상황

<br>

- ✅ **완료**: Flutter 프로젝트 구조, Supabase DB 스키마 (10개 테이블 + RLS)
- ✅ **완료**: FastAPI 백엔드 구조, DART API 공시·재무 연동
- ✅ **완료**: HTML 전처리, 캐시 레이어, Rate Limiter
- 🚧 **진행**: Gemini AI 공시 요약 (쉬운 설명 + 3줄 요약)
- ⏳ **예정**: 네이버 뉴스 API, 카테고리 분류, Flutter UI 전체

<br>

전체 진척: **43%** (Must 기능 기준)

`세션 3/7 완료 · 세션 4 진행 중`

---

## 6. 데모

<br>

**준비된 시나리오**

1. **DART API 연동 확인**
   - `GET /companies` — 기업 목록 조회
   - `GET /disclosures/{corp_code}` — 삼성전자 공시 목록 호출

2. **AI 공시 요약 (진행 중)**
   - 공시 원문 → Gemini API → 쉬운 설명 + 3줄 요약 반환

3. **Supabase 캐싱 확인**
   - 첫 요청: DART API 호출
   - 재요청: Supabase 캐시 반환 (응답 속도 비교)

<br>

> FastAPI Swagger UI (`localhost:8000/docs`) 라이브 시연

---

## 7. 남은 일정

<br>

| 세션 | 기간 | 목표 |
|------|------|------|
| **S4** (현재) | 5/18 ~ 5/26 | Gemini AI + 네이버 뉴스 + 카테고리 분류 |
| **S5** | 5/27 ~ 6/2 | Flutter UI 전체 화면 구현 + 테스트/디버깅 |
| **S6** | 6/3 ~ 6/9 | FCM 알림 + 마이페이지 + 배포 (Render) |
| **S7** | 6/10 ~ 6/14 | **최종 발표** |

<br>

**리스크 관리**

- DART API 일 10,000건 한도 → 캐싱으로 대응
- Gemini 무료 플랜 분당 15건 → Rate Limiter 적용
- Supabase 무료 플랜 1주 미사용 시 일시정지 → 주기적 ping

---

## 8. 어려운 점 / 도움 요청

<br>

**기술적 어려움**

- **DART 공시 HTML 전처리** — 표, 이미지, 특수문자가 섞인 원문 파싱
  → BeautifulSoup으로 해결 중, 일부 공시 포맷 예외 처리 필요

- **Gemini 응답 파싱** — "쉬운 설명 / 핵심 요약" 두 파트를 일관되게 추출하는 프롬프트 설계
  → 구조화된 JSON 응답 유도 방식 검토 중

<br>

**도움 요청**

- Flutter `Riverpod` + `go_router` 조합에서 딥링크 처리 방법
- 실제 App Store / Google Play 배포 경험 있으신 분 조언

---

## 9. 질문 받습니다

<br>
<br>

# 감사합니다 🙏

<br>

**GitHub Pages 발표 자료**
`https://[유저명].github.io/dartletter-pages`

<br>

**WBS · 아키텍처 · 비전 슬라이드**
온라인에서 실시간 확인 가능

---

<!-- 발표 스크립트 주석 -->
<!--
[표지]
안녕하세요. 다트레터 팀입니다.
저희는 DART 공시를 AI가 쉽게 풀어주는 기업분석 앱을 개발 중입니다.

[1. 문제 정의]
국내 개인 투자자가 1400만 명인데, 실제로 공시를 읽고 이해하는 사람은 거의 없습니다.
공시 원문은 평균 32페이지에 법률·회계 용어로 가득 차 있고,
정보도 DART, 포털, 증권앱에 분산되어 있어 한눈에 보기 어렵습니다.

[2. 사용자 시나리오]
예를 들어 퇴근 후 삼성전자 공시 알림을 받은 직장인이 앱을 열면,
AI가 핵심을 쉬운 말로 바로 설명해줍니다.

[3. 기술 스택]
프론트는 Flutter로 iOS·Android 동시 개발, 백엔드는 FastAPI,
DB는 Supabase, AI는 Gemini API를 사용합니다.
모두 무료 또는 무료 플랜으로 운영 가능한 조합입니다.

[5. 진행 상황]
현재 3세션이 완료되어 43% 진행률입니다.
백엔드 구조, DB 스키마, DART API 연동까지 완료했고,
지금은 Gemini AI 요약 기능을 개발 중입니다.

[7. 남은 일정]
이번 세션에 AI 요약과 뉴스 연동을 마치고,
다음 세션에 Flutter UI 전체를 완성할 계획입니다.
6월 9일까지 배포까지 마무리하겠습니다.
-->
