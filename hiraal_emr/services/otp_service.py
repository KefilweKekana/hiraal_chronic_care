import random
import frappe
from frappe.utils import now, add_to_date

OTP_LENGTH = 6
OTP_EXPIRY_MINUTES = 5
CACHE_PREFIX = "hiraal_otp_"


def generate_otp(mobile: str, length: int = OTP_LENGTH) -> str:
    """Generate a numeric OTP, store it in Frappe cache with expiry, and return it."""
    otp = "".join([str(random.randint(0, 9)) for _ in range(length)])
    cache_key = f"{CACHE_PREFIX}{mobile}"
    frappe.cache().set_value(cache_key, otp, expires_in_sec=OTP_EXPIRY_MINUTES * 60)
    return otp


def verify_otp(mobile: str, otp: str) -> bool:
    """Verify an OTP against the cached value and invalidate it on success."""
    cache_key = f"{CACHE_PREFIX}{mobile}"
    cached_otp = frappe.cache().get_value(cache_key)
    if cached_otp and str(cached_otp) == str(otp):
        frappe.cache().delete_value(cache_key)
        return True
    return False
