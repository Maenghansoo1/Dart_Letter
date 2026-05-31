def ok(data) -> dict:
    return {"success": True, "data": data, "error": None}


def err(msg: str) -> dict:
    return {"success": False, "data": None, "error": msg}
