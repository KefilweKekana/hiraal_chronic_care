"""Caregiver / sponsor linking, invitations, permissions, and sponsored care."""

from __future__ import annotations

import json
import re
import secrets
import string

import frappe
from frappe import _
from frappe.utils import flt, get_datetime, now_datetime


LINK_FIELDS = [
    "name",
    "patient",
    "patient_name",
    "family_member_name",
    "relationship",
    "phone",
    "email",
    "location",
    "country_code",
    "whatsapp_number",
    "link_status",
    "invite_direction",
    "invite_code",
    "caregiver_user",
    "is_active",
    "can_view_vitals",
    "can_view_appointments",
    "can_view_medications",
    "can_receive_alerts",
    "can_pay_for_care",
    "is_sponsor",
    "sponsor_subscription_active",
    "requested_on",
    "accepted_on",
    "activated_on",
    "creation",
]


def normalize_phone(country_code: str, number: str) -> str:
    cc = re.sub(r"[^\d+]", "", (country_code or "").strip()) or "+252"
    if not cc.startswith("+"):
        cc = f"+{cc.lstrip('+')}"
    digits = re.sub(r"\D", "", number or "")
    if digits.startswith("0"):
        digits = digits[1:]
    cc_digits = cc.lstrip("+")
    if digits.startswith(cc_digits):
        return f"+{digits}"
    return f"{cc}{digits}"


def _invite_code() -> str:
    alphabet = string.ascii_uppercase + string.digits
    for _ in range(20):
        code = "".join(secrets.choice(alphabet) for _ in range(6))
        if not frappe.db.exists("Family Member", {"invite_code": code}):
            return code
    return secrets.token_hex(3).upper()


def _invite_token() -> str:
    return secrets.token_urlsafe(24)


def _serialize_link(row: dict) -> dict:
    out = {k: row.get(k) for k in LINK_FIELDS if k in row}
    out["permissions"] = {
        "can_view_vitals": bool(row.get("can_view_vitals")),
        "can_view_appointments": bool(row.get("can_view_appointments")),
        "can_view_medications": bool(row.get("can_view_medications")),
        "can_receive_alerts": bool(row.get("can_receive_alerts")),
        "can_pay_for_care": bool(row.get("can_pay_for_care")),
        "view_readings": bool(row.get("can_view_vitals")),
        "view_medicines": bool(row.get("can_view_medications")),
        "view_appointments": bool(row.get("can_view_appointments")),
        "view_subscription": bool(row.get("can_pay_for_care")),
    }
    return out


_PERMISSION_ALIASES = {
    "view_readings": "can_view_vitals",
    "view_medicines": "can_view_medications",
    "view_appointments": "can_view_appointments",
    "view_subscription": "can_pay_for_care",
}


def _parse_permissions(raw) -> dict:
    if isinstance(raw, dict):
        return raw
    if isinstance(raw, str) and raw.strip():
        try:
            return json.loads(raw)
        except Exception:
            pass
    return {}


def _normalize_permissions(raw) -> dict:
    parsed = _parse_permissions(raw)
    out = {}
    for key, value in parsed.items():
        canonical = _PERMISSION_ALIASES.get(key, key)
        if canonical.startswith("can_"):
            out[canonical] = bool(value)
    return out


def _apply_permissions(doc, permissions: dict):
    normalized = _normalize_permissions(permissions)
    for field in (
        "can_view_vitals",
        "can_view_appointments",
        "can_view_medications",
        "can_receive_alerts",
        "can_pay_for_care",
    ):
        if field in normalized:
            doc.set(field, 1 if normalized[field] else 0)


def _patient_by_phone(phone: str):
    normalized = normalize_phone("", phone)
    digits = re.sub(r"\D", "", normalized)
    candidates = {normalized, digits, f"+{digits}"}
    if len(digits) > 9:
        candidates.add(digits[-9:])
    rows = frappe.get_all(
        "Patient",
        filters={"mobile": ["in", list(candidates)]},
        fields=["name", "patient_name", "mobile", "status"],
        limit=1,
    )
    if rows:
        return rows[0]
    rows = frappe.get_all(
        "Patient",
        filters={"name": phone},
        fields=["name", "patient_name", "mobile", "status"],
        limit=1,
    )
    return rows[0] if rows else None


def _user_for_phone(phone: str):
    normalized = normalize_phone("", phone)
    user = frappe.db.get_value("Patient", {"mobile": normalized}, "user_id")
    if user:
        return user
    digits = re.sub(r"\D", "", normalized)
    return frappe.db.get_value("User", {"mobile_no": ["like", f"%{digits[-9:]}%"]}, "name")


def invite_caregiver(patient: str, country_code: str, whatsapp_number: str, relationship: str,
                     family_member_name: str | None = None, permissions=None):
    phone = normalize_phone(country_code, whatsapp_number)
    perms = _normalize_permissions(permissions)
    name = family_member_name or phone
    doc = frappe.new_doc("Family Member")
    doc.patient = patient
    doc.family_member_name = name
    doc.relationship = relationship or "Other"
    doc.country_code = country_code or "+252"
    doc.whatsapp_number = whatsapp_number
    doc.phone = phone
    doc.invite_direction = "Patient Invited"
    doc.link_status = "Pending"
    doc.invite_token = _invite_token()
    doc.invite_code = _invite_code()
    doc.is_active = 1
    doc.is_sponsor = 1 if perms.get("can_pay_for_care") else 0
    _apply_permissions(doc, {
        "can_view_vitals": perms.get("can_view_vitals", True),
        "can_view_appointments": perms.get("can_view_appointments", True),
        "can_view_medications": perms.get("can_view_medications", True),
        "can_receive_alerts": perms.get("can_receive_alerts", True),
        "can_pay_for_care": perms.get("can_pay_for_care", False),
    })
    doc.requested_on = now_datetime()
    doc.caregiver_user = _user_for_phone(phone)
    doc.insert(ignore_permissions=True)
    return doc


def request_sponsor_connection(country_code: str, whatsapp_number: str, relationship: str,
                             sponsor_name: str | None = None):
    phone = normalize_phone(country_code, whatsapp_number)
    patient_row = _patient_by_phone(phone)
    if not patient_row:
        frappe.throw(_("No patient found with that WhatsApp number"))
    sponsor_user = frappe.session.user
    sponsor_patient = frappe.db.get_value("Patient", {"user_id": sponsor_user}, "name")
    sponsor_display = sponsor_name or frappe.db.get_value("User", sponsor_user, "full_name") or sponsor_user
    existing = frappe.db.get_value(
        "Family Member",
        {"patient": patient_row.name, "caregiver_user": sponsor_user,
         "link_status": ["in", ["Pending", "Accepted", "Active"]]},
        "name",
    )
    if existing:
        frappe.throw(_("You already have a pending or active connection with this patient"))

    doc = frappe.new_doc("Family Member")
    doc.patient = patient_row.name
    doc.family_member_name = sponsor_display
    doc.relationship = relationship or "Other"
    doc.country_code = country_code or "+252"
    doc.whatsapp_number = whatsapp_number
    doc.phone = phone if sponsor_patient else frappe.db.get_value("User", sponsor_user, "mobile_no")
    doc.invite_direction = "Sponsor Requested"
    doc.link_status = "Pending"
    doc.invite_token = _invite_token()
    doc.invite_code = _invite_code()
    doc.is_active = 1
    doc.is_sponsor = 1
    doc.can_pay_for_care = 1
    doc.can_view_vitals = 0
    doc.can_view_appointments = 0
    doc.can_view_medications = 0
    doc.can_receive_alerts = 1
    doc.requested_on = now_datetime()
    doc.caregiver_user = sponsor_user
    doc.insert(ignore_permissions=True)
    return doc, patient_row


def find_patient_for_sponsor(query: str):
    query = (query or "").strip()
    if not query:
        frappe.throw(_("Enter a phone number or member ID"))
    row = _patient_by_phone(query)
    if not row:
        row = frappe.db.get_value(
            "Patient", query,
            ["name", "patient_name", "mobile", "status"],
            as_dict=True,
        )
    if not row:
        return None
    plan = frappe.db.get_value(
        "Care Subscription",
        {"patient": row.name, "status": ["in", ["Active", "Overdue", "Past Due", "Expiring Soon"]]},
        ["plan", "monthly_fee", "status"],
        as_dict=True,
    )
    return {
        "patient": row.name,
        "patient_name": row.patient_name,
        "mobile": row.mobile,
        "member_id": row.name,
        "status": row.status,
        "care_plan": plan.plan if plan else None,
        "monthly_fee": flt(plan.monthly_fee) if plan else 0,
        "subscription_status": plan.status if plan else None,
    }


def redeem_invitation_code(code: str, user: str | None = None):
    code = (code or "").strip().upper()
    if not code:
        frappe.throw(_("Enter an invitation code"))
    name = frappe.db.get_value("Family Member", {"invite_code": code, "link_status": "Pending"}, "name")
    if not name:
        frappe.throw(_("Invalid or expired invitation code"))
    doc = frappe.get_doc("Family Member", name)
    doc.caregiver_user = user or frappe.session.user
    doc.link_status = "Accepted"
    doc.accepted_on = now_datetime()
    if doc.can_pay_for_care:
        doc.is_sponsor = 1
    doc.save(ignore_permissions=True)
    return doc


def list_caregivers_for_patient(patient: str, include_inactive=False):
    filters = {"patient": patient}
    if not include_inactive:
        filters["link_status"] = ["in", ["Pending", "Accepted", "Active"]]
    rows = frappe.get_all("Family Member", filters=filters, fields=LINK_FIELDS, order_by="creation desc")
    return [_serialize_link(r) for r in rows]


def list_pending_for_patient(patient: str):
    rows = frappe.get_all(
        "Family Member",
        filters={"patient": patient, "link_status": "Pending"},
        fields=LINK_FIELDS,
        order_by="creation desc",
    )
    return [_serialize_link(r) for r in rows]


def list_sponsorships_for_user(user: str):
    rows = frappe.get_all(
        "Family Member",
        filters={
            "caregiver_user": user,
            "link_status": ["in", ["Pending", "Accepted", "Active"]],
        },
        fields=LINK_FIELDS,
        order_by="creation desc",
    )
    out = []
    for r in rows:
        item = _serialize_link(r)
        sub = frappe.db.get_value(
            "Care Subscription",
            {"patient": r.patient, "status": ["in", ["Active", "Overdue", "Past Due", "Expiring Soon"]]},
            ["name", "plan", "monthly_fee", "status", "next_billing_date"],
            as_dict=True,
        )
        item["subscription"] = sub
        out.append(item)
    return out


def respond_to_request(link_name: str, action: str, patient: str | None = None):
    doc = frappe.get_doc("Family Member", link_name)
    if patient and doc.patient != patient:
        frappe.throw(_("Not permitted"), frappe.PermissionError)
    action = (action or "").strip().lower()
    if action == "accept":
        doc.link_status = "Accepted" if not doc.can_pay_for_care else "Active"
        doc.accepted_on = now_datetime()
        if doc.link_status == "Active":
            doc.activated_on = now_datetime()
    elif action == "reject":
        doc.link_status = "Cancelled"
        doc.is_active = 0
    else:
        frappe.throw(_("Unknown action"))
    doc.save(ignore_permissions=True)
    return doc


def update_permissions(link_name: str, patient: str, permissions: dict):
    doc = frappe.get_doc("Family Member", link_name)
    if doc.patient != patient:
        frappe.throw(_("Not permitted"), frappe.PermissionError)
    _apply_permissions(doc, permissions)
    normalized = _normalize_permissions(permissions)
    if normalized.get("can_pay_for_care"):
        doc.is_sponsor = 1
    doc.save(ignore_permissions=True)
    return doc


def revoke_link(link_name: str, patient: str | None = None):
    doc = frappe.get_doc("Family Member", link_name)
    if patient and doc.patient != patient:
        frappe.throw(_("Not permitted"), frappe.PermissionError)
    doc.link_status = "Inactive"
    doc.is_active = 0
    doc.save(ignore_permissions=True)
    return doc


def whatsapp_invite_url(link_name: str) -> str:
    doc = frappe.get_doc("Family Member", link_name)
    site = frappe.utils.get_url()
    link = f"{site}/caregiver-invite?code={doc.invite_code}"
    message = (
        f"You have been invited to join Hiraal Life Care as a caregiver for "
        f"{doc.patient_name}. Open: {link}  Code: {doc.invite_code}"
    )
    phone_digits = re.sub(r"\D", "", doc.phone or "")
    from urllib.parse import quote
    return f"https://wa.me/{phone_digits}?text={quote(message)}"


def sponsorship_dashboard(link_name: str, user: str):
    doc = frappe.get_doc("Family Member", link_name)
    if doc.caregiver_user != user or doc.link_status not in ("Accepted", "Active"):
        frappe.throw(_("Not permitted"), frappe.PermissionError)
    patient = doc.patient
    updates = []
    if doc.can_view_medications:
        orders = frappe.get_all(
            "Medicine Request",
            filters={"patient": patient, "status": ["in", ["Delivered", "Out for Delivery"]]},
            fields=["name", "status", "modified"],
            order_by="modified desc",
            limit=3,
        )
        for o in orders:
            updates.append({
                "type": "delivery",
                "title": "Medicine delivered" if o.status == "Delivered" else "Out for delivery",
                "date": o.modified,
                "reference": o.name,
            })
    if doc.can_view_appointments:
        appts = frappe.get_all(
            "Patient Appointment",
            filters={"patient": patient, "status": ["!=", "Cancelled"]},
            fields=["name", "appointment_date", "appointment_time", "practitioner_name"],
            order_by="appointment_date desc",
            limit=2,
        )
        for a in appts:
            updates.append({
                "type": "appointment",
                "title": f"Visit with {a.practitioner_name or 'care team'}",
                "date": f"{a.appointment_date} {a.appointment_time or ''}".strip(),
                "reference": a.name,
            })
    sub = frappe.db.get_value(
        "Care Subscription",
        {"patient": patient},
        ["name", "plan", "monthly_fee", "status", "next_billing_date"],
        as_dict=True,
    )
    return {
        "link": _serialize_link(doc.as_dict()),
        "patient_name": doc.patient_name,
        "updates": updates,
        "subscription": sub,
    }


def caregiver_can_access(link_name: str, user: str, permission: str) -> bool:
    doc = frappe.get_doc("Family Member", link_name)
    if doc.caregiver_user != user or doc.link_status not in ("Accepted", "Active"):
        return False
    return bool(doc.get(permission))


def notify_sponsors_of_alert(patient: str, alert_type: str, message: str):
    """Push in-app notifications to linked caregivers who may receive alerts."""
    rows = frappe.get_all(
        "Family Member",
        filters={
            "patient": patient,
            "link_status": ["in", ["Accepted", "Active"]],
            "can_receive_alerts": 1,
            "caregiver_user": ["is", "set"],
        },
        fields=["name", "caregiver_user", "family_member_name"],
    )
    for row in rows:
        try:
            if frappe.db.exists("DocType", "Notification Log"):
                n = frappe.new_doc("Notification Log")
                n.for_user = row.caregiver_user
                n.subject = f"Alert for {patient}: {alert_type}"
                n.email_content = message
                n.document_type = "Family Member"
                n.document_name = row.name
                n.insert(ignore_permissions=True)
        except Exception:
            frappe.logger("hiraal_caregiver").exception(
                "sponsor alert notify failed link=%s", row.name
            )


def activate_sponsored_care(link_name: str):
    doc = frappe.get_doc("Family Member", link_name)
    doc.link_status = "Active"
    doc.sponsor_subscription_active = 1
    doc.activated_on = now_datetime()
    doc.is_sponsor = 1
    doc.save(ignore_permissions=True)
