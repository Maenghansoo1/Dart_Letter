import asyncio
import logging

from fastapi import APIRouter, Query, Request
from fastapi.responses import JSONResponse

from db.supabase_client import get_supabase
from services import dart_service
from utils import err, ok
from utils.rate_limiter import limiter

router = APIRouter(prefix="/companies", tags=["기업"])
logger = logging.getLogger(__name__)


@router.get("")
@limiter.limit("60/minute")
async def list_companies(
    request: Request,
    category: str | None = Query(None),
    market: str | None = Query(None),
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
):
    data = await asyncio.to_thread(_query_companies, category, market, page, limit)
    return ok(data)


def _query_companies(category: str | None, market: str | None, page: int, limit: int) -> dict:
    db = get_supabase()
    offset = (page - 1) * limit

    q = db.table("companies").select(
        "corp_code, corp_name, stock_code, market, industry, category"
    )
    if category:
        q = q.eq("category", category)
    if market:
        q = q.eq("market", market)
    items = q.range(offset, offset + limit - 1).execute()

    count_q = db.table("companies").select("corp_code", count="exact")
    if category:
        count_q = count_q.eq("category", category)
    if market:
        count_q = count_q.eq("market", market)
    count_res = count_q.execute()

    return {"items": items.data, "total": count_res.count or 0, "page": page, "limit": limit}


@router.post("/sync")
async def sync_companies(request: Request):
    """DART 상장사 목록을 Supabase에 동기화 (최초 1회 실행)"""
    count = await dart_service.sync_listed_companies()
    return ok({"synced": count})


@router.get("/{corp_code}")
@limiter.limit("60/minute")
async def get_company(request: Request, corp_code: str):
    data = await dart_service.get_company(corp_code)
    if not data:
        return JSONResponse(status_code=404, content=err("기업을 찾을 수 없습니다"))
    return ok(data)
