"""Family Care web portal: OTP session login for caregivers and sponsors."""

from __future__ import annotations

import re

import frappe
from frappe import _
from frappe.utils import flt, now_datetime

from hiraal_emr.services.caregiver_service import (
    _serialize_link,
    list_sponsorships_for_user,
    redeem_invitation_code,
)
from hiraal_emr.services.otp_service import generate_otp, request_allowed, verify_otp
from hiraal_emr.services.security_helpers import client_rate_key, rate_limit
from hiraal_emr.services.sms_service import send_otp_sms


def _require_logged_in() -> str:
    user = frappe.session.user
    if not user or user == "Guest":
        frappe.throw(_("Please sign in to continue"), frappe.AuthenticationError)
    return user


def _digits(value: str) -> str:
    return re.sub(r"\D", "", value or "")


def _mobile_candidates(mobile: str) -> list[str]:
    raw = str(mobile or "").strip()
    digits = _digits(raw)
    nsn = digits[3:] if digits.startswith("252") else digits
    nsn = nsn.lstrip("0")
    cands = {raw, digits}
    if nsn:
        cands.update({nsn, "0" + nsn, "252" + nsn, "+252" + nsn})
    return [c for c in cands if c]


def _find_user_by_mobile(mobile: str) -> str | None:
    candidates = _mobile_candidates(mobile)
    for cand in candidates:
        user = frappe.db.get_value("User", {"mobile_no": cand, "enabled": 1}, "name")
        if user:
            return user
    digits = _digits(mobile)
    tail = digits[-9:] if len(digits) >= 9 else digits
    if tail:
        user = frappe.db.get_value("User", {"mobile_no": ["like", f"%{tail}"], "enabled": 1}, "name")
        if user:
            return user
    patient_user = frappe.db.get_value(
        "Patient",
        {"mobile": ["in", candidates], "status": "Active"},
        "user_id",
    )
    return patient_user or None


def _ensure_caregiver_user(mobile: str, full_name: str | None = None) -> str:
    existing = _find_user_by_mobile(mobile)
    if existing:
        if full_name and not frappe.db.get_value("User", existing, "first_name"):
            frappe.db.set_value("User", existing, "first_name", full_name, update_modified=False)
        return existing

    digits = _digits(mobile) or "caregiver"
    email = f"{digits}@caregiver.hiraal.local"
    if frappe.db.exists("User", email):
        user_doc = frappe.get_doc("User", email)
        if not user_doc.mobile_no:
            user_doc.mobile_no = mobile
            user_doc.save(ignore_permissions=True)
        return user_doc.name

    user_doc = frappe.new_doc("User")
    user_doc.email = email
    user_doc.first_name = (full_name or "").strip() or "Family caregiver"
    user_doc.mobile_no = mobile
    user_doc.send_welcome_email = 0
    user_doc.user_type = "Website User"
    user_doc.insert(ignore_permissions=True)
    try:
        user_doc.add_roles("Customer")
    except Exception:
        pass
    return user_doc.name


def _login_as(user: str):
    from frappe.auth import LoginManager

    manager = getattr(frappe.local, "login_manager", None) or LoginManager()
    frappe.local.login_manager = manager
    manager.login_as(user)
    frappe.db.commit()


def request_portal_otp(mobile: str):
    mobile = (mobile or "").strip()
    if len(_digits(mobile)) < 6:
        frappe.throw(_("Enter a valid mobile number"))
    rate_limit(client_rate_key("portal_otp", mobile), limit=8, window_sec=3600)
    if not request_allowed(mobile):
        return {"success": True, "message": "OTP sent"}
    otp = generate_otp(mobile)
    send_otp_sms(mobile, otp)
    return {"success": True, "message": "OTP sent"}


def verify_portal_otp(mobile: str, otp: str, full_name: str | None = None, invite_code: str | None = None):
    mobile = (mobile or "").strip()
    otp = (otp or "").strip()
    if not otp:
        frappe.throw(_("Enter the verification code"))
    rate_limit(client_rate_key("portal_verify", mobile), limit=12, window_sec=900)
    if not verify_otp(mobile, otp):
        frappe.throw(_("Invalid or expired code"), frappe.AuthenticationError)

    existing = _find_user_by_mobile(mobile)
    new_account = not bool(existing)
    user = _ensure_caregiver_user(mobile, full_name)
    _login_as(user)

    redeemed = None
    code = (invite_code or "").strip().upper()
    if code:
        try:
            doc = redeem_invitation_code(code, user)
            redeemed = _serialize_link(doc.as_dict())
        except Exception:
            frappe.clear_messages()

    return {
        "success": True,
        "new_account": new_account,
        "user": user,
        "full_name": frappe.db.get_value("User", user, "full_name") or full_name,
        "csrf_token": frappe.sessions.get_csrf_token(),
        "redeemed": redeemed,
        "session": bootstrap(),
    }


def logout_portal():
    if frappe.session.user and frappe.session.user != "Guest":
        frappe.local.login_manager.logout()
        frappe.db.commit()
    return {"success": True}


def bootstrap():
    user = frappe.session.user
    if not user or user == "Guest":
        return {"authenticated": False, "user": None, "sponsorships": []}

    sponsorships = list_sponsorships_for_user(user)
    for item in sponsorships:
        sub = item.get("subscription") or {}
        item["plan"] = item.get("plan") or (sub.get("plan") if isinstance(sub, dict) else None)
        item["monthly_amount"] = flt(
            item.get("monthly_amount")
            or (sub.get("monthly_fee") if isinstance(sub, dict) else 0)
        )
        item["next_payment_date"] = item.get("next_payment_date") or (
            sub.get("next_billing_date") if isinstance(sub, dict) else None
        )
        item["status"] = item.get("status") or item.get("link_status")
        item["can_pay_for_care"] = bool(
            item.get("can_pay_for_care")
            or (item.get("permissions") or {}).get("can_pay_for_care")
            or (item.get("permissions") or {}).get("view_subscription")
        )

    return {
        "authenticated": True,
        "user": {
            "name": user,
            "full_name": frappe.db.get_value("User", user, "full_name") or user,
            "mobile": frappe.db.get_value("User", user, "mobile_no"),
        },
        "sponsorships": sponsorships,
        "csrf_token": frappe.sessions.get_csrf_token(),
    }


def portal_payment_methods():
    _require_logged_in()
    from hiraal_emr.api import _as_admin, _mobile_payments_pos

    pos = _mobile_payments_pos()
    if not pos:
        return {"enabled": False, "methods": []}
    try:
        return _as_admin(pos.get_mobile_payment_methods)
    except Exception:
        frappe.logger("hiraal_portal").exception("portal payment methods failed")
        return {"enabled": False, "methods": []}


def portal_plans():
    _require_logged_in()
    from hiraal_emr.services.subscription_catalog import subscription_plans_catalog

    return {"success": True, "plans": subscription_plans_catalog()}


def portal_patient_bundle(patient: str):
    """Permission-gated snapshot used by the web portal person view."""
    _require_logged_in()
    user = frappe.session.user
    link = frappe.db.get_value(
        "Family Member",
        {
            "patient": patient,
            "caregiver_user": user,
            "link_status": ["in", ["Pending", "Accepted", "Active"]],
        },
        [
            "name",
            "patient_name",
            "link_status",
            "relationship",
            "can_view_vitals",
            "can_view_appointments",
            "can_view_medications",
            "can_pay_for_care",
        ],
        as_dict=True,
    )
    if not link:
        frappe.throw(_("Not permitted"), frappe.PermissionError)

    from hiraal_emr.api import _safe_get_all
    from hiraal_emr.services.caregiver_service import sponsorship_dashboard

    dashboard = sponsorship_dashboard(link.name, user)
    readings = []
    appointments = []
    orders = []
    if link.link_status in ("Accepted", "Active"):
        if link.can_view_vitals:
            readings = _safe_get_all(
                "Daily Reading",
                filters={"patient": patient},
                fields=["reading_date", "bp_systolic", "bp_diastolic", "blood_sugar", "weight", "risk_level"],
                order_by="reading_date desc",
                limit_page_length=14,
            )
        if link.can_view_appointments:
            appointments = _safe_get_all(
                "Patient Appointment",
                filters={"patient": patient},
                fields=["name", "appointment_date", "appointment_time", "practitioner_name", "status"],
                order_by="appointment_date desc",
                limit_page_length=10,
            )
        if link.can_view_medications:
            orders = _safe_get_all(
                "Medicine Request",
                filters={"patient": patient},
                fields=["name", "status", "modified", "total_amount"],
                order_by="modified desc",
                limit_page_length=10,
            )

    return {
        "success": True,
        "link": link,
        "dashboard": dashboard,
        "readings": readings,
        "appointments": appointments,
        "orders": orders,
        "now": str(now_datetime()),
    }
