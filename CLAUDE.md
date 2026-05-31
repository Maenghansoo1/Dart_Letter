# 다트레터 (DartLetter)

DART 공시를 AI가 쉽게 풀어주는 기업분석 앱.

## 스택
- Frontend: Flutter + Riverpod + go_router
- Backend: Python FastAPI
- DB: Supabase (PostgreSQL)
- AI: Gemini API (gemini-2.0-flash)
- 공시: DART Open API / 뉴스: 네이버 검색 API / 주가: KRX / 알림: FCM

## 절대 금지
- API 키 코드 하드코딩 금지 → 반드시 .env 사용
- .env 커밋 금지
- 프론트에서 service_role_key 사용 금지
- SELECT * 남용 금지 → 필요한 컬럼만
- 화면에서 직접 API 호출 금지 → 반드시 Provider 경유

## 코드 원칙
- 함수 하나는 한 가지 일만, 50줄 초과 시 분리
- 모든 외부 API 호출은 try/except + 캐시 적용
- 로딩/에러/데이터 세 가지 상태 항상 처리
- 재사용 UI는 widgets/ 에 공통 컴포넌트로 분리

## UI 필수
- 모든 화면 하단: "본 서비스는 투자 참고용이며 투자 권유가 아닙니다"
- 주가 옆: "전일 종가 기준" 표시
- 상승: 빨강 #E24B4A / 하락: 파랑 #378ADD
- 로딩 시 SkeletonLoader / 에러 시 ErrorView + 재시도 버튼

## 상세 문서
- 보안: docs/SECURITY.md
- 컨벤션: docs/CONVENTION.md
- 재사용 컴포넌트: docs/COMPONENTS.md
- API 명세: docs/API.md
- AI 프롬프트: docs/AI_PROMPT.md
