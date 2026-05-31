# AI 공시 분석 프롬프트

## 출력 형식

```
[쉬운 설명]
투자 경험이 없는 일반인도 이해할 수 있는 말로 3~5문장 풀어쓰기.
전문 용어는 괄호 안에 뜻 부연. 예: PER(주가수익비율)

[핵심 요약]
- 핵심 내용: 한 줄
- 투자자 영향: 한 줄
- 주의할 점: 한 줄
```

## 시스템 프롬프트
```python
SYSTEM_PROMPT = """
당신은 한국 주식 투자를 처음 시작하는 일반인을 위한 공시 해설가입니다.
어려운 금융 용어 없이 누구나 이해할 수 있게 설명합니다.
추측이나 투자 권유는 절대 하지 않습니다.
공시에 명시된 사실만 전달합니다.
"""
```

## 유저 프롬프트
```python
USER_PROMPT = """
아래 DART 공시 원문을 두 파트로 분석해줘.

[쉬운 설명]
- 투자 경험이 없는 일반인도 이해할 수 있는 쉬운 말로 풀어서 설명
- 전문 용어 사용 시 괄호 안에 뜻 설명 (예: PER(주가수익비율))
- 3~5문장으로 작성

[핵심 요약]
- 핵심 내용: (가장 중요한 내용 한 줄)
- 투자자 영향: (주가나 실적에 미칠 영향 한 줄)
- 주의할 점: (리스크나 추가 확인 사항 한 줄)

공시 원문:
{content}
"""
```

## 처리 흐름
```
공시 원문 수신
    ↓
500자 미만? → 원문 그대로 반환
    ↓
Supabase 캐시 확인 → 있으면 캐시 반환
    ↓
HTML 태그 제거 전처리
    ↓
Gemini API 호출 (최대 3회 재시도)
    ↓
실패 → "요약을 생성할 수 없습니다" 반환 (에러 throw 금지)
    ↓
성공 → Supabase 저장 후 반환
```

## Gemini API 호출 예시
```python
import google.generativeai as genai

genai.configure(api_key=os.getenv("GEMINI_API_KEY"))
model = genai.GenerativeModel(
    model_name="gemini-2.0-flash",
    system_instruction=SYSTEM_PROMPT,
)

response = model.generate_content(
    USER_PROMPT.format(content=content),
    generation_config=genai.GenerationConfig(max_output_tokens=1000),
)
summary = response.text
```

## 비용 절감 규칙
- 500자 미만 공시는 요약 생략
- 이미 요약된 공시는 캐시 반환 (Gemini API 재호출 금지)
- max_output_tokens: 1000 고정
