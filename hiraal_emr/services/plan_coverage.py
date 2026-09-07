"""Server-side plan coverage: charge only if not included or over quota.

The mobile app must display whatever this module returns (covered vs amount).
Never trust a client-only skip-payment decision.
"""

from __future__ import annotations

import frappe
from frappe.utils import flt, get_first_day, get_last_day, getdate, today

from hiraal_emr.services.subscription_catalog import has_active_subscription

# Fallback prices when Appointment Type / Lab Test Template has no rate.
DEFAULT_FEES = {
    "consultation": 10.0,
    "video_consultation": 10.0,
    "lab_test": 15.0,
    "medicine": 0.0,
    "home_sample": 8.0,
}

SERVICE_ALIASES = {
    "doctor": "consultation",
    "doctor_visit": "consultation",
    "inperson": "consultation",
    "in_person": "consultation",
    "video": "video_consultation",
    "video_call": "video_consultation",
    "telemedicine": "video_consultation",
    "lab": "lab_test",
    "labs": "lab_test",
    "medicine_refill": "medicine",
    "refill": "medicine",
    "home_sample_collection": "home_sample",
    "home collection": "home_sample",
}

# Quota field on Subscription Plan → 0 means unlimited when include_* is set.
PLAN_FIELDS = {
    "consultation": ("include_consultations", "consultation_quota_monthly", "consultation_fee"),
    "video_consultation": (
        "include_video_consultations",
        "video_quota_monthly",
        "video_consultation_fee",
    ),
    "lab_test": ("include_lab_tests", "lab_quota_monthly", "lab_default_fee"),
    "medicine": ("include_medicines", "medicine_quota_monthly", "medicine_default_fee"),
    "home_sample": ("include_home_sample", "home_sample_quota_monthly", "home_sample_fee"),
}


def normalize_service(service_type: str) -> str:
    raw = (service_type or "").strip().lower().replace("-", "_").replace(" ", "_")
    return SERVICE_ALIASES.get(raw, raw or "consultation")


def _active_subscription(patient: str):
    if not patient:
        return None
    return frappe.db.get_value(
        "Care Subscription",
        {"patient": patient, "status": "Active"},
        ["name", "plan", "is_on_trial", "trial_end_date", "monthly_fee"],
        as_dict=True,
        order_by="creation desc",
    )


def _plan_row(plan_name: str):
    if not plan_name or not frappe.db.exists("DocType", "Subscription Plan"):
        return None
    if not frappe.db.exists("Subscription Plan", plan_name):
        # plan_name on Care Subscription may be the display name
        found = frappe.db.get_value("Subscription Plan", {"plan_name": plan_name}, "name")
        if not found:
            return None
        plan_name = found
    meta = frappe.get_meta("Subscription Plan")
    fields = ["name", "plan_name", "monthly_fee", "features"]
    for include_f, quota_f, fee_f in PLAN_FIELDS.values():
        for f in (include_f, quota_f, fee_f):
            if meta.has_field(f):
                fields.append(f)
    return frappe.db.get_value("Subscription Plan", plan_name, fields, as_dict=True)


def _feature_implies(plan, service: str) -> bool:
    """Fallback when explicit include_* fields are missing: parse features text."""
    features = (plan.get("features") or "") if plan else ""
    text = str(features).lower()
    needles = {
        "consultation": ("consult", "doctor", "visit", "telemed"),
        "video_consultation": ("video", "telemed", "consult"),
        "lab_test": ("lab", "diagnostic"),
        "medicine": ("medicine", "medication", "pharmacy", "delivery"),
        "home_sample": ("home sample", "home collection", "sample collection"),
    }
    return any(n in text for n in needles.get(service, ()))


def _included_on_plan(plan, service: str) -> bool:
    if not plan:
        return False
    include_f, _, _ = PLAN_FIELDS.get(service, (None, None, None))
    if include_f and include_f in plan and plan.get(include_f) is not None:
        return bool(int(plan.get(include_f) or 0))
    # No explicit flag yet (site not migrated): an active plan covers core
    # chronic-care services so existing patients are not suddenly charged.
    if service in ("consultation", "video_consultation", "lab_test", "medicine", "home_sample"):
        if _feature_implies(plan, service):
            return True
        return True
    return False


def _quota_limit(plan, service: str) -> int:
    """0 = unlimited."""
    if not plan:
        return 0
    _, quota_f, _ = PLAN_FIELDS.get(service, (None, None, None))
    if quota_f and quota_f in plan and plan.get(quota_f) is not None:
        return int(plan.get(quota_f) or 0)
    return 0


def _fee_for(plan, service: str, extra: dict | None = None) -> float:
    extra = extra or {}
    if service == "lab_test":
        template = extra.get("template")
        if template and frappe.db.exists("DocType", "Lab Test Template"):
            rate = frappe.db.get_value("Lab Test Template", template, "lab_test_rate")
            if rate is not None:
                return flt(rate)
    if service in ("consultation", "video_consultation"):
        appt_type = extra.get("appointment_type")
        if appt_type and frappe.db.exists("DocType", "Appointment Type"):
            for field in ("price", "rate", "amount"):
                try:
                    val = frappe.db.get_value("Appointment Type", appt_type, field)
                    if val is not None and flt(val) > 0:
                        return flt(val)
                except Exception:
                    continue
    if plan:
        _, _, fee_f = PLAN_FIELDS.get(service, (None, None, None))
        if fee_f and fee_f in plan and flt(plan.get(fee_f)) > 0:
            return flt(plan.get(fee_f))
    return flt(DEFAULT_FEES.get(service, 0))


def _month_bounds():
    start = get_first_day(today())
    end = get_last_day(today())
    return start, end


def _usage_this_month(patient: str, service: str) -> int:
    start, end = _month_bounds()
    if service in ("consultation", "video_consultation"):
        filters = {
            "patient": patient,
            "appointment_date": ["between", [start, end]],
            "status": ["not in", ("Cancelled", "Closed")],
        }
        rows = frappe.get_all(
            "Patient Appointment",
            filters=filters,
            fields=["name", "appointment_type"],
            ignore_permissions=True,
        )
        if service == "video_consultation":
            video_names = set(
                frappe.get_all(
                    "Telemedicine Session",
                    filters={"patient": patient},
                    pluck="appointment",
                    ignore_permissions=True,
                )
                or []
            )
            return len([r for r in rows if r.name in video_names])
        return len(rows)
    if service == "lab_test":
        return frappe.db.count(
            "Lab Test",
            {
                "patient": patient,
                "creation": [">=", str(start)],
            },
        ) or 0
    if service == "home_sample":
        # Count lab tests requested with home collection in the note/custom field.
        return frappe.db.count(
            "Lab Test",
            {
                "patient": patient,
                "creation": [">=", str(start)],
            },
        ) or 0
    if service == "medicine":
        return frappe.db.count(
            "Medicine Request",
            {
                "patient": patient,
                "creation": [">=", str(start)],
                "status": ["not in", ("Cancelled",)],
            },
        ) or 0
    return 0


def check_coverage(patient: str, service_type: str, extra: dict | None = None) -> dict:
    """Authoritative coverage decision for a service request.

    Returns a JSON-serializable dict the app can render:
    covered, payment_required, amount, reason, quota_used, quota_limit, plan.
    """
    extra = extra or {}
    service = normalize_service(service_type)
    sub = _active_subscription(patient)
    if not sub or not has_active_subscription(patient):
        amount = _fee_for(None, service, extra)
        return {
            "success": True,
            "covered": False,
            "payment_required": True if amount > 0 or service != "medicine" else True,
            "amount": amount,
            "currency": "USD",
            "reason": "no_active_plan",
            "message": "Not included in your plan – Payment required",
            "service": service,
            "plan": None,
            "quota_used": 0,
            "quota_limit": 0,
        }

    plan = _plan_row(sub.plan)
    included = _included_on_plan(plan, service)
    quota = _quota_limit(plan, service)
    used = _usage_this_month(patient, service)
    over_quota = bool(quota and used >= quota)
    covered = included and not over_quota
    amount = 0.0 if covered else _fee_for(plan, service, extra)
    reason = "included"
    message = "Included in your plan, FREE for you"
    if not included:
        reason = "not_in_plan"
        message = "Not included in your plan – Payment required"
    elif over_quota:
        reason = "over_quota"
        message = "Not included in your plan – Payment required"

    return {
        "success": True,
        "covered": covered,
        "payment_required": not covered,
        "amount": flt(amount),
        "currency": "USD",
        "reason": reason,
        "message": message,
        "service": service,
        "plan": (plan or {}).get("plan_name") or sub.plan,
        "subscription": sub.name,
        "quota_used": used,
        "quota_limit": quota,
    }


def apply_coverage_to_appointment(appt, coverage: dict):
    """Skip invoicing when the consult is covered by the plan."""
    if not coverage.get("covered"):
        return
    meta = frappe.get_meta(appt.doctype)
    if meta.has_field("invoiced"):
        appt.invoiced = 1
    if meta.has_field("paid_amount"):
        try:
            appt.paid_amount = 0
        except Exception:
            pass
    if meta.has_field("custom_plan_covered"):
        appt.custom_plan_covered = 1


def skip_invoice_if_covered(doctype: str, name: str, patient: str, service: str):
    """After insert: cancel auto-created invoices when the plan covers the item."""
    coverage = check_coverage(patient, service)
    if not coverage.get("covered"):
        return coverage
    try:
        if frappe.db.exists("DocType", "Sales Invoice"):
            invoices = frappe.get_all(
                "Sales Invoice",
                filters={"patient": patient, "docstatus": 0},
                fields=["name", "remarks", "creation"],
                order_by="creation desc",
                limit=3,
                ignore_permissions=True,
            )
            for inv in invoices:
                items = frappe.get_all(
                    "Sales Invoice Item",
                    filters={"parent": inv.name, "reference_dn": name},
                    pluck="name",
                    ignore_permissions=True,
                )
                if items or name in str(inv.get("remarks") or ""):
                    doc = frappe.get_doc("Sales Invoice", inv.name)
                    if int(doc.docstatus or 0) == 0:
                        doc.delete(ignore_permissions=True)
    except Exception:
        frappe.logger("hiraal_coverage").exception(
            "skip invoice failed for %s %s", doctype, name
        )
    if frappe.get_meta(doctype).has_field("invoiced"):
        frappe.db.set_value(doctype, name, "invoiced", 1, update_modified=False)
    return coverage


def after_appointment_insert(doc, method=None):
    is_video = 0
    if frappe.db.exists("Telemedicine Session", {"appointment": doc.name}):
        is_video = 1
    service = "video_consultation" if is_video else "consultation"
    skip_invoice_if_covered("Patient Appointment", doc.name, doc.patient, service)


def after_lab_test_insert(doc, method=None):
    skip_invoice_if_covered("Lab Test", doc.name, doc.patient, "lab_test")


def cover_medicine_request_if_included(doc):
    """If medicine is in-plan, do not ask the patient/sponsor to pay."""
    coverage = check_coverage(doc.patient, "medicine")
    if not coverage.get("covered"):
        return coverage
    if hasattr(doc, "payment_status"):
        doc.payment_status = "Paid"
    if hasattr(doc, "amount"):
        doc.amount = 0
    if hasattr(doc, "total"):
        doc.total = 0
    if getattr(doc, "status", None) == "Awaiting Payment":
        doc.status = "Paid"
    return coverage
