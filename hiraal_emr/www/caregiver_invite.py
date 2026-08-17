import frappe

from hiraal_emr.services.security_helpers import client_rate_key, rate_limit


def get_context(context):
    context.no_cache = 1
    context.no_breadcrumbs = 1
    context.show_sidebar = 0
    context.code = ""
    context.invite = None
    context.error = None
    context.is_sponsor = False
    context.is_pending = False

    code = (frappe.form_dict.get("code") or "").strip().upper()
    context.code = code
    if not code:
        context.error = "Missing invitation code."
        return context

    try:
        rate_limit(client_rate_key("invite_page", code), limit=30, window_sec=900)
    except Exception:
        context.error = "Too many attempts. Please try again later."
        return context

    try:
        row = frappe.db.get_value(
            "Family Member",
            {"invite_code": code},
            [
                "name",
                "patient_name",
                "family_member_name",
                "relationship",
                "link_status",
                "can_pay_for_care",
            ],
            as_dict=True,
        )
    except Exception:
        frappe.log_error(frappe.get_traceback(), "Caregiver invite page lookup failed")
        context.error = "Unable to load this invitation right now. Please try again shortly."
        return context

    if not row:
        context.error = "This invitation code is invalid or has expired."
        return context

    if row.get("link_status") != "Pending":
        context.error = "This invitation is no longer active."
        context.invite = None
        return context

    context.invite = row
    context.is_sponsor = bool(row.get("can_pay_for_care"))
    context.is_pending = row.get("link_status") == "Pending"
    return context
