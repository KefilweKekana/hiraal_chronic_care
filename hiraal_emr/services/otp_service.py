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
    cache_key = _cache_key(mobile)
    frappe.cache().set_value(cache_key, otp, expires_in_sec=OTP_EXPIRY_MINUTES * 60)
    frappe.logger("hiraal_otp").info(f"stored otp for key={cache_key}")
    return otp


def verify_otp(mobile: str, otp: str) -> bool:
    """Verify an OTP against the cached value and invalidate it on success.

    Logs the reason to the Error Log on failure so OTP problems can be
    diagnosed without server shell access.
    """
    cache_key = _cache_key(mobile)
    cached_otp = frappe.cache().get_value(cache_key)

    if cached_otp is None:
        frappe.log_error(
            title="OTP verify failed: no cached code",
            message=(
                f"key={cache_key} provided={otp!r}\n"
                "Cache held nothing for this number: the code expired, was "
                "already used, was overwritten by a newer request, or the key "
                "differs from the one used at request time."
            ),
        )
        return False

    if str(cached_otp).strip() == str(otp).strip():
        frappe.cache().delete_value(cache_key)
        return True

    frappe.log_error(
        title="OTP verify failed: code mismatch",
        message=f"key={cache_key} cached={cached_otp!r} provided={otp!r}",
    )
    return False
