import random
import frappe

OTP_LENGTH = 6
OTP_EXPIRY_MINUTES = 5
CACHE_PREFIX = "hiraal_otp_"


def _cache_key(mobile: str) -> str:
    """Build the cache key from a normalised mobile so request and verify
    always agree even if the client sends stray whitespace."""
    return f"{CACHE_PREFIX}{str(mobile).strip()}"


def _log_otp(mobile, result, provided=None, cached=None, remarks=None):
    """Persist an OTP attempt to the 'Hiraal OTP Log' doctype.

    Commits immediately so the entry survives the transaction rollback that
    follows an authentication failure (verify_otp raises AuthenticationError).
    Never lets a logging problem break the OTP flow.
    """
    # Primary, always-visible sink: the Error Log (its table always exists).
    # Commit so the entry survives the rollback that verify_otp's frappe.throw
    # triggers — that rollback is why earlier non-committed logs vanished.
    try:
        frappe.log_error(
            title=f"Hiraal OTP: {result}",
            message=(
                f"mobile={mobile!r}\nresult={result}\n"
                f"provided={provided!r}\ncached={cached!r}\nremarks={remarks}"
            ),
        )
        frappe.db.commit()
    except Exception:
        frappe.logger("hiraal_otp").exception("failed to write OTP Error Log")

    # Secondary, best-effort structured sink (only if the doctype is migrated).
    try:
        doc = frappe.new_doc("Hiraal OTP Log")
        doc.mobile = str(mobile or "")
        doc.result = result
        doc.provided_code = None if provided is None else str(provided)
        doc.cached_code = None if cached is None else str(cached)
        doc.remarks = remarks
        doc.insert(ignore_permissions=True)
        frappe.db.commit()
    except Exception:
        frappe.db.rollback()


def generate_otp(mobile: str, length: int = OTP_LENGTH) -> str:
    """Generate a numeric OTP, store it in Frappe cache with expiry, and return it."""
    otp = "".join([str(random.randint(0, 9)) for _ in range(length)])
    cache_key = _cache_key(mobile)
    frappe.cache().set_value(cache_key, otp, expires_in_sec=OTP_EXPIRY_MINUTES * 60)
    _log_otp(mobile, "Sent", cached=otp, remarks=f"key={cache_key}")
    return otp


def verify_otp(mobile: str, otp: str) -> bool:
    """Verify an OTP against the cached value and invalidate it on success.

    Every attempt is recorded in the 'Hiraal OTP Log' doctype so OTP problems
    can be diagnosed from the desk without server shell access.
    """
    cache_key = _cache_key(mobile)
    cached_otp = frappe.cache().get_value(cache_key)

    if cached_otp is None:
        _log_otp(
            mobile,
            "No Cached Code",
            provided=otp,
            remarks=(
                f"key={cache_key} — cache held nothing: code expired, already "
                "used, overwritten by a newer request, or key mismatch."
            ),
        )
        return False

    if str(cached_otp).strip() == str(otp).strip():
        frappe.cache().delete_value(cache_key)
        _log_otp(mobile, "Verified", provided=otp, cached=cached_otp, remarks=f"key={cache_key}")
        return True

    _log_otp(mobile, "Mismatch", provided=otp, cached=cached_otp, remarks=f"key={cache_key}")
    return False
