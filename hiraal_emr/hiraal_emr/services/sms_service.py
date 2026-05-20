import frappe
from frappe import _


def _get_settings():
    return frappe.get_doc("Chronic Care Settings", "Chronic Care Settings")


def send_sms(to: str, message: str) -> dict:
    """Send SMS via configured provider (Africa's Talking, Twilio, or Telesom)."""
    settings = _get_settings()
    if not settings.enable_sms_notifications:
        return {"status": "skipped", "reason": "SMS notifications disabled"}

    provider = settings.sms_provider or "Africa's Talking"
    result = {"status": "queued", "provider": provider}

    if provider == "Africa's Talking":
        result = _send_africas_talking(to, message, settings)
    elif provider == "Twilio":
        result = _send_twilio(to, message, settings)
    elif provider == "Telesom":
        result = _send_telesom(to, message, settings)
    else:
        result = {"status": "error", "reason": f"Unknown provider {provider}"}

    return result


def _send_africas_talking(to, message, settings):
    # TODO: integrate africa's talking REST API
    frappe.log_error(
        title=_("Africa's Talking SMS not yet integrated"),
        message=f"To: {to}, Message: {message}"
    )
    return {"status": "stub", "provider": "Africa's Talking"}


def _send_twilio(to, message, settings):
    # TODO: integrate Twilio REST API
    frappe.log_error(
        title=_("Twilio SMS not yet integrated"),
        message=f"To: {to}, Message: {message}"
    )
    return {"status": "stub", "provider": "Twilio"}


def _send_telesom(to, message, settings):
    """Send SMS via Telesom (Somaliland).

    Tries to use the external ``telesom_sms`` Frappe app if installed;
    otherwise falls back to an inline implementation that reads credentials
    from ``Telesom SMS Settings`` (the settings DocType shipped by that app).
    """
    # --- 1. Try the dedicated app (cleanest, handles hashing / logging) ---
    try:
        from telesom_sms.services.telesom_api import send_single_sms

        result = send_single_sms(to, message)
        if result.get("success"):
            return {
                "status": "sent",
                "provider": "Telesom",
                "detail": result.get("data") or result.get("response"),
            }
        return {
            "status": "error",
            "provider": "Telesom",
            "reason": result.get("error", "Unknown Telesom error"),
        }
    except ImportError:
        pass  # telesom_sms app not installed – fall through

    # --- 2. Inline fallback (self-contained, no extra app required) ---
    return _send_telesom_inline(to, message)


def _send_telesom_inline(to, message):
    """Inline Telesom sender that duplicates the hashing logic so
    ``hiraal_emr`` can send SMS even when ``telesom_sms`` is not installed.
    """
    import datetime
    import hashlib
    import re

    import requests

    DEFAULT_API_URL = "https://sms.mytelesom.com/index.php/Gway/sendsms/"

    # Read from the Telesom SMS Settings single DocType
    if not frappe.db.exists("DocType", "Telesom SMS Settings"):
        frappe.log_error(
            title=_("Telesom SMS not configured"),
            message=(
                "Telesom SMS Settings DocType not found. "
                "Either install the 'telesom_sms' app or create a "
                "'Telesom SMS Settings' single DocType with credentials."
            ),
        )
        return {
            "status": "error",
            "provider": "Telesom",
            "reason": "Telesom SMS Settings not found",
        }

    ts = frappe.get_doc("Telesom SMS Settings", "Telesom SMS Settings")
    if not ts.enabled:
        return {
            "status": "skipped",
            "provider": "Telesom",
            "reason": "Telesom SMS disabled in settings",
        }

    username = str(ts.username or "").strip()
    password = frappe.utils.password.get_decrypted_password(
        "Telesom SMS Settings", "Telesom SMS Settings", "password"
    ) or ""
    sender = str(ts.sender_id or "").strip()
    api_key = frappe.utils.password.get_decrypted_password(
        "Telesom SMS Settings", "Telesom SMS Settings", "api_key"
    ) or ""
    api_url = str(ts.api_url or "").strip() or DEFAULT_API_URL
    api_url = api_url.replace("/Gateway/sendsms", "/Gway/sendsms").rstrip("/") + "/"

    if not username:
        return {"status": "error", "provider": "Telesom", "reason": "Username missing"}
    if not password:
        return {"status": "error", "provider": "Telesom", "reason": "Password missing"}
    if not sender:
        return {"status": "error", "provider": "Telesom", "reason": "Sender ID missing"}
    if not api_key:
        return {"status": "error", "provider": "Telesom", "reason": "API Key missing"}

    # Normalise mobile
    mobile = str(to or "").strip().replace(" ", "").replace("+", "")

    # Strip HTML
    clean_msg = str(message or "")
    clean_msg = re.sub(r"(?i)<br\s*/?>", "\n", clean_msg)
    clean_msg = re.sub(r"(?i)</p\s*>", "\n", clean_msg)
    clean_msg = re.sub(r"(?i)</div\s*>", "\n", clean_msg)
    clean_msg = re.sub(r"<[^>]+>", "", clean_msg)
    for old, new in (
        ("&nbsp;", " "), ("&amp;", "&"), ("&lt;", "<"),
        ("&gt;", ">"), ("&quot;", '"'), ("&#39;", "'"),
    ):
        clean_msg = clean_msg.replace(old, new)
    clean_msg = clean_msg.replace("\r\n", "\n").replace("\r", "\n")
    clean_msg = re.sub(r"[ \t]+", " ", clean_msg)
    clean_msg = re.sub(r" *\n *", "\n", clean_msg)
    clean_msg = re.sub(r"\n{3,}", "\n\n", clean_msg).strip()

    # Telesom requires spaces as %20
    telesom_msg = clean_msg.replace(" ", "%20")
    date_str = datetime.datetime.now().strftime("%d/%m/%Y")

    # Build MD5 hash exactly as Telesom expects
    hash_string = "{0}|{1}|{2}|{3}|{4}|{5}|{6}".format(
        username, password, mobile, telesom_msg, sender, date_str, api_key
    )
    hash_key = hashlib.md5(hash_string.encode("utf-8")).hexdigest().upper()

    payload = {
        "From": sender,
        "to": mobile,
        "msg": telesom_msg,
        "key": hash_key,
        "from": sender,
        "sender": sender,
        "senderid": sender,
        "SenderID": sender,
        "message": telesom_msg,
    }

    try:
        response = requests.post(api_url, data=payload, timeout=30)
    except requests.exceptions.Timeout:
        frappe.log_error(
            title=_("Telesom SMS Timeout"), message=f"To: {mobile}"
        )
        return {"status": "error", "provider": "Telesom", "reason": "Request timed out"}
    except Exception as e:
        frappe.log_error(
            title=_("Telesom SMS Error"), message=f"To: {mobile}, Error: {e}"
        )
        return {"status": "error", "provider": "Telesom", "reason": str(e)}

    text = (response.text or "").strip()
    success = False
    if response.status_code == 200:
        try:
            data = frappe.parse_json(text)
            status = str(data.get("status", "")).lower()
            if status in ("success", "sent", "ok"):
                success = True
        except Exception:
            lowered = text.lower()
            if "wrong hash" not in lowered and "sender id required" not in lowered and '"status":"error"' not in lowered:
                success = True

    if success:
        return {
            "status": "sent",
            "provider": "Telesom",
            "status_code": response.status_code,
            "response": text,
        }

    frappe.log_error(
        title=_("Telesom SMS Failed"),
        message=f"To: {mobile}, HTTP {response.status_code}: {text}",
    )
    return {
        "status": "error",
        "provider": "Telesom",
        "reason": f"HTTP {response.status_code}: {text}",
        "status_code": response.status_code,
    }


def send_otp_sms(mobile: str, otp: str) -> dict:
    """Send an OTP SMS in Somali/English."""
    message = (
        f"Hiraal Chronic Care: Your verification code is {otp}. "
        f"It expires in 5 minutes. Do not share this code with anyone."
    )
    return send_sms(mobile, message)


def send_alert_sms(mobile: str, alert_message: str) -> dict:
    """Send an urgent alert SMS to a patient or care team member."""
    settings = _get_settings()
    if not settings.urgent_alert_sms:
        return {"status": "skipped", "reason": "Urgent alert SMS disabled"}
    return send_sms(mobile, alert_message)
