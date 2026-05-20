"""Subscription Report — Active plans, status distribution, and revenue per plan."""

import frappe


def execute(filters=None):
    columns = [
        {"label": "Subscription", "fieldname": "name", "fieldtype": "Link", "options": "Care Subscription", "width": 140},
        {"label": "Patient", "fieldname": "patient_name", "fieldtype": "Data", "width": 160},
        {"label": "Plan", "fieldname": "plan", "fieldtype": "Data", "width": 120},
        {"label": "Monthly Fee", "fieldname": "monthly_fee", "fieldtype": "Currency", "width": 100},
        {"label": "Status", "fieldname": "status", "fieldtype": "Data", "width": 100},
        {"label": "Payment Method", "fieldname": "payment_method", "fieldtype": "Data", "width": 110},
        {"label": "Next Billing", "fieldname": "next_billing_date", "fieldtype": "Date", "width": 100},
        {"label": "Total Collected", "fieldname": "total_collected", "fieldtype": "Currency", "width": 110},
    ]

    f = {}
    if filters and filters.get("status"):
        f["status"] = filters["status"]
    if filters and filters.get("plan"):
        f["plan"] = filters["plan"]

    data = frappe.get_all(
        "Care Subscription",
        filters=f,
        fields=["name", "patient_name", "plan", "monthly_fee", "status", "payment_method", "next_billing_date", "total_collected"],
        order_by="status asc, patient_name asc",
        limit=500,
    )

    return columns, data
