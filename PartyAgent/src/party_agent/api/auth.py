"""Firebase ID-token verification for the chat endpoints.

Enforces the email-verified gate server-side: the Flutter app sends the user's
Firebase ID token as ``Authorization: Bearer <token>``; we verify it and require
the ``email_verified`` claim. Client-side checks are UX only — this is the real
boundary in front of the (paid) LLM.

Behaviour is controlled by ``AUTH_ENFORCED`` (default True). When disabled for
local dev the dependency is a no-op. When enabled it fails closed: if
firebase-admin cannot initialise, requests get 503 rather than slipping through.
"""

from __future__ import annotations

import logging
import os
import threading

from fastapi import HTTPException, Request

from party_agent.config import get_settings

log = logging.getLogger(__name__)

_init_lock = threading.Lock()
_initialized = False


def _ensure_firebase() -> None:
    """Initialise the firebase-admin app exactly once. Raises on failure."""
    global _initialized
    if _initialized:
        return
    with _init_lock:
        if _initialized:
            return
        import firebase_admin
        from firebase_admin import credentials

        if not firebase_admin._apps:
            cred_path = get_settings().firebase_service_account
            if cred_path and os.path.exists(cred_path):
                firebase_admin.initialize_app(credentials.Certificate(cred_path))
            else:
                # Application Default Credentials
                # (GOOGLE_APPLICATION_CREDENTIALS or GCP metadata server).
                firebase_admin.initialize_app()
        _initialized = True


def _extract_bearer(request: Request) -> str | None:
    header = request.headers.get("Authorization")
    if not header:
        return None
    scheme, _, token = header.partition(" ")
    if scheme.lower() != "bearer":
        return None
    return token.strip() or None


async def require_verified_user(request: Request) -> dict:
    """FastAPI dependency: require a verified-email Firebase user.

    Returns the decoded token claims (``uid``, ``email``, …) so handlers can
    trust the token identity over the client-supplied ``user_id``.
    """
    settings = get_settings()
    if not settings.auth_enforced:
        return {}

    token = _extract_bearer(request)
    if not token:
        raise HTTPException(status_code=401, detail="Missing bearer token")

    try:
        _ensure_firebase()
    except Exception as exc:  # noqa: BLE001 — fail closed on any init error
        log.error("firebase-admin init failed: %s: %s", type(exc).__name__, exc)
        raise HTTPException(status_code=503, detail="Auth service unavailable") from exc

    from firebase_admin import auth as firebase_auth

    try:
        decoded = firebase_auth.verify_id_token(token)
    except Exception as exc:  # noqa: BLE001 — any verify failure is a bad token
        raise HTTPException(status_code=401, detail="Invalid token") from exc

    if not decoded.get("email_verified"):
        raise HTTPException(status_code=403, detail="EMAIL_NOT_VERIFIED")

    return decoded
