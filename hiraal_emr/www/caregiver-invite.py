import frappe


def get_context(context):
    code = (frappe.form_dict.get("code") or "").strip().upper()
    context.no_cache = 1
    context.code = code
    context.invite = None
    context.error = None

    if not code:
        context.error = "Missing invitation code."
        return context

    row = frappe.db.get_value(
        "Family Member",
        {"invite_code": code},
        [
            "name",
            "patient_name",
            "family_member_name",
            "relationship",
            "link_status",
            "invite_direction",
            "can_pay_for_care",
        ],
        as_dict=True,
    )
    if not row:
        context.error = "This invitation code is invalid or has expired."
        return context

    context.invite = row
    context.is_sponsor = bool(row.can_pay_for_care)
    context.is_pending = row.link_status == "Pending"
    return context
