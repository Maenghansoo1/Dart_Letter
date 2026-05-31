# 보안 규칙

## 환경변수
```python
# 올바른 방법
DART_API_KEY = os.getenv("DART_API_KEY")
if not DART_API_KEY:
    raise ValueError("DART_API_KEY 환경변수가 설정되지 않았습니다")

# 절대 금지
DART_API_KEY = "abc1234567890"
```

## Supabase RLS
```sql
ALTER TABLE watchlist ENABLE ROW LEVEL SECURITY;
CREATE POLICY "본인 데이터만 접근" ON watchlist
  FOR ALL USING (auth.uid() = user_id);

-- 공개 데이터는 SELECT만 허용
CREATE POLICY "공시 읽기 전용" ON disclosures
  FOR SELECT USING (true);
```

## 인증 미들웨어
```python
from fastapi import Depends, HTTPException

async def verify_token(authorization: str = Header(...)):
    token = authorization.replace("Bearer ", "")
    user = supabase.auth.get_user(token)
    if not user:
        raise HTTPException(status_code=401, detail="로그인이 필요합니다")
    return user

# 커뮤니티 엔드포인트는 인증 필수
@router.post("/community/posts")
async def create_post(post: PostCreate, user=Depends(verify_token)):
    ...
```

## 입력값 검증
```python
class PostCreate(BaseModel):
    corp_code: str = Field(..., min_length=6, max_length=6, pattern=r"^\d{6}$")
    content: str = Field(..., min_length=1, max_length=1000)
```

## Rate Limiting
- DART API: 초당 최대 5건
- 네이버 API: 초당 최대 10건
- Gemini API: 동시 요청 최대 3건

```python
from slowapi import Limiter
limiter = Limiter(key_func=get_remote_address)

@router.post("/disclosures/{rcept_no}/summarize")
@limiter.limit("10/minute")
async def summarize(request: Request, rcept_no: str):
    ...
```
