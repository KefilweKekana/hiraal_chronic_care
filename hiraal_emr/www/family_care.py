import frappe


def get_context(context):
    context.no_cache = 1
    context.no_breadcrumbs = 1
    context.show_sidebar = 0
    context.no_header = 1
    context.full_width = 1
    context.invite_code = (frappe.form_dict.get("code") or "").strip().upper()
    context.csrf_token = frappe.sessions.get_csrf_token()
    context.session_user = frappe.session.user if frappe.session.user != "Guest" else ""
    context.authenticated = bool(context.session_user)
    return context
