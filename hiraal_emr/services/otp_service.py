import random
import frappe

OTP_LENGTH = 6
OTP_EXPIRY_MINUTES = 5
CACHE_PREFIX = "hiraal_otp_"


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
    if fails >= 5:
        return False

    cached_otp = frappe.cache().get_value(cache_key)
    if cached_otp is not None and str(cached_otp).strip() == str(otp).strip():
        frappe.cache().delete_value(cache_key)
        frappe.cache().delete_value(fail_key)
        return True

    frappe.cache().set_value(fail_key, fails + 1, expires_in_sec=15 * 60)
    return False


def request_allowed(mobile: str, limit: int = 5, window_sec: int = 3600) -> bool:
    """Limit OTP generation per mobile number."""
    key = f"hiraal_otp_req:{_cache_key(mobile)}"
    count = int(frappe.cache().get_value(key) or 0)
    if count >= limit:
        return False
    frappe.cache().set_value(key, count + 1, expires_in_sec=window_sec)
    return True
