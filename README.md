# 다트레터 (DartLetter)

DART 공시를 AI가 쉽게 풀어주는 기업분석 앱

---

## 시작하기

### 1. 환경변수 설정

```bash
cp .env.example .env
# .env 파일 열어서 API 키 전부 입력
```

필요한 API 키:
| API | 발급 주소 | 비용 |
|-----|----------|------|
| DART Open API | https://opendart.fss.or.kr | 무료 |
| 네이버 검색 API | https://developers.naver.com | 무료 |
| Gemini API | https://aistudio.google.com | 유료 |
| Supabase | https://supabase.com | 무료 |
| KRX | https://data.krx.co.kr | 무료 |
| Firebase | https://console.firebase.google.com | 무료 |

---

### 2. 백엔드 실행

```bash
cd backend
python -m venv venv
source venv/bin/activate   # Windows: venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

API 문서: http://localhost:8000/docs

---

### 3. 프론트엔드 실행

```bash
cd frontend
flutter pub get
flutter run
```

---

### 4. Docker로 백엔드 실행

```bash
cd backend
docker build -t dartletter-api .
docker run -p 8000:8000 --env-file ../.env dartletter-api
```

---

## 개발 순서

Claude Code로 개발할 때 아래 순서대로 진행:

1. 프로젝트 구조 세팅
2. Supabase DB 스키마
3. DART API 연동
4. Gemini API 공시 요약
5. 네이버 뉴스 API 연동
6. 카테고리 분류 로직
7. Flutter 탐색 화면
8. Flutter 홈 화면
9. Flutter 기업 상세 화면
10. Flutter 커뮤니티 기능
11. FCM 푸시 알림
12. 마이페이지
13. 배포 준비

자세한 각 단계별 프롬프트는 `PROMPTS.md` 참고.

---

## 주의사항

- `.env` 파일은 절대 커밋하지 않는다
- `firebase-credentials.json` 절대 커밋하지 않는다
- 주가 데이터는 전일 종가 기준 (실시간 아님)
- 모든 화면에 투자 면책 문구 표시 필수
