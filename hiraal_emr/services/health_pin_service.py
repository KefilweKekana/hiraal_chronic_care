"""Patient health PIN: 4-digit PIN hashed with a per-patient salt.

The PIN is never stored in plaintext, never logged, and never returned
from any API. Verify returns a short-lived unlock token (or a structured
failure). Wrong-PIN lockout matches OTP: 5 failures, then wait 15 minutes.
"""

from __future__ import annotations

import hashlib
import hmac
import secrets

import frappe
from frappe import _

from hiraal_emr.services.otp_service import OTP_FAIL_LIMIT, OTP_FAIL_WINDOW_SEC, verify_otp as otp_verify
from hiraal_emr.services.security_helpers import client_rate_key, rate_limit

DOCTYPE = "Patient Health PIN"
HASH_ITERATIONS = 120_000
UNLOCK_TTL_SEC = 15 * 60
PIN_FAIL_LIMIT = OTP_FAIL_LIMIT  # 5
PIN_FAIL_WINDOW_SEC = OTP_FAIL_WINDOW_SEC  # 15 minutes
_PIN_KEYS = (
    "health_pin_hash",
    "health_pin_salt",
    "custom_health_pin_hash",
    "custom_health_pin_salt",
    "pin_hash",
    "pin_salt",
)


def normalize_pin(pin) -> str:
    raw = str(pin or "").strip()
    if len(raw) != 4 or not raw.isdigit():
        frappe.throw(_("PIN must be 4 digits"))
    return raw


def new_salt() -> str:
    return secrets.token_hex(16)


def hash_pin(pin: str, salt: str) -> str:
    """SHA-256 (PBKDF2) with a per-patient salt. Never log [pin]."""
    return hashlib.pbkdf2_hmac(
        "sha256",
        pin.encode("utf-8"),
        bytes.fromhex(salt),
        HASH_ITERATIONS,
    ).hex()


def pins_match(pin: str, salt: str, stored_hash: str) -> bool:
    if not salt or not stored_hash:
        return False
    try:
        expected = hash_pin(pin, salt)
    except (ValueError, TypeError):
        return False
    return hmac.compare_digest(expected, stored_hash)


def strip_pin_fields(data: dict) -> dict:
    """Remove any hash/salt keys so Patient payloads never leak them."""
    for key in _PIN_KEYS:
        data.pop(key, None)
    return data


def patient_has_pin(patient: str) -> bool:
    if not patient:
        return False
    try:
        if frappe.db.has_column("Patient", "custom_health_pin_hash"):
            stored = frappe.db.get_value("Patient", patient, "custom_health_pin_hash")
            if stored:
                return True
    except Exception:
        pass
    try:
        return bool(frappe.db.exists(DOCTYPE, {"patient": patient}))
    except Exception:
        return False


def _session_user() -> str:
    user = getattr(frappe.session, "user", None)
    if not user or user == "Guest":
        frappe.throw(_("Not authenticated"), frappe.AuthenticationError)
    return user


def _own_patient() -> str | None:
    user = getattr(frappe.session, "user", None)
    if not user or user == "Guest":
        return None
    return frappe.db.get_value("Patient", {"user_id": user}, "name")


def _caregiver_linked(patient: str) -> bool:
    user = getattr(frappe.session, "user", None)
    if not user or user == "Guest" or not patient:
        return False
    return bool(
        frappe.db.exists(
            "Family Member",
            {
                "patient": patient,
                "caregiver_user": user,
                "link_status": ["in", ["Accepted", "Active"]],
            },
        )
    )


def _resolve_view_patient(patient=None) -> str:
    """Own record, or a loved one this caregiver is linked to."""
    _session_user()
    requested = (patient or "").strip()
    own = _own_patient()
    if not requested or (own and requested == own):
        if not own:
            frappe.throw(_("No patient linked to this account"), frappe.AuthenticationError)
        return own
    if not _caregiver_linked(requested):
        frappe.throw(_("Not permitted"), frappe.PermissionError)
    return requested


def _fail_key(patient: str) -> str:
    return f"hiraal_health_pin_fail:{patient}"


def _fail_state(patient: str) -> tuple[int, int]:
    key = _fail_key(patient)
    fails = int(frappe.cache().get_value(key) or 0)
    ttl = 0
    cache = frappe.cache()
    for name in ("get_expiration_time", "ttl"):
        fn = getattr(cache, name, None)
        if not callable(fn):
            continue
        try:
            val = int(fn(key))
        except Exception:
            continue
        if val > 0:
            ttl = val
            break
    return fails, ttl


def _record_fail(patient: str) -> tuple[int, int]:
    key = _fail_key(patient)
    fails, _ttl = _fail_state(patient)
    nxt = fails + 1
    frappe.cache().set_value(key, nxt, expires_in_sec=PIN_FAIL_WINDOW_SEC)
    return nxt, PIN_FAIL_WINDOW_SEC if nxt >= PIN_FAIL_LIMIT else 0


def _clear_fails(patient: str):
    frappe.cache().delete_value(_fail_key(patient))


def _issue_token(patient: str) -> str:
    token = secrets.token_urlsafe(32)
    frappe.cache().set_value(
        f"hiraal_health_unlock:{token}",
        patient,
        expires_in_sec=UNLOCK_TTL_SEC,
    )
    return token


def _load_row(patient: str):
    """Prefer Patient custom columns. Never instantiate Patient Health PIN
    (UAT registered that DocType under Core and its controller import fails)."""
    try:
        if frappe.db.has_column("Patient", "custom_health_pin_hash"):
            row = frappe.db.get_value(
                "Patient",
                patient,
                ["custom_health_pin_hash", "custom_health_pin_salt"],
                as_dict=True,
            )
            if row and row.get("custom_health_pin_hash") and row.get("custom_health_pin_salt"):
                return frappe._dict(
                    name=patient,
                    pin_hash=row.custom_health_pin_hash,
                    pin_salt=row.custom_health_pin_salt,
                )
    except Exception:
        pass
    try:
        name = frappe.db.exists(DOCTYPE, {"patient": patient})
        if not name:
            return None
        return frappe.db.get_value(DOCTYPE, name, ["name", "pin_hash", "pin_salt"], as_dict=True)
    except Exception:
        return None


def _ensure_patient_pin_columns():
    """Hidden hash/salt columns on Patient so Save PIN never loads a DocType controller."""
    for fieldname, label in (
        ("custom_health_pin_hash", "Health PIN Hash"),
        ("custom_health_pin_salt", "Health PIN Salt"),
    ):
        if frappe.db.exists("Custom Field", {"dt": "Patient", "fieldname": fieldname}):
            continue
        frappe.get_doc(
            {
                "doctype": "Custom Field",
                "dt": "Patient",
                "fieldname": fieldname,
                "label": label,
                "fieldtype": "Data",
                "hidden": 1,
                "read_only": 1,
                "no_copy": 1,
                "insert_after": "mobile",
            }
        ).insert(ignore_permissions=True)
    frappe.clear_cache(doctype="Patient")


def _write_pin(patient: str, pin: str):
    _ensure_patient_pin_columns()
    salt = new_salt()
    digest = hash_pin(pin, salt)
    frappe.db.set_value(
        "Patient",
        patient,
        {
            "custom_health_pin_hash": digest,
            "custom_health_pin_salt": salt,
        },
        update_modified=False,
    )
    frappe.db.commit()
    _clear_fails(patient)


def has_health_pin(patient=None):
    """Boolean only. Never returns a hash, salt, or PIN."""
    target = _resolve_view_patient(patient)
    return {"has_pin": patient_has_pin(target)}


def set_health_pin(pin=None, current_pin=None):
    """Create or replace the caller's own health PIN.

    First-time setup needs only [pin]. Changing an existing PIN needs
    [current_pin]. Caregivers cannot set a loved one's PIN.
    """
    own = _own_patient()
    if not own:
        frappe.throw(_("No patient linked to this account"), frappe.AuthenticationError)
    rate_limit(client_rate_key("health_pin_set", own), limit=10, window_sec=3600)
    new_pin = normalize_pin(pin)
    row = _load_row(own)
    if row:
        current = normalize_pin(current_pin)
        if not pins_match(current, row.pin_salt, row.pin_hash):
            frappe.throw(_("Current PIN is incorrect"))
    _write_pin(own, new_pin)
    try:
        from hiraal_emr.doctype.audit_log.audit_log import log_action as audit_log

        audit_log("Update", DOCTYPE, own, "Health PIN set")
    except Exception:
        pass
    return {"success": True}


def verify_health_pin(pin=None, patient=None):
    """Check a PIN for the caller or a linked loved one. Rate-limited."""
    target = _resolve_view_patient(patient)
    rate_limit(client_rate_key("health_pin_verify", target), limit=30, window_sec=3600)

    fails, ttl = _fail_state(target)
    if fails >= PIN_FAIL_LIMIT:
        wait = max(int(ttl or PIN_FAIL_WINDOW_SEC), 1)
        return {
            "ok": False,
            "locked": True,
            "retry_after": wait,
            "attempts_left": 0,
            "message": _("Too many incorrect attempts. Please wait {0} seconds.").format(wait),
        }

    row = _load_row(target)
    if not row:
        return {
            "ok": False,
            "locked": False,
            "has_pin": False,
            "attempts_left": PIN_FAIL_LIMIT,
            "message": _("This patient has not created a health PIN yet"),
        }

    try:
        candidate = normalize_pin(pin)
    except Exception:
        candidate = ""

    if candidate and pins_match(candidate, row.pin_salt, row.pin_hash):
        _clear_fails(target)
        token = _issue_token(target)
        return {
            "ok": True,
            "token": token,
            "expires_in": UNLOCK_TTL_SEC,
            "has_pin": True,
        }

    nxt, wait = _record_fail(target)
    left = max(PIN_FAIL_LIMIT - nxt, 0)
    locked = nxt >= PIN_FAIL_LIMIT
    return {
        "ok": False,
        "locked": locked,
        "has_pin": True,
        "retry_after": wait if locked else 0,
        "attempts_left": left,
        "message": (
            _("Too many incorrect attempts. Please wait {0} seconds.").format(wait)
            if locked
            else _("Incorrect PIN")
        ),
    }


def reset_health_pin(otp=None, new_pin=None, mobile=None):
    """Replace the PIN after OTP to the patient's phone (same number).

    Guest callers must send [mobile]. Signed-in patients use the number
    on their record. Caregivers cannot reset a loved one's PIN.
    """
    rate_limit(client_rate_key("health_pin_reset", mobile or ""), limit=8, window_sec=3600)
    pin = normalize_pin(new_pin)
    code = str(otp or "").strip()
    if not code:
        frappe.throw(_("A verification code is required"))

    own = _own_patient()
    if own:
        # Always OTP the number on the patient record, not a caller-supplied one.
        target_mobile = frappe.db.get_value("Patient", own, "mobile")
        patient = own
    else:
        target_mobile = (mobile or "").strip()
        if not target_mobile:
            frappe.throw(_("A valid phone number is required"))
        from hiraal_emr.api import _mobile_candidates

        patient = frappe.db.get_value(
            "Patient",
            {"mobile": ["in", _mobile_candidates(target_mobile)], "status": "Active"},
            "name",
        )
        if not patient:
            frappe.throw(_("Patient not found"), frappe.AuthenticationError)

    if not otp_verify(target_mobile, code):
        frappe.throw(_("Invalid or expired code"), frappe.AuthenticationError)

    _write_pin(patient, pin)
    try:
        from hiraal_emr.doctype.audit_log.audit_log import log_action as audit_log

        audit_log("Update", DOCTYPE, patient, "Health PIN reset after OTP")
    except Exception:
        pass
    return {"success": True}
