import random
from typing import NamedTuple

import frappe
from frappe import _

OTP_LENGTH = 6
OTP_EXPIRY_MINUTES = 5
CACHE_PREFIX = "hiraal_otp_"

# OTP *send* limits (per phone or email). Not per IP — see OTP_IP_* below.
# After 3 sends, wait the remaining window (typically 60–120 seconds).
OTP_REQUEST_LIMIT = 3
OTP_REQUEST_WINDOW_SEC = 120
# SMS-cost / hammering cap. This is the longer lockout, not a few taps.
OTP_HOURLY_LIMIT = 12
OTP_HOURLY_WINDOW_SEC = 3600
# Shared clinic Wi-Fi: generous so one patient cannot lock a ward.
OTP_IP_LIMIT = 20
OTP_IP_WINDOW_SEC = 300

# Wrong-code brute force on verify (unchanged).
OTP_FAIL_LIMIT = 5
OTP_FAIL_WINDOW_SEC = 15 * 60


class OtpRequestGate(NamedTuple):
    allowed: bool
    retry_after: int  # seconds to wait when allowed is False


def _cache_key(mobile: str) -> str:
    """Build the cache key from a normalised mobile so request and verify
    always agree even if the client sends stray whitespace."""
    return f"{CACHE_PREFIX}{str(mobile).strip()}"


def generate_otp(mobile: str, length: int = OTP_LENGTH) -> str:
    """Generate a numeric OTP, store it in Frappe cache with expiry, and return it."""
    otp = "".join([str(random.randint(0, 9)) for _ in range(length)])
    frappe.cache().set_value(
        _cache_key(mobile), otp, expires_in_sec=OTP_EXPIRY_MINUTES * 60
    )
    return otp


def verify_otp(mobile: str, otp: str) -> bool:
    """Verify an OTP against the cached value and invalidate it on success."""
    cache_key = _cache_key(mobile)
    fail_key = f"hiraal_otp_fail:{cache_key}"
    fails = int(frappe.cache().get_value(fail_key) or 0)
    if fails >= OTP_FAIL_LIMIT:
        return False

    cached_otp = frappe.cache().get_value(cache_key)
    if cached_otp is not None and str(cached_otp).strip() == str(otp).strip():
        frappe.cache().delete_value(cache_key)
        frappe.cache().delete_value(fail_key)
        return True

    frappe.cache().set_value(fail_key, fails + 1, expires_in_sec=OTP_FAIL_WINDOW_SEC)
    return False


def otp_wait_message(retry_after: int) -> str:
    """Stable English-number message so the app can parse remaining seconds."""
    seconds = max(int(retry_after or 0), 1)
    return _("Please wait {0} seconds before requesting another code").format(seconds)


def check_otp_send_allowed(identifier: str, *, consume: bool = True) -> OtpRequestGate:
    """Gate OTP generation for a phone or email.

    Limits (fixed windows; TTL is set on first hit and not reset):
      - 3 sends / 120s per phone or email
      - 12 sends / hour per phone or email
      - 20 sends / 5 min per client IP
    """
    ident = str(identifier or "").strip()
    send_key = f"hiraal_otp_send:{_cache_key(ident)}"
    hour_key = f"hiraal_otp_hour:{_cache_key(ident)}"
    ip = (getattr(frappe.local, "request_ip", None) or "").strip()
    ip_key = f"hiraal_otp_ip:{ip}" if ip else ""

    wait = 0
    blocked = False

    send_count, send_ttl = _peek(send_key)
    if send_count >= OTP_REQUEST_LIMIT:
        blocked = True
        wait = max(wait, send_ttl or OTP_REQUEST_WINDOW_SEC)

    hour_count, hour_ttl = _peek(hour_key)
    if hour_count >= OTP_HOURLY_LIMIT:
        blocked = True
        wait = max(wait, hour_ttl or OTP_HOURLY_WINDOW_SEC)

    if ip_key:
        ip_count, ip_ttl = _peek(ip_key)
        if ip_count >= OTP_IP_LIMIT:
            blocked = True
            wait = max(wait, ip_ttl or OTP_IP_WINDOW_SEC)

    if blocked:
        return OtpRequestGate(False, max(int(wait), 1))

    if consume:
        _hit(send_key, OTP_REQUEST_WINDOW_SEC)
        _hit(hour_key, OTP_HOURLY_WINDOW_SEC)
        if ip_key:
            _hit(ip_key, OTP_IP_WINDOW_SEC)

    return OtpRequestGate(True, 0)


def request_allowed(mobile: str, limit: int = OTP_REQUEST_LIMIT, window_sec: int = OTP_REQUEST_WINDOW_SEC) -> bool:
    """Limit OTP generation per mobile number (or email identifier)."""
    # Custom limit/window is legacy; the shared gate is the policy.
    if limit != OTP_REQUEST_LIMIT or window_sec != OTP_REQUEST_WINDOW_SEC:
        key = f"hiraal_otp_send:{_cache_key(mobile)}"
        count, _ttl = _peek(key)
        if count >= limit:
            return False
        _hit(key, window_sec)
        return True
    return check_otp_send_allowed(mobile).allowed


def _peek(key: str) -> tuple[int, int]:
    """Return (count, ttl_seconds). Missing keys are (0, 0)."""
    raw = frappe.cache().get_value(key)
    if raw is None:
        return 0, 0
    return int(raw), _cache_ttl(key, default=0)


def _hit(key: str, window_sec: int) -> int:
    """Increment a fixed-window counter without resetting TTL on later hits."""
    cache = frappe.cache()
    if cache.get_value(key) is None:
        cache.set_value(key, 1, expires_in_sec=window_sec)
        return 1
    incr = getattr(cache, "incr", None)
    if callable(incr):
        try:
            return int(incr(key))
        except Exception:
            pass
    n = int(cache.get_value(key) or 0) + 1
    ttl = max(_cache_ttl(key, default=window_sec), 1)
    cache.set_value(key, n, expires_in_sec=ttl)
    return n


def _cache_ttl(key: str, default: int) -> int:
    cache = frappe.cache()
    for name in ("get_expiration_time", "ttl"):
        fn = getattr(cache, name, None)
        if not callable(fn):
            continue
        try:
            val = int(fn(key))
        except Exception:
            continue
        # Redis TTL: -2 missing, -1 no expiry, >=0 remaining seconds
        if val > 0:
            return val
    return int(default or 0)
