import frappe


def execute():
    """Point Patient Health PIN at Hiraal EMR, not Frappe Core.

    A site that created this DocType as custom stored module=Core, so
    insert tried to import frappe.core.doctype.patient_health_pin.
    """
    if not frappe.db.exists("DocType", "Patient Health PIN"):
        return
    frappe.db.set_value(
        "DocType",
        "Patient Health PIN",
        {"module": "Hiraal EMR", "custom": 0},
        update_modified=False,
    )
    frappe.clear_cache(doctype="Patient Health PIN")
