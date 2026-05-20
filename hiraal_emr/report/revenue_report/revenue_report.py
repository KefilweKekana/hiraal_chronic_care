"""Revenue Report — Payment transactions, revenue trends, and collection rates."""

import frappe


def execute(filters=None):
    columns = [
        {"label": "Transaction", "fieldname": "name", "fieldtype": "Link", "options": "Subscription Payment", "width": 140},
        {"label": "Patient", "fieldname": "patient_name", "fieldtype": "Data", "width": 160},
        {"label": "Date", "fieldname": "payment_date", "fieldtype": "Date", "width": 100},
        {"label": "Amount ($)", "fieldname": "amount", "fieldtype": "Currency", "width": 100},
        {"label": "Method", "fieldname": "payment_method", "fieldtype": "Data", "width": 100},
        {"label": "Status", "fieldname": "status", "fieldtype": "Data", "width": 90},
        {"label": "Reference", "fieldname": "reference_id", "fieldtype": "Data", "width": 140},
    ]

    f = {}
    if filters and filters.get("from_date"):
        f["payment_date"] = [">=", filters["from_date"]]
    if filters and filters.get("to_date"):
        if "payment_date" in f:
            f["payment_date"] = ["between", [filters["from_date"], filters["to_date"]]]
        else:
            f["payment_date"] = ["<=", filters["to_date"]]
    if filters and filters.get("status"):
        f["status"] = filters["status"]

    data = frappe.get_all(
        "Subscription Payment",
        filters=f,
        fields=["name", "patient_name", "payment_date", "amount", "payment_method", "status", "reference_id"],
        order_by="payment_date desc",
        limit=500,
    )

    return columns, data
