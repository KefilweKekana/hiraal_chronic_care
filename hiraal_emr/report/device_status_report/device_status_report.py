"""Device Status Report — Connectivity, battery, sync tracking across all patient devices."""

import frappe


def execute(filters=None):
    columns = [
        {"label": "Device", "fieldname": "name", "fieldtype": "Link", "options": "Patient Device", "width": 140},
        {"label": "Device Name", "fieldname": "device_name", "fieldtype": "Data", "width": 160},
        {"label": "Type", "fieldname": "device_type", "fieldtype": "Data", "width": 120},
        {"label": "Patient", "fieldname": "patient_name", "fieldtype": "Data", "width": 160},
        {"label": "Status", "fieldname": "status", "fieldtype": "Data", "width": 100},
        {"label": "Battery %", "fieldname": "battery_level", "fieldtype": "Int", "width": 80},
        {"label": "Last Sync", "fieldname": "last_sync", "fieldtype": "Datetime", "width": 150},
        {"label": "Total Syncs", "fieldname": "total_syncs", "fieldtype": "Int", "width": 80},
        {"label": "Failures", "fieldname": "sync_failures", "fieldtype": "Int", "width": 80},
        {"label": "Firmware", "fieldname": "firmware_version", "fieldtype": "Data", "width": 100},
    ]

    f = {}
    if filters and filters.get("status"):
        f["status"] = filters["status"]
    if filters and filters.get("device_type"):
        f["device_type"] = filters["device_type"]

    data = frappe.get_all(
        "Patient Device",
        filters=f,
        fields=[
            "name", "device_name", "device_type", "patient_name",
            "status", "battery_level", "last_sync", "total_syncs",
            "sync_failures", "firmware_version",
        ],
        order_by="status asc, device_name asc",
        limit=500,
    )

    return columns, data
