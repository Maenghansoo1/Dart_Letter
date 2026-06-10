"""
기업 카테고리 서비스
company_categories 테이블 없이 companies 테이블에서 직접 필터링
"""
import asyncio
import logging
import re
from datetime import date, timedelta

from db.supabase_client import get_supabase

logger = logging.getLogger(__name__)

# ── 카테고리 정의 ──────────────────────────────────────────────────────────────

STATIC_CATEGORIES = [
    "전체",
    "KOSPI",
    "KOSDAQ",
    "코넥스",
    "ETF",
    "우선주",
    "신규상장",
]

ETF_KEYWORDS = ["KODEX", "TIGER", "ARIRANG", "KINDEX", "KOSEF",
                "HANARO", "ACE", "SOL", "PLUS", "RISE", "SMART", "ETF"]

INDUSTRY_CATEGORIES = [
    "반도체", "바이오", "2차전지", "자동차", "은행",
    "보험", "증권", "건설", "화학", "철강",
    "유통", "게임/엔터", "통신", "부동산", "식품",
    "에너지", "항공/운송", "IT서비스",
]

INDUSTRY_MAP: dict[str, list[str]] = {
    "반도체":    ["261", "262"],
    "바이오":    ["210", "211", "212", "213"],
    "2차전지":  ["2722", "272"],
    "자동차":    ["301", "302", "303", "304"],
    "은행":      ["641"],
    "보험":      ["651", "652"],
    "증권":      ["642", "643"],
    "건설":      ["410", "411", "412"],
    "화학":      ["201", "202", "203", "204"],
    "철강":      ["241", "242", "243"],
    "유통":      ["461", "471", "472", "478"],
    "게임/엔터": ["582", "592", "901", "902"],
    "통신":      ["611", "612", "613"],
    "부동산":    ["681", "682", "683"],
    "식품":      ["101", "102", "103", "104", "107"],
    "에너지":    ["051", "052", "191", "192"],
    "항공/운송": ["511", "512", "492", "493"],
    "IT서비스":  ["620", "621", "622"],
}

ALL_CATEGORIES = STATIC_CATEGORIES + INDUSTRY_CATEGORIES


# ── DB 쿼리 ────────────────────────────────────────────────────────────────────

def _base_query():
    return get_supabase().table("companies").select(
        "corp_code, corp_name, stock_code, market, industry, listed_date"
    )


def _paginate(q, page: int, limit: int):
    offset = (page - 1) * limit
    return q.range(offset, offset + limit - 1)


def _count(q) -> int:
    res = q.execute()
    return len(res.data or [])


def _query_all(page: int, limit: int) -> dict:
    db = get_supabase()
    offset = (page - 1) * limit
    items = db.table("companies").select(
        "corp_code, corp_name, stock_code, market, industry"
    ).range(offset, offset + limit - 1).execute()
    total = db.table("companies").select("corp_code", count="exact").execute()
    return {"items": items.data or [], "total": total.count or 0, "page": page, "limit": limit}


def _query_market(market_val: str, page: int, limit: int) -> dict:
    db = get_supabase()
    offset = (page - 1) * limit
    q = db.table("companies").select(
        "corp_code, corp_name, stock_code, market, industry"
    ).eq("market", market_val)
    items = q.range(offset, offset + limit - 1).execute()
    count = db.table("companies").select("corp_code", count="exact").eq("market", market_val).execute()
    return {"items": items.data or [], "total": count.count or 0, "page": page, "limit": limit}


def _query_etf(page: int, limit: int) -> dict:
    db = get_supabase()
    offset = (page - 1) * limit
    # 이름에 ETF 키워드 포함
    filter_str = ",".join(f"corp_name.ilike.%{kw}%" for kw in ETF_KEYWORDS)
    items = db.table("companies").select(
        "corp_code, corp_name, stock_code, market, industry"
    ).or_(filter_str).range(offset, offset + limit - 1).execute()
    all_etf = db.table("companies").select("corp_code", count="exact").or_(filter_str).execute()
    return {"items": items.data or [], "total": all_etf.count or 0, "page": page, "limit": limit}


def _query_preferred(page: int, limit: int) -> dict:
    db = get_supabase()
    offset = (page - 1) * limit
    # 종목명이 '우'로 끝나는 경우 (우선주)
    items = db.table("companies").select(
        "corp_code, corp_name, stock_code, market, industry"
    ).or_("corp_name.ilike.%우,corp_name.ilike.%우B,corp_name.ilike.%우C").range(offset, offset + limit - 1).execute()
    count = db.table("companies").select("corp_code", count="exact").or_(
        "corp_name.ilike.%우,corp_name.ilike.%우B,corp_name.ilike.%우C"
    ).execute()
    return {"items": items.data or [], "total": count.count or 0, "page": page, "limit": limit}


def _query_new_listing(page: int, limit: int) -> dict:
    db = get_supabase()
    offset = (page - 1) * limit
    one_year_ago = (date.today() - timedelta(days=365)).isoformat()
    items = db.table("companies").select(
        "corp_code, corp_name, stock_code, market, industry, listed_date"
    ).gte("listed_date", one_year_ago).range(offset, offset + limit - 1).execute()
    count = db.table("companies").select("corp_code", count="exact").gte("listed_date", one_year_ago).execute()
    return {"items": items.data or [], "total": count.count or 0, "page": page, "limit": limit}


def _query_industry(category: str, page: int, limit: int) -> dict:
    prefixes = INDUSTRY_MAP.get(category, [])
    if not prefixes:
        return {"items": [], "total": 0, "page": page, "limit": limit}
    db = get_supabase()
    offset = (page - 1) * limit
    filter_str = ",".join(f"industry.ilike.{p}%" for p in prefixes)
    items = db.table("companies").select(
        "corp_code, corp_name, stock_code, market, industry"
    ).or_(filter_str).range(offset, offset + limit - 1).execute()
    count = db.table("companies").select("corp_code", count="exact").or_(filter_str).execute()
    return {"items": items.data or [], "total": count.count or 0, "page": page, "limit": limit}


# ── 카테고리별 종목 수 ─────────────────────────────────────────────────────────

def _count_per_category() -> list[dict]:
    db = get_supabase()
    result = []
    # 시장별
    for market, label in [("KOSPI", "KOSPI"), ("KOSDAQ", "KOSDAQ"), ("KONEX", "코넥스")]:
        c = db.table("companies").select("corp_code", count="exact").eq("market", market).execute()
        result.append({"category": label, "count": c.count or 0})
    # ETF
    filter_str = ",".join(f"corp_name.ilike.%{kw}%" for kw in ETF_KEYWORDS)
    c = db.table("companies").select("corp_code", count="exact").or_(filter_str).execute()
    result.append({"category": "ETF", "count": c.count or 0})
    # 우선주
    c = db.table("companies").select("corp_code", count="exact").or_(
        "corp_name.ilike.%우,corp_name.ilike.%우B,corp_name.ilike.%우C"
    ).execute()
    result.append({"category": "우선주", "count": c.count or 0})
    # 신규상장
    one_year_ago = (date.today() - timedelta(days=365)).isoformat()
    c = db.table("companies").select("corp_code", count="exact").gte("listed_date", one_year_ago).execute()
    result.append({"category": "신규상장", "count": c.count or 0})
    # 업종
    for sector, prefixes in INDUSTRY_MAP.items():
        filter_str = ",".join(f"industry.ilike.{p}%" for p in prefixes)
        c = db.table("companies").select("corp_code", count="exact").or_(filter_str).execute()
        if (c.count or 0) > 0:
            result.append({"category": sector, "count": c.count})
    return result


# ── 공개 인터페이스 ────────────────────────────────────────────────────────────

async def get_categories() -> list[dict]:
    try:
        return await asyncio.to_thread(_count_per_category)
    except Exception as e:
        logger.error(f"카테고리 목록 실패: {e}")
        # 폴백: 정적 카테고리만 반환
        return [{"category": c, "count": 0} for c in STATIC_CATEGORIES[1:] + INDUSTRY_CATEGORIES]


async def get_category_stocks(category: str, sort: str, page: int, limit: int) -> dict:
    return await asyncio.to_thread(_dispatch, category, page, limit)


def _dispatch(category: str, page: int, limit: int) -> dict:
    if category == "전체":
        return _query_all(page, limit)
    if category == "KOSPI":
        return _query_market("KOSPI", page, limit)
    if category == "KOSDAQ":
        return _query_market("KOSDAQ", page, limit)
    if category == "코넥스":
        return _query_market("KONEX", page, limit)
    if category == "ETF":
        return _query_etf(page, limit)
    if category == "우선주":
        return _query_preferred(page, limit)
    if category == "신규상장":
        return _query_new_listing(page, limit)
    if category in INDUSTRY_MAP:
        return _query_industry(category, page, limit)
    return {"items": [], "total": 0, "page": page, "limit": limit}


# refresh_all은 company_categories 테이블이 생기면 사용
async def refresh_all() -> int:
    logger.info("company_categories 테이블 없이 동작 중 — 정적 필터링 사용")
    return 0
