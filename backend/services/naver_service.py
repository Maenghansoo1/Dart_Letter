"""
네이버 뉴스 검색 API 서비스
https://developers.naver.com/docs/serviceapi/search/news/news.md
캐시: 1시간 (in-memory)
"""
import logging
import time
from datetime import datetime
from email.utils import parsedate_to_datetime

import httpx

import config

logger = logging.getLogger(__name__)

NAVER_URL = "https://openapi.naver.com/v1/search/news.json"
_cache: dict[str, dict] = {}
_TTL = 3600  # 1시간

CATEGORY_QUERIES: dict[str, str] = {
    "전체":   "경제 증시 주식",
    "코스피":  "코스피 KOSPI",
    "코스닥":  "코스닥 KOSDAQ",
    "환율":   "환율 달러 원달러",
    "금리":   "금리 기준금리 한국은행",
    "원자재":  "원자재 원유 금값",
    "부동산":  "부동산 아파트 주택시장",
    "공시":   "DART 공시 주요사항",
}


def _headers() -> dict:
    return {
        "X-Naver-Client-Id": config.NAVER_CLIENT_ID,
        "X-Naver-Client-Secret": config.NAVER_CLIENT_SECRET,
    }


def _cached(key: str) -> list[dict] | None:
    entry = _cache.get(key)
    if entry and time.time() - entry["ts"] < _TTL:
        return entry["data"]
    return None


def _store(key: str, data: list[dict]) -> None:
    _cache[key] = {"data": data, "ts": time.time()}


async def _search(query: str, display: int = 20) -> list[dict]:
    async with httpx.AsyncClient(timeout=10) as client:
        res = await client.get(
            NAVER_URL,
            headers=_headers(),
            params={"query": query, "display": display, "sort": "date"},
        )
        res.raise_for_status()
        return res.json().get("items", [])


def _format_date(pub_date: str) -> str:
    try:
        dt = parsedate_to_datetime(pub_date)
        diff = datetime.now(dt.tzinfo) - dt
        minutes = int(diff.total_seconds() // 60)
        if minutes < 60:
            return f"{minutes}분 전"
        if minutes < 1440:
            return f"{minutes // 60}시간 전"
        return f"{diff.days}일 전"
    except Exception:
        return pub_date


def _parse(item: dict, category: str = "뉴스") -> dict:
    raw_title = item.get("title", "")
    raw_desc = item.get("description", "")
    return {
        "title": _strip(raw_title),
        "link": item.get("link") or item.get("originallink", ""),
        "description": _strip(raw_desc),
        "pub_date": _format_date(item.get("pubDate", "")),
        "category": category,
    }


def _strip(text: str) -> str:
    import re
    return re.sub(r"<[^>]+>", "", text).replace("&amp;", "&").replace("&quot;", '"').replace("&lt;", "<").replace("&gt;", ">")


async def get_latest_news(category: str = "전체") -> list[dict]:
    """카테고리별 최신 뉴스 20건 (1시간 캐시)"""
    query = CATEGORY_QUERIES.get(category, CATEGORY_QUERIES["전체"])
    key = f"latest:{category}"
    if (cached := _cached(key)) is not None:
        return cached
    try:
        items = await _search(query, display=20)
        result = [_parse(i, category) for i in items]
        _store(key, result)
        return result
    except Exception as e:
        logger.error(f"네이버 뉴스 실패 ({category}): {e}")
        return _cache.get(key, {}).get("data", [])


async def get_company_news(corp_name: str) -> list[dict]:
    """기업별 뉴스 20건"""
    key = f"corp:{corp_name}"
    if (cached := _cached(key)) is not None:
        return cached
    try:
        items = await _search(f"{corp_name} 주가", display=20)
        result = [_parse(i) for i in items]
        _store(key, result)
        return result
    except Exception as e:
        logger.error(f"네이버 기업뉴스 실패 ({corp_name}): {e}")
        return _cache.get(key, {}).get("data", [])
