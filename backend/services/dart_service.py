import asyncio
import io
import logging
import xml.etree.ElementTree as ET
import zipfile
from datetime import date

import httpx

import config
from db.supabase_client import get_supabase
from utils.cache import cache_get, cache_set
from utils.html_parser import clean_html

logger = logging.getLogger(__name__)

DART_BASE = "https://opendart.fss.or.kr/api"
_semaphore = asyncio.Semaphore(5)  # DART API: 동시 5건 제한


# ── 내부 HTTP 헬퍼 ────────────────────────────────────────────────────────────

async def _dart_json(path: str, params: dict) -> dict:
    """DART JSON API 호출"""
    async with _semaphore:
        async with httpx.AsyncClient(timeout=30) as client:
            try:
                res = await client.get(
                    f"{DART_BASE}/{path}",
                    params={**params, "crtfc_key": config.DART_API_KEY},
                )
                res.raise_for_status()
                return res.json()
            except httpx.TimeoutException:
                logger.error(f"DART 타임아웃: {path}")
                raise
            except httpx.HTTPStatusError as e:
                logger.error(f"DART HTTP {e.response.status_code}: {path}")
                raise


async def _dart_bytes(path: str, params: dict) -> bytes | None:
    """DART 바이너리(ZIP) 다운로드"""
    async with _semaphore:
        async with httpx.AsyncClient(timeout=60) as client:
            try:
                res = await client.get(
                    f"{DART_BASE}/{path}",
                    params={**params, "crtfc_key": config.DART_API_KEY},
                )
                res.raise_for_status()
                return res.content
            except Exception as e:
                logger.error(f"DART 바이너리 실패 {path}: {e}")
                return None


# ── 기업 목록 동기화 ───────────────────────────────────────────────────────────

async def sync_listed_companies() -> int:
    """DART corpCode.xml 다운로드 → 상장사만 Supabase에 upsert"""
    raw = await _dart_bytes("corpCode.xml", {})
    if not raw:
        raise RuntimeError("DART corpCode.xml 다운로드 실패")

    with zipfile.ZipFile(io.BytesIO(raw)) as zf:
        xml_content = zf.read(zf.namelist()[0])

    root = ET.fromstring(xml_content)
    companies = []
    for item in root.findall(".//list"):
        stock_code = (item.findtext("stock_code") or "").strip()
        if not stock_code:
            continue  # 비상장사 제외
        companies.append({
            "corp_code": item.findtext("corp_code", "").strip(),
            "corp_name": item.findtext("corp_name", "").strip(),
            "stock_code": stock_code,
        })

    db = get_supabase()
    batch_size = 500
    for i in range(0, len(companies), batch_size):
        await asyncio.to_thread(
            lambda batch=companies[i:i + batch_size]: db.table("companies").upsert(batch).execute()
        )

    logger.info(f"기업 동기화 완료: {len(companies)}개")
    return len(companies)


async def sync_market_from_dart() -> int:
    """DART 공시목록 API로 코스피·코스닥 corp_code를 수집해 market 필드 일괄 업데이트"""
    from datetime import date, timedelta

    end_de = date.today().strftime("%Y%m%d")
    bgn_de = (date.today() - timedelta(days=90)).strftime("%Y%m%d")  # 최근 3개월

    # 코스피·코스닥 병렬 수집
    kospi_task = _collect_corp_codes_by_cls("Y", bgn_de, end_de)
    kosdaq_task = _collect_corp_codes_by_cls("K", bgn_de, end_de)
    kospi_codes, kosdaq_codes = await asyncio.gather(kospi_task, kosdaq_task)

    if not kospi_codes and not kosdaq_codes:
        return 0

    db = get_supabase()
    updated = 0
    for market, codes in [("KOSPI", list(kospi_codes)), ("KOSDAQ", list(kosdaq_codes))]:
        for i in range(0, len(codes), 200):
            batch = codes[i : i + 200]
            res = await asyncio.to_thread(
                lambda m=market, b=batch: db.table("companies")
                .update({"market": m})
                .in_("corp_code", b)
                .execute()
            )
            updated += len(res.data or [])

    logger.info(f"market 동기화 완료: {updated}개 (KOSPI {len(kospi_codes)}, KOSDAQ {len(kosdaq_codes)})")
    return updated


async def _collect_corp_codes_by_cls(corp_cls: str, bgn_de: str, end_de: str) -> set[str]:
    """DART 공시목록 전체 페이지를 순회하며 unique corp_code 수집"""
    codes: set[str] = set()
    page = 1
    while True:
        try:
            data = await _dart_json(
                "list.json",
                {"bgn_de": bgn_de, "end_de": end_de, "corp_cls": corp_cls,
                 "page_no": page, "page_count": 100},
            )
            if data.get("status") not in ("000", "013"):
                break
            items = data.get("list", [])
            for item in items:
                if code := item.get("corp_code"):
                    codes.add(code)
            total = int(data.get("total_count", 0))
            if page * 100 >= total or not items:
                break
            page += 1
        except Exception as e:
            logger.error(f"DART corp_cls={corp_cls} 수집 실패 (page={page}): {e}")
            break
    logger.info(f"corp_cls={corp_cls} 수집 완료: {len(codes)}개 고유 기업")
    return codes


# ── 업종 코드 동기화 ──────────────────────────────────────────────────────────

async def sync_industry_codes() -> int:
    """industry가 null인 기업들의 업종코드를 DART에서 병렬 조회하여 업데이트"""
    db = get_supabase()

    # Supabase 기본 limit=1000 → 전체 페이지 순회
    corp_codes: list[str] = []
    offset = 0
    page_size = 1000
    while True:
        result = await asyncio.to_thread(
            lambda o=offset: db.table("companies")
            .select("corp_code")
            .is_("industry", "null")
            .in_("market", ["KOSPI", "KOSDAQ"])
            .range(o, o + page_size - 1)
            .execute()
        )
        batch = [r["corp_code"] for r in (result.data or [])]
        corp_codes.extend(batch)
        if len(batch) < page_size:
            break
        offset += page_size

    if not corp_codes:
        return 0

    logger.info(f"업종코드 미등록 기업 {len(corp_codes)}개 동기화 시작")

    updates: list[dict] = []
    lock = asyncio.Lock()

    async def fetch_one(corp_code: str):
        try:
            data = await _dart_json("company.json", {"corp_code": corp_code})
            if data.get("status") != "000":
                return
            code = (data.get("induty_code") or "").strip()
            if code:
                async with lock:
                    updates.append({"corp_code": corp_code, "industry": code})
        except Exception:
            pass

    # semaphore로 병렬 제한 (전역 _semaphore 재사용)
    tasks = [fetch_one(c) for c in corp_codes]
    await asyncio.gather(*tasks)

    # 업종코드별로 그룹핑 후 배치 update (upsert 금지: corp_name NOT NULL 제약)
    industry_map: dict[str, list[str]] = {}
    for row in updates:
        industry_map.setdefault(row["industry"], []).append(row["corp_code"])

    updated_count = 0
    for industry_code, codes in industry_map.items():
        for i in range(0, len(codes), 200):
            batch = codes[i : i + 200]
            res = await asyncio.to_thread(
                lambda ic=industry_code, b=batch: db.table("companies")
                .update({"industry": ic})
                .in_("corp_code", b)
                .execute()
            )
            updated_count += len(res.data or [])

    logger.info(f"업종코드 동기화 완료: {updated_count}개 업데이트")
    return updated_count


# ── 기업 ─────────────────────────────────────────────────────────────────────

async def get_company(corp_code: str) -> dict | None:
    """기업 정보 조회 (24시간 캐시)"""
    cached = await cache_get("companies", "corp_code", corp_code, ttl_hours=24)
    if cached:
        return cached
    try:
        data = await _dart_json("company.json", {"corp_code": corp_code})
        if data.get("status") != "000":
            return None
        company = _map_company(data)
        await cache_set("companies", company)
        return company
    except Exception as e:
        logger.error(f"기업 조회 실패 {corp_code}: {e}")
        return None


def _map_company(data: dict) -> dict:
    _cls = {"Y": "KOSPI", "K": "KOSDAQ", "N": "KONEX", "E": "기타"}
    return {
        "corp_code": data.get("corp_code"),
        "corp_name": data.get("corp_name"),
        "stock_code": data.get("stock_code"),
        "ceo": data.get("ceo_nm"),
        "industry": data.get("induty_code"),
        "established_date": data.get("est_dt") or None,
        "listed_date": data.get("listing_dt") or None,
        "market": _cls.get(data.get("corp_cls", ""), None),
        "address": data.get("adres"),
        "phone": data.get("phn_no"),
        "website": data.get("hm_url"),
    }


# ── 공시 목록 ─────────────────────────────────────────────────────────────────

async def get_disclosures(corp_code: str | None, page: int, limit: int) -> dict:
    """공시 목록 조회 (corp_code=None 이면 전체 최신 공시)"""
    params: dict = {"page_no": page, "page_count": limit, "sort": "date", "sort_mth": "desc"}
    if corp_code:
        params["corp_code"] = corp_code
    else:
        today = date.today()
        params["bgn_de"] = (today.replace(day=1)).strftime("%Y%m%d")
        params["end_de"] = today.strftime("%Y%m%d")
        params["corp_cls"] = "Y"      # 코스피만
        params["pblntf_ty"] = "A"     # 정기공시만 (사업보고서, 분기보고서 등)
    try:
        data = await _dart_json("list.json", params)
        # status 013 = 데이터 없음 (정상)
        if data.get("status") not in ("000", "013"):
            logger.warning(f"DART 공시 목록 오류: {data.get('message')}")
            return _empty_page(page, limit)

        items = [_map_disclosure(d) for d in data.get("list", [])]
        return {"items": items, "total": int(data.get("total_count", 0)), "page": page, "limit": limit}
    except Exception as e:
        logger.error(f"공시 목록 실패 {corp_code}: {e}")
        return _empty_page(page, limit)


def _map_disclosure(d: dict) -> dict:
    return {
        "rcept_no": d.get("rcept_no"),
        "corp_code": d.get("corp_code"),
        "corp_name": d.get("corp_name"),
        "report_nm": d.get("report_nm"),
        "rcept_dt": d.get("rcept_dt"),
        "submitter": d.get("flr_nm"),
    }


def _empty_page(page: int, limit: int) -> dict:
    return {"items": [], "total": 0, "page": page, "limit": limit}


async def get_watchlist_disclosures(corp_codes: list[str], limit_per_corp: int = 5) -> dict:
    """관심종목 각각의 최신 공시를 병렬로 조회 후 날짜순 정렬"""
    tasks = [get_disclosures(code, page=1, limit=limit_per_corp) for code in corp_codes]
    results = await asyncio.gather(*tasks, return_exceptions=True)

    items: list[dict] = []
    for result in results:
        if isinstance(result, dict):
            items.extend(result.get("items", []))

    items.sort(key=lambda x: x.get("rcept_dt", ""), reverse=True)
    return {"items": items, "total": len(items)}


# ── 공시 원문 ─────────────────────────────────────────────────────────────────

async def get_disclosure_detail(rcept_no: str) -> str | None:
    """공시 원문 조회 (영구 캐시)"""
    cached = await cache_get("disclosure_details", "rcept_no", rcept_no)
    if cached:
        return cached.get("content")
    try:
        raw = await _dart_bytes("document.json", {"rcept_no": rcept_no})
        if not raw:
            return None
        content = _extract_from_zip(raw)
        if content:
            await cache_set("disclosure_details", {"rcept_no": rcept_no, "content": content})
        return content
    except Exception as e:
        logger.error(f"공시 원문 실패 {rcept_no}: {e}")
        return None


def _extract_from_zip(raw: bytes) -> str | None:
    """ZIP에서 첫 번째 HTML 추출 후 정제"""
    try:
        with zipfile.ZipFile(io.BytesIO(raw)) as zf:
            html_files = [f for f in zf.namelist() if f.lower().endswith(".html")]
            if not html_files:
                return None
            html = zf.read(html_files[0]).decode("utf-8", errors="ignore")
        return clean_html(html)
    except zipfile.BadZipFile:
        logger.warning("ZIP 형식이 아닌 응답")
        return None


# ── 재무제표 ──────────────────────────────────────────────────────────────────

async def get_financials(corp_code: str) -> dict | None:
    """재무제표 조회 (24시간 캐시, 직전 사업연도)"""
    cached = await cache_get("financial_statements", "corp_code", corp_code, ttl_hours=24)
    if cached:
        return cached
    year = str(date.today().year - 1)
    try:
        data = await _dart_json("fnlttSinglAcnt.json", {
            "corp_code": corp_code,
            "bsns_year": year,
            "reprt_code": "11011",  # 사업보고서
        })
        if data.get("status") != "000":
            return None
        result = _parse_financials(data.get("list", []), corp_code, year)
        await cache_set("financial_statements", result)
        return result
    except Exception as e:
        logger.error(f"재무제표 실패 {corp_code}: {e}")
        return None


def _parse_financials(items: list, corp_code: str, year: str) -> dict:
    is_map = {i["account_nm"]: i.get("thstrm_amount") for i in items if i.get("sj_div") in ("IS", "CIS")}
    bs_map = {i["account_nm"]: i.get("thstrm_amount") for i in items if i.get("sj_div") == "BS"}

    revenue = _to_int(is_map.get("매출액") or is_map.get("수익(매출액)") or is_map.get("영업수익"))
    op_income = _to_int(is_map.get("영업이익") or is_map.get("영업이익(손실)"))
    liab = _to_int(bs_map.get("부채총계"))
    equity = _to_int(bs_map.get("자본총계"))
    debt_ratio = round(liab / equity * 100, 2) if equity else None

    return {
        "corp_code": corp_code,
        "year": int(year),
        "revenue": revenue,
        "operating_income": op_income,
        "debt_ratio": debt_ratio,
        "per": None,   # KRX 데이터 필요 (추후 연동)
        "pbr": None,   # KRX 데이터 필요 (추후 연동)
    }


def _to_int(value: str | None) -> int | None:
    if not value:
        return None
    try:
        return int(str(value).replace(",", "").strip())
    except ValueError:
        return None
