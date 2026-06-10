import asyncio
import logging

from fastapi import APIRouter, Query, Request
from fastapi.responses import JSONResponse

from db.supabase_client import get_supabase
from services import dart_service
from services.category_service import INDUSTRY_MAP, ETF_KEYWORDS
from utils import err, ok
from utils.rate_limiter import limiter

router = APIRouter(prefix="/companies", tags=["기업"])
logger = logging.getLogger(__name__)


@router.get("")
@limiter.limit("60/minute")
async def list_companies(
    request: Request,
    market: str | None = Query(None),
    search: str | None = Query(None),
    industry_category: str | None = Query(None),
    page: int = Query(1, ge=1),
    limit: int = Query(30, ge=1, le=100),
):
    data = await asyncio.to_thread(
        _query_companies, market, search, industry_category, page, limit
    )
    return ok(data)


def _query_companies(
    market: str | None,
    search: str | None,
    industry_category: str | None,
    page: int,
    limit: int,
) -> dict:
    db = get_supabase()
    offset = (page - 1) * limit

    q = db.table("companies").select(
        "corp_code, corp_name, stock_code, market, industry"
    )
    if market:
        q = q.eq("market", market)
    if search:
        q = q.ilike("corp_name", f"%{search}%")
    if industry_category:
        q = _apply_industry_filter(q, industry_category)

    items = q.order("corp_name").range(offset, offset + limit - 1).execute()

    count_q = db.table("companies").select("corp_code", count="exact")
    if market:
        count_q = count_q.eq("market", market)
    if search:
        count_q = count_q.ilike("corp_name", f"%{search}%")
    if industry_category:
        count_q = _apply_industry_filter(count_q, industry_category)
    count_res = count_q.execute()

    return {"items": items.data, "total": count_res.count or 0, "page": page, "limit": limit}


def _apply_industry_filter(q, industry_category: str):
    """업종 카테고리를 industry 코드 prefix 필터로 변환"""
    if industry_category == "ETF":
        return q.or_(",".join(f"corp_name.ilike.%{kw}%" for kw in ETF_KEYWORDS))
    if industry_category == "우선주":
        return q.or_("corp_name.ilike.%우,corp_name.ilike.%우B,corp_name.ilike.%우C")
    prefixes = INDUSTRY_MAP.get(industry_category, [])
    if prefixes:
        return q.or_(",".join(f"industry.ilike.{p}%" for p in prefixes))
    return q


@router.post("/sync")
async def sync_companies(request: Request):
    """DART 상장사 목록을 Supabase에 동기화 (최초 1회 실행)"""
    count = await dart_service.sync_listed_companies()
    return ok({"synced": count})


@router.post("/sync-market")
async def sync_market(request: Request):
    """DART 공시목록으로 코스피·코스닥 분류를 가져와 market 필드 일괄 업데이트 (수분 소요)"""
    count = await dart_service.sync_market_from_dart()
    return ok({"updated": count})


@router.post("/sync-industry")
async def sync_industry(request: Request):
    """DART company.json으로 업종코드 일괄 업데이트 (수분 소요)"""
    count = await dart_service.sync_industry_codes()
    return ok({"updated": count})


@router.get("/{corp_code}")
@limiter.limit("60/minute")
async def get_company(request: Request, corp_code: str):
    data = await dart_service.get_company(corp_code)
    if not data:
        return JSONResponse(status_code=404, content=err("기업을 찾을 수 없습니다"))
    return ok(data)
