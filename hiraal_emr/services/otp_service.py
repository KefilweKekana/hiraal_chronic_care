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
    cached_otp = frappe.cache().get_value(cache_key)
    if cached_otp is not None and str(cached_otp).strip() == str(otp).strip():
        frappe.cache().delete_value(cache_key)
        return True
    return False
