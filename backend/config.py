import os
from dotenv import load_dotenv

load_dotenv()


def _require(key: str) -> str:
    value = os.getenv(key)
    if not value:
        raise ValueError(f"{key} 환경변수가 설정되지 않았습니다")
    return value


DART_API_KEY: str = _require("DART_API_KEY")
SUPABASE_URL: str = _require("SUPABASE_URL")
SUPABASE_SERVICE_ROLE_KEY: str = _require("SUPABASE_SERVICE_ROLE_KEY")
SUPABASE_ANON_KEY: str = _require("SUPABASE_ANON_KEY")
GEMINI_API_KEY: str = _require("GEMINI_API_KEY")

NAVER_CLIENT_ID: str = os.getenv("NAVER_CLIENT_ID", "")
NAVER_CLIENT_SECRET: str = os.getenv("NAVER_CLIENT_SECRET", "")
FCM_SERVER_KEY: str = os.getenv("FCM_SERVER_KEY", "")
