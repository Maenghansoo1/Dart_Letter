from fastapi import APIRouter, Request
from fastapi.responses import JSONResponse

from services import dart_service
from utils import err, ok
from utils.rate_limiter import limiter

router = APIRouter(prefix="/financials", tags=["재무"])


@router.get("/{corp_code}")
@limiter.limit("30/minute")
async def get_financials(request: Request, corp_code: str):
    data = await dart_service.get_financials(corp_code)
    if not data:
        return JSONResponse(status_code=404, content=err("재무 데이터를 찾을 수 없습니다"))
    return ok(data)
