from fastapi import APIRouter, Query, Request
from fastapi.responses import JSONResponse

from services import dart_service
from utils import err, ok
from utils.rate_limiter import limiter

router = APIRouter(prefix="/disclosures", tags=["공시"])


@router.get("/latest")
@limiter.limit("30/minute")
async def list_latest_disclosures(
    request: Request,
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
):
    data = await dart_service.get_disclosures(None, page, limit)
    return ok(data)


@router.get("/watchlist")
@limiter.limit("30/minute")
async def watchlist_disclosures(
    request: Request,
    corp_codes: str = Query(...),
    limit: int = Query(5, ge=1, le=20),
):
    codes = [c.strip() for c in corp_codes.split(",") if c.strip()]
    data = await dart_service.get_watchlist_disclosures(codes, limit)
    return ok(data)


@router.get("/{corp_code}")
@limiter.limit("30/minute")
async def list_disclosures(
    request: Request,
    corp_code: str,
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
):
    data = await dart_service.get_disclosures(corp_code, page, limit)
    return ok(data)


@router.get("/{rcept_no}/detail")
@limiter.limit("20/minute")
async def get_disclosure_detail(request: Request, rcept_no: str):
    content = await dart_service.get_disclosure_detail(rcept_no)
    if content is None:
        return JSONResponse(status_code=404, content=err("공시 원문을 찾을 수 없습니다"))
    return ok({"rcept_no": rcept_no, "content": content})
