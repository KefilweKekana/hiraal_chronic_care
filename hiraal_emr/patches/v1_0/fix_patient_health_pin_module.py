import frappe


def execute():
    """PIN storage must not use the Core-registered Patient Health PIN DocType.

    Keep the DocType pointed at Hiraal EMR, and add hidden hash/salt fields
    on Patient that set_health_pin actually writes.
    """
    if frappe.db.exists("DocType", "Patient Health PIN"):
        frappe.db.set_value(
            "DocType",
            "Patient Health PIN",
            {"module": "Hiraal EMR", "custom": 0},
            update_modified=False,
        )
        frappe.clear_cache(doctype="Patient Health PIN")

    from hiraal_emr.services.health_pin_service import _ensure_patient_pin_columns

    _ensure_patient_pin_columns()
    frappe.db.commit()
