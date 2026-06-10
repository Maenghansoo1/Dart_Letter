import asyncio
import logging

from fastapi import APIRouter, Header, Request
from fastapi.responses import JSONResponse
from supabase import create_client

import config
from utils import err, ok
from utils.rate_limiter import limiter
from db.supabase_client import get_supabase

router = APIRouter(prefix="/auth", tags=["인증"])
logger = logging.getLogger(__name__)


def _anon_client():
    """이메일 로그인용 anon key 클라이언트"""
    return create_client(config.SUPABASE_URL, config.SUPABASE_ANON_KEY)


# ── 회원가입 ───────────────────────────────────────────────────────────────────

@router.post("/signup")
@limiter.limit("5/minute")
async def signup(request: Request):
    body = await request.json()
    email = (body.get("email") or "").strip().lower()
    password = body.get("password") or ""
    nickname = (body.get("nickname") or "익명").strip()[:20]

    if not email or not password:
        return JSONResponse(status_code=400, content=err("이메일과 비밀번호를 입력하세요"))
    if len(password) < 6:
        return JSONResponse(status_code=400, content=err("비밀번호는 6자 이상이어야 합니다"))

    try:
        data = await asyncio.to_thread(_do_signup, email, password, nickname)
        return ok(data)
    except Exception as e:
        msg = str(e)
        if "already registered" in msg or "already been registered" in msg:
            return JSONResponse(status_code=409, content=err("이미 사용 중인 이메일입니다"))
        logger.error(f"회원가입 실패 {email}: {e}")
        return JSONResponse(status_code=400, content=err("회원가입에 실패했습니다"))


def _do_signup(email: str, password: str, nickname: str) -> dict:
    db = get_supabase()
    # service_role admin API: 이메일 미인증 상태로 생성 (확인 메일 발송)
    res = db.auth.admin.create_user({
        "email": email,
        "password": password,
        "user_metadata": {"nickname": nickname},
        "email_confirm": False,  # 이메일 확인 필요
    })
    user = res.user
    return {"user_id": user.id, "email": user.email, "nickname": nickname}


# ── 로그인 ────────────────────────────────────────────────────────────────────

@router.post("/login")
@limiter.limit("10/minute")
async def login(request: Request):
    body = await request.json()
    email = (body.get("email") or "").strip().lower()
    password = body.get("password") or ""

    if not email or not password:
        return JSONResponse(status_code=400, content=err("이메일과 비밀번호를 입력하세요"))

    try:
        data = await asyncio.to_thread(_do_login, email, password)
        return ok(data)
    except Exception as e:
        msg = str(e)
        logger.error(f"로그인 실패 {email}: {e}")
        if "Email not confirmed" in msg:
            return JSONResponse(status_code=403, content=err("이메일 인증을 완료해주세요"))
        return JSONResponse(status_code=401, content=err("이메일 또는 비밀번호가 올바르지 않습니다"))


def _do_login(email: str, password: str) -> dict:
    client = _anon_client()
    res = client.auth.sign_in_with_password({"email": email, "password": password})
    user = res.user
    session = res.session
    nickname = (user.user_metadata or {}).get("nickname", "익명")
    return {
        "access_token": session.access_token,
        "refresh_token": session.refresh_token,
        "user_id": user.id,
        "email": user.email,
        "nickname": nickname,
    }


# ── 토큰 갱신 ─────────────────────────────────────────────────────────────────

@router.post("/refresh")
async def refresh_token(request: Request):
    body = await request.json()
    refresh_token_val = body.get("refresh_token") or ""
    if not refresh_token_val:
        return JSONResponse(status_code=400, content=err("refresh_token이 없습니다"))
    try:
        data = await asyncio.to_thread(_do_refresh, refresh_token_val)
        return ok(data)
    except Exception as e:
        logger.error(f"토큰 갱신 실패: {e}")
        return JSONResponse(status_code=401, content=err("세션이 만료되었습니다. 다시 로그인해주세요"))


def _do_refresh(refresh_token_val: str) -> dict:
    client = _anon_client()
    res = client.auth.refresh_session(refresh_token_val)
    session = res.session
    user = res.user
    nickname = (user.user_metadata or {}).get("nickname", "익명")
    return {
        "access_token": session.access_token,
        "refresh_token": session.refresh_token,
        "user_id": user.id,
        "email": user.email,
        "nickname": nickname,
    }


# ── 내 정보 ───────────────────────────────────────────────────────────────────

@router.get("/me")
async def get_me(authorization: str | None = Header(None)):
    if not authorization or not authorization.startswith("Bearer "):
        return JSONResponse(status_code=401, content=err("로그인이 필요합니다"))
    token = authorization.removeprefix("Bearer ")
    try:
        data = await asyncio.to_thread(_get_user_from_token, token)
        return ok(data)
    except Exception:
        return JSONResponse(status_code=401, content=err("유효하지 않은 토큰입니다"))


def _get_user_from_token(token: str) -> dict:
    db = get_supabase()
    res = db.auth.get_user(token)
    user = res.user
    nickname = (user.user_metadata or {}).get("nickname", "익명")
    return {"user_id": user.id, "email": user.email, "nickname": nickname}


# ── 닉네임 수정 ───────────────────────────────────────────────────────────────

@router.patch("/nickname")
async def update_nickname(request: Request, authorization: str | None = Header(None)):
    if not authorization or not authorization.startswith("Bearer "):
        return JSONResponse(status_code=401, content=err("로그인이 필요합니다"))
    token = authorization.removeprefix("Bearer ")
    body = await request.json()
    nickname = (body.get("nickname") or "").strip()[:20]
    if not nickname:
        return JSONResponse(status_code=400, content=err("닉네임을 입력하세요"))
    try:
        await asyncio.to_thread(_update_nickname, token, nickname)
        return ok({"nickname": nickname})
    except Exception as e:
        logger.error(f"닉네임 수정 실패: {e}")
        return JSONResponse(status_code=400, content=err("닉네임 수정에 실패했습니다"))


def _update_nickname(token: str, nickname: str):
    db = get_supabase()
    user_res = db.auth.get_user(token)
    db.auth.admin.update_user_by_id(
        user_res.user.id,
        {"user_metadata": {"nickname": nickname}},
    )
