from fastapi import APIRouter, Query, Request

from services import category_service
from utils import ok
from utils.rate_limiter import limiter

router = APIRouter(prefix="/categories", tags=["카테고리"])

_SORT_VALUES = {"market_cap", "dividend_rate", "change_rate", "name"}


@router.get("")
@limiter.limit("60/minute")
async def list_categories(request: Request):
    """전체 카테고리 목록 + 종목 수"""
    data = await category_service.get_categories()
    return ok(data)


@router.get("/{category_name}/stocks")
@limiter.limit("30/minute")
async def category_stocks(
    request: Request,
    category_name: str,
    sort: str = Query("name"),
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
):
    """카테고리별 종목 목록 (정렬, 페이지네이션)"""
    if sort not in _SORT_VALUES:
        sort = "name"
    data = await category_service.get_category_stocks(category_name, sort, page, limit)
    return ok(data)


@router.post("/refresh")
async def refresh_categories(request: Request):
    """전체 종목 카테고리 재분류 (관리자 전용)"""
    count = await category_service.refresh_all()
    return ok({"classified": count})
