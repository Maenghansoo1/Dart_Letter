import asyncio
import logging

from fastapi import APIRouter, Query, Request
from fastapi.responses import JSONResponse

from db.supabase_client import get_supabase
from utils import err, ok
from utils.rate_limiter import limiter

router = APIRouter(prefix="/community", tags=["커뮤니티"])
logger = logging.getLogger(__name__)


# ── 게시글 목록 ───────────────────────────────────────────────────────────────

@router.get("/posts")
@limiter.limit("60/minute")
async def list_posts(
    request: Request,
    feed: str | None = Query(None),   # popular | stock | info
    corp_code: str | None = Query(None),
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=50),
):
    data = await asyncio.to_thread(_query_posts, feed, corp_code, page, limit)
    return ok(data)


def _query_posts(feed: str | None, corp_code: str | None, page: int, limit: int) -> dict:
    db = get_supabase()
    offset = (page - 1) * limit

    cols = "id, corp_code, corp_name, post_type, nickname, title, content, likes_count, comments_count, created_at"
    q = db.table("posts").select(cols)
    count_q = db.table("posts").select("id", count="exact")

    if corp_code:
        q = q.eq("corp_code", corp_code)
        count_q = count_q.eq("corp_code", corp_code)
    elif feed == "stock":
        q = q.not_.is_("corp_code", "null")
        count_q = count_q.not_.is_("corp_code", "null")
    elif feed == "info":
        q = q.is_("corp_code", "null")
        count_q = count_q.is_("corp_code", "null")
    # popular: 전체 대상 likes 순

    if feed == "popular":
        q = q.order("likes_count", desc=True).order("created_at", desc=True)
    else:
        q = q.order("created_at", desc=True)

    items = q.range(offset, offset + limit - 1).execute()
    count_res = count_q.execute()

    return {
        "items": items.data or [],
        "total": count_res.count or 0,
        "page": page,
        "limit": limit,
    }


# ── 게시글 작성 ───────────────────────────────────────────────────────────────

@router.post("/posts")
@limiter.limit("10/minute")
async def create_post(request: Request):
    body = await request.json()
    try:
        data = await asyncio.to_thread(_insert_post, body)
        return ok(data)
    except ValueError as e:
        return JSONResponse(status_code=400, content=err(str(e)))


def _insert_post(body: dict) -> dict:
    title = (body.get("title") or "").strip()
    content = (body.get("content") or "").strip()
    if not title or not content:
        raise ValueError("제목과 내용을 입력하세요")

    corp_code = body.get("corp_code") or None
    post = {
        "corp_code": corp_code,
        "corp_name": body.get("corp_name") or None,
        "post_type": "info" if not corp_code else "stock",
        "nickname": (body.get("nickname") or "익명").strip()[:20],
        "title": title[:100],
        "content": content[:2000],
    }
    db = get_supabase()
    res = db.table("posts").insert(post).execute()
    return res.data[0]


# ── 게시글 상세 ───────────────────────────────────────────────────────────────

@router.get("/posts/{post_id}")
async def get_post(request: Request, post_id: str):
    res = await asyncio.to_thread(
        lambda: get_supabase().table("posts").select("*").eq("id", post_id).maybe_single().execute()
    )
    if not res.data:
        return JSONResponse(status_code=404, content=err("게시글을 찾을 수 없습니다"))
    return ok(res.data)


# ── 좋아요 ────────────────────────────────────────────────────────────────────

@router.post("/posts/{post_id}/like")
@limiter.limit("30/minute")
async def like_post(request: Request, post_id: str):
    try:
        new_count = await asyncio.to_thread(_increment_likes, post_id)
        return ok({"likes_count": new_count})
    except ValueError as e:
        return JSONResponse(status_code=404, content=err(str(e)))


def _increment_likes(post_id: str) -> int:
    db = get_supabase()
    res = db.table("posts").select("likes_count").eq("id", post_id).maybe_single().execute()
    if not res.data:
        raise ValueError("게시글을 찾을 수 없습니다")
    new_count = (res.data.get("likes_count") or 0) + 1
    db.table("posts").update({"likes_count": new_count}).eq("id", post_id).execute()
    return new_count


# ── 댓글 목록 ─────────────────────────────────────────────────────────────────

@router.get("/posts/{post_id}/comments")
async def list_comments(request: Request, post_id: str):
    res = await asyncio.to_thread(
        lambda: get_supabase()
        .table("comments")
        .select("id, post_id, nickname, content, created_at")
        .eq("post_id", post_id)
        .order("created_at")
        .execute()
    )
    return ok(res.data or [])


# ── 댓글 작성 ─────────────────────────────────────────────────────────────────

@router.post("/posts/{post_id}/comments")
@limiter.limit("10/minute")
async def create_comment(request: Request, post_id: str):
    body = await request.json()
    try:
        data = await asyncio.to_thread(_insert_comment, post_id, body)
        return ok(data)
    except ValueError as e:
        return JSONResponse(status_code=400, content=err(str(e)))


def _insert_comment(post_id: str, body: dict) -> dict:
    content = (body.get("content") or "").strip()
    if not content:
        raise ValueError("내용을 입력하세요")

    db = get_supabase()
    comment = {
        "post_id": post_id,
        "nickname": (body.get("nickname") or "익명").strip()[:20],
        "content": content[:500],
    }
    res = db.table("comments").insert(comment).execute()

    # comments_count 증가
    post = db.table("posts").select("comments_count").eq("id", post_id).maybe_single().execute()
    if post.data:
        db.table("posts").update({
            "comments_count": (post.data.get("comments_count") or 0) + 1
        }).eq("id", post_id).execute()

    return res.data[0]
