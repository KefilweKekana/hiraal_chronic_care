import frappe
from frappe.model.document import Document


class AuditLog(Document):
    pass


def log_action(doc, method=None, docname_ref=None, description=None):
    """Doc event hook wrapper to create an audit log entry.
    
    Can also be called directly as log_action(action, doctype_ref, docname_ref, description).
    """
    # Detect if called as doc event hook (doc is a Document instance)
    if isinstance(doc, Document) and method:
        action_map = {
            "after_insert": "Create",
            "on_update": "Update",
            "on_submit": "Update",
            "on_cancel": "Update",
            "on_trash": "Delete",
        }
        action = action_map.get(method, "Update")
        doctype_ref = doc.doctype
        docname_ref = doc.name
        description = description or f"{action} {doc.doctype} {doc.name}"
    else:
        # Direct call: doc is action string
        action = doc
        doctype_ref = method
        docname_ref = docname_ref
        description = description

    try:
        settings = frappe.get_single("Chronic Care Settings")
        if not settings.enable_audit_log:
            return
    except Exception:
        return

    log = frappe.new_doc("Audit Log")
    log.user = frappe.session.user
    log.action = action
    log.doctype_ref = doctype_ref
    log.docname_ref = docname_ref
    log.description = description
    log.ip_address = frappe.local.request_ip if hasattr(frappe.local, "request_ip") else None
    log.insert(ignore_permissions=True)
