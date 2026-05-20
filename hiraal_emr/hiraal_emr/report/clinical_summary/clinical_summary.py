"""Clinical Summary Report — Alert distribution, resolution times, and care metrics."""

import frappe
from frappe.utils import add_days, getdate, today


def execute(filters=None):
    columns = [
        {"label": "Alert", "fieldname": "name", "fieldtype": "Link", "options": "Chronic Care Alert", "width": 140},
        {"label": "Patient", "fieldname": "patient_name", "fieldtype": "Data", "width": 160},
        {"label": "Level", "fieldname": "alert_level", "fieldtype": "Data", "width": 90},
        {"label": "Type", "fieldname": "alert_type", "fieldtype": "Data", "width": 130},
        {"label": "Status", "fieldname": "status", "fieldtype": "Data", "width": 90},
        {"label": "BP", "fieldname": "bp_display", "fieldtype": "Data", "width": 90},
        {"label": "Sugar", "fieldname": "blood_sugar", "fieldtype": "Float", "width": 80},
        {"label": "Assigned Nurse", "fieldname": "assigned_nurse_name", "fieldtype": "Data", "width": 140},
        {"label": "Created", "fieldname": "creation", "fieldtype": "Datetime", "width": 150},
    ]

    f = {}
    if filters and filters.get("from_date"):
        f["creation"] = [">=", filters["from_date"]]
    if filters and filters.get("alert_level"):
        f["alert_level"] = filters["alert_level"]
    if filters and filters.get("status"):
        f["status"] = filters["status"]

    alerts = frappe.get_all(
        "Chronic Care Alert",
        filters=f,
        fields=[
            "name", "patient_name", "alert_level", "alert_type", "status",
            "bp_systolic", "bp_diastolic", "blood_sugar",
            "assigned_nurse_name", "creation",
        ],
        order_by="creation desc",
        limit=500,
    )

    for a in alerts:
        a["bp_display"] = f"{a.bp_systolic}/{a.bp_diastolic}" if a.bp_systolic else ""

    return columns, alerts
