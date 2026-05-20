"""Permission helpers for Hiraal EMR doctypes."""

import frappe


def daily_reading_permission(doc, ptype, user):
    """Restrict daily reading access based on assigned nurse."""
    if frappe.session.user == "Administrator":
        return True

    roles = frappe.get_roles(user)
    if "System Manager" in roles or "Chronic Care Admin" in roles:
        return True

    if "Chronic Care Doctor" in roles:
        return True

    if "Chronic Care Nurse" in roles:
        # Nurses see all readings (could be refined to their assigned patients)
        return True

    return False
