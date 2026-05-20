from frappe import _


def get_data():
    return [
        {
            "label": _("Monitoring"),
            "items": [
                {
                    "type": "page",
                    "name": "clinic-dashboard",
                    "label": _("Clinic Dashboard"),
                    "description": _("Live overview of today's activity"),
                },
                {
                    "type": "page",
                    "name": "alert-queue",
                    "label": _("Alert Queue"),
                    "description": _("Patients needing follow-up"),
                },
                {
                    "type": "page",
                    "name": "patient-management",
                    "label": _("Patient Management"),
                    "description": _("Patient registry with risk stratification"),
                },
                {
                    "type": "page",
                    "name": "daily-readings",
                    "label": _("Daily Readings"),
                    "description": _("All readings consolidated"),
                },
                {
                    "type": "page",
                    "name": "analytics-dashboard",
                    "label": _("Analytics"),
                    "description": _("Insights and reporting"),
                },
            ],
        },
        {
            "label": _("Clinical"),
            "items": [
                {
                    "type": "doctype",
                    "name": "Daily Reading",
                    "label": _("Daily Readings"),
                    "description": _("Patient vitals submissions"),
                },
                {
                    "type": "doctype",
                    "name": "Nurse Task",
                    "label": _("Nurse Tasks"),
                    "description": _("Tasks for follow-up"),
                },
                {
                    "type": "doctype",
                    "name": "Doctor Review",
                    "label": _("Doctor Reviews"),
                    "description": _("Weekly patient reviews"),
                },
                {
                    "type": "doctype",
                    "name": "Chronic Care Alert",
                    "label": _("Alerts"),
                    "description": _("Active health alerts"),
                },
            ],
        },
        {
            "label": _("Pharmacy & Devices"),
            "items": [
                {
                    "type": "doctype",
                    "name": "Medicine Request",
                    "label": _("Medicine Requests"),
                    "description": _("Pharmacy fulfillment workflow"),
                },
                {
                    "type": "doctype",
                    "name": "Patient Device",
                    "label": _("Patient Devices"),
                    "description": _("Connected monitoring devices"),
                },
            ],
        },
        {
            "label": _("Billing"),
            "items": [
                {
                    "type": "doctype",
                    "name": "Care Subscription",
                    "label": _("Subscriptions"),
                    "description": _("Monthly care plans"),
                },
                {
                    "type": "doctype",
                    "name": "Subscription Payment",
                    "label": _("Payments"),
                    "description": _("Transaction records"),
                },
            ],
        },
        {
            "label": _("Settings"),
            "items": [
                {
                    "type": "doctype",
                    "name": "Chronic Care Settings",
                    "label": _("Chronic Care Settings"),
                    "description": _("Module configuration"),
                },
            ],
        },
        {
            "label": _("Reports"),
            "items": [
                {
                    "type": "report",
                    "is_query_report": True,
                    "name": "Patient Summary",
                    "doctype": "Patient",
                    "label": _("Patient Summary"),
                },
                {
                    "type": "report",
                    "is_query_report": True,
                    "name": "Revenue Report",
                    "doctype": "Subscription Payment",
                    "label": _("Revenue Report"),
                },
                {
                    "type": "report",
                    "is_query_report": True,
                    "name": "Subscription Report",
                    "doctype": "Care Subscription",
                    "label": _("Subscription Report"),
                },
                {
                    "type": "report",
                    "is_query_report": True,
                    "name": "Clinical Summary",
                    "doctype": "Chronic Care Alert",
                    "label": _("Clinical Summary"),
                },
                {
                    "type": "report",
                    "is_query_report": True,
                    "name": "Device Status Report",
                    "doctype": "Patient Device",
                    "label": _("Device Status"),
                },
            ],
        },
    ]
