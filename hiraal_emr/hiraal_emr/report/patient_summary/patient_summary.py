"""Patient Summary Report — Comprehensive patient overview with risk, readings, and subscription status."""

import frappe
from frappe.utils import add_days, getdate, today


def execute(filters=None):
    columns = get_columns()
    data = get_data(filters)
    return columns, data


def get_columns():
    return [
        {"label": "Patient ID", "fieldname": "name", "fieldtype": "Link", "options": "Patient", "width": 120},
        {"label": "Patient Name", "fieldname": "patient_name", "fieldtype": "Data", "width": 180},
        {"label": "Sex", "fieldname": "sex", "fieldtype": "Data", "width": 60},
        {"label": "Mobile", "fieldname": "mobile", "fieldtype": "Data", "width": 120},
        {"label": "Risk Level", "fieldname": "risk_level", "fieldtype": "Data", "width": 100},
        {"label": "Last BP", "fieldname": "last_bp", "fieldtype": "Data", "width": 90},
        {"label": "Last Sugar", "fieldname": "last_sugar", "fieldtype": "Float", "width": 90},
        {"label": "Readings (7d)", "fieldname": "readings_7d", "fieldtype": "Int", "width": 90},
        {"label": "Med Adherence %", "fieldname": "adherence", "fieldtype": "Percent", "width": 110},
        {"label": "Subscription", "fieldname": "subscription", "fieldtype": "Data", "width": 120},
        {"label": "Active Alerts", "fieldname": "alerts", "fieldtype": "Int", "width": 90},
    ]


def get_data(filters):
    patients = frappe.get_all(
        "Patient",
        filters={"status": "Active"},
        fields=["name", "patient_name", "sex", "mobile"],
        order_by="patient_name asc",
        limit=500,
    )

    seven_days_ago = add_days(getdate(today()), -7)
    data = []

    for p in patients:
        # Risk
        alert_level = frappe.db.get_value(
            "Chronic Care Alert",
            {"patient": p.name, "status": "Open"},
            "alert_level",
            order_by="creation desc",
        ) or "Normal"

        # Last reading
        lr = frappe.db.get_value(
            "Daily Reading", {"patient": p.name},
            ["bp_systolic", "bp_diastolic", "blood_sugar"],
            order_by="reading_date desc", as_dict=True,
        )
        last_bp = f"{lr.bp_systolic}/{lr.bp_diastolic}" if lr and lr.bp_systolic else ""
        last_sugar = lr.blood_sugar if lr else None

        # 7-day readings count + adherence
        readings_7d = frappe.db.count(
            "Daily Reading", {"patient": p.name, "reading_date": [">=", seven_days_ago]}
        ) or 0
        med_taken = frappe.db.count(
            "Daily Reading", {"patient": p.name, "reading_date": [">=", seven_days_ago], "medicine_taken": 1}
        ) or 0
        adherence = round((med_taken / max(readings_7d, 1)) * 100)

        # Subscription
        sub = frappe.db.get_value(
            "Care Subscription", {"patient": p.name, "status": ["!=", "Cancelled"]},
            ["plan", "status"], as_dict=True,
        )
        subscription = f"{sub.plan} ({sub.status})" if sub else "None"

        # Active alerts
        alerts = frappe.db.count("Chronic Care Alert", {"patient": p.name, "status": "Open"}) or 0

        data.append({
            "name": p.name,
            "patient_name": p.patient_name,
            "sex": p.sex,
            "mobile": p.mobile,
            "risk_level": alert_level,
            "last_bp": last_bp,
            "last_sugar": last_sugar,
            "readings_7d": readings_7d,
            "adherence": adherence,
            "subscription": subscription,
            "alerts": alerts,
        })

    return data
