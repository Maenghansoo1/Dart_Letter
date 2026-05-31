import asyncio
import logging
from datetime import datetime, timezone, timedelta

from db.supabase_client import get_supabase

logger = logging.getLogger(__name__)


async def cache_get(
    table: str, key_col: str, key_val: str, ttl_hours: int | None = None
) -> dict | None:
    return await asyncio.to_thread(_sync_get, table, key_col, key_val, ttl_hours)


def _sync_get(
    table: str, key_col: str, key_val: str, ttl_hours: int | None
) -> dict | None:
    try:
        db = get_supabase()
        result = db.table(table).select("*").eq(key_col, key_val).maybe_single().execute()
        if not result.data:
            return None

        if ttl_hours is not None:
            cached_at_str = result.data.get("cached_at")
            if cached_at_str:
                cached_at = datetime.fromisoformat(cached_at_str.replace("Z", "+00:00"))
                if datetime.now(timezone.utc) - cached_at > timedelta(hours=ttl_hours):
                    return None

        return result.data
    except Exception as e:
        logger.warning(f"캐시 조회 실패 [{table}] {key_val}: {e}")
        return None


async def cache_set(table: str, data: dict) -> None:
    await asyncio.to_thread(_sync_set, table, data)


def _sync_set(table: str, data: dict) -> None:
    try:
        db = get_supabase()
        data_ts = {**data, "cached_at": datetime.now(timezone.utc).isoformat()}
        db.table(table).upsert(data_ts).execute()
    except Exception as e:
        logger.warning(f"캐시 저장 실패 [{table}]: {e}")
