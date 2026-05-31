"""
기업 카테고리 자동 분류 서비스
한 종목이 여러 카테고리에 중복 분류 가능 (company_categories 테이블)
캐시: 24시간 (POST /categories/refresh 로 강제 갱신)
"""
import asyncio
import logging
import re
from datetime import date

from db.supabase_client import get_supabase

logger = logging.getLogger(__name__)

# ── 상수 ──────────────────────────────────────────────────────────────────────

ETF_KEYWORDS = [
    "KODEX", "TIGER", "ARIRANG", "KINDEX", "KOSEF",
    "HANARO", "ACE", "SOL", "PLUS", "RISE", "SMART",
]

# KISIC 코드 앞자리 → 업종명
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

MARKET_LABEL = {"KOSPI": "KOSPI", "KOSDAQ": "KOSDAQ", "KONEX": "코넥스"}


# ── 분류 로직 ──────────────────────────────────────────────────────────────────

def _is_etf(name: str) -> bool:
    upper = name.upper()
    return "ETF" in upper or any(kw in upper for kw in ETF_KEYWORDS)


def _is_preferred(name: str) -> bool:
    return bool(re.search(r"[가-힣]우[A-Z]?$", name))


def _sector_from_industry(industry: str) -> str | None:
    for sector, prefixes in INDUSTRY_MAP.items():
        if any(industry.startswith(p) for p in prefixes):
            return sector
    return None


def _financials_categories(fin: dict, corp_name: str) -> list[str]:
    result: list[str] = []
    cap = fin.get("market_cap")
    div = fin.get("dividend_yield")
    per = fin.get("per")
    pbr = fin.get("pbr")
    rev = fin.get("revenue")
    prev = fin.get("prev_revenue")

    if cap is not None:
        if cap >= 10_000_000_000_000:
            result.append("대형주")
        elif cap < 100_000_000_000:
            result.append("소형주")

    if div is not None:
        if div >= 5.0:
            result.extend(["고배당", "배당주"])
        elif div >= 2.0:
            result.append("배당주")

    if "월배당" in corp_name or "월지급" in corp_name:
        result.append("월배당주")

    if per is not None and pbr is not None and per > 0 and pbr > 0:
        if per <= 10 and pbr <= 1:
            result.append("가치주")

    if rev and prev and prev > 0:
        if (rev - prev) / prev >= 0.20:
            result.append("성장주")

    return result


def classify_company(company: dict, financials: dict | None) -> list[str]:
    """단일 기업 → 카테고리 목록 (복수 허용)"""
    cats: list[str] = []
    name = company.get("corp_name", "")
    market = company.get("market") or ""
    industry = company.get("industry") or ""

    if _is_etf(name):
        cats.append("ETF")

    if _is_preferred(name):
        cats.append("우선주")

    label = MARKET_LABEL.get(market)
    if label:
        cats.append(label)

    listed_str = company.get("listed_date")
    if listed_str:
        try:
            listed = date.fromisoformat(str(listed_str)[:10])
            if (date.today() - listed).days <= 365:
                cats.append("신규상장")
        except (ValueError, TypeError):
            pass

    sector = _sector_from_industry(industry)
    if sector:
        cats.append(sector)

    if financials:
        cats.extend(_financials_categories(financials, name))

    return list(set(cats))


# ── DB 헬퍼 ───────────────────────────────────────────────────────────────────

def _fetch_all_companies() -> list[dict]:
    return (
        get_supabase()
        .table("companies")
        .select("corp_code, corp_name, market, industry, listed_date")
        .execute()
        .data or []
    )


def _fetch_all_financials() -> dict[str, dict]:
    rows = get_supabase().table("financial_statements").select("*").execute().data or []
    return {r["corp_code"]: r for r in rows}


def _bulk_replace(rows: list[dict]) -> None:
    db = get_supabase()
    db.table("company_categories").delete().neq("corp_code", "").execute()
    for i in range(0, len(rows), 500):
        db.table("company_categories").insert(rows[i : i + 500]).execute()


def _count_by_category() -> list[dict]:
    rows = (
        get_supabase()
        .table("company_categories")
        .select("category_name")
        .execute()
        .data or []
    )
    counts: dict[str, int] = {}
    for r in rows:
        cat = r["category_name"]
        counts[cat] = counts.get(cat, 0) + 1
    return sorted(
        [{"category": k, "count": v} for k, v in counts.items()],
        key=lambda x: -x["count"],
    )


def _query_stocks(category: str, sort: str, page: int, limit: int) -> dict:
    db = get_supabase()
    offset = (page - 1) * limit

    codes_res = (
        db.table("company_categories")
        .select("corp_code")
        .eq("category_name", category)
        .execute()
    )
    codes = [r["corp_code"] for r in (codes_res.data or [])]
    total = len(codes)
    if not codes:
        return {"items": [], "total": 0, "page": page, "limit": limit}

    page_codes = codes[offset : offset + limit]
    items_res = (
        db.table("companies")
        .select("corp_code, corp_name, stock_code, market, industry")
        .in_("corp_code", page_codes)
        .execute()
    )
    return {"items": items_res.data or [], "total": total, "page": page, "limit": limit}


# ── 공개 인터페이스 ────────────────────────────────────────────────────────────

async def get_categories() -> list[dict]:
    return await asyncio.to_thread(_count_by_category)


async def get_category_stocks(
    category: str, sort: str, page: int, limit: int
) -> dict:
    return await asyncio.to_thread(_query_stocks, category, sort, page, limit)


async def refresh_all() -> int:
    """전체 종목 재분류 후 Supabase 저장"""
    companies = await asyncio.to_thread(_fetch_all_companies)
    financials = await asyncio.to_thread(_fetch_all_financials)

    rows: list[dict] = []
    for company in companies:
        code = company["corp_code"]
        for cat in classify_company(company, financials.get(code)):
            rows.append({"corp_code": code, "category_name": cat})

    await asyncio.to_thread(_bulk_replace, rows)
    logger.info(f"카테고리 재분류 완료: {len(companies)}개 기업, {len(rows)}개 분류")
    return len(companies)
