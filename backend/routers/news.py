from fastapi import APIRouter, Query, Request

from services import naver_service
from utils import ok
from utils.rate_limiter import limiter

router = APIRouter(prefix="/news", tags=["뉴스"])

_CATEGORIES = list(naver_service.CATEGORY_QUERIES.keys())


@router.get("/categories")
async def news_categories(request: Request):
    return ok(_CATEGORIES)


@router.get("/latest")
@limiter.limit("30/minute")
async def latest_news(
    request: Request,
    category: str = Query("전체"),
):
    data = await naver_service.get_latest_news(category)
    return ok(data)


@router.get("/{corp_name}")
@limiter.limit("30/minute")
async def company_news(request: Request, corp_name: str):
    data = await naver_service.get_company_news(corp_name)
    return ok(data)
