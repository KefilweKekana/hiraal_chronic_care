from frappe import _


def get_data():
    return {
        "heatmap": True,
        "heatmap_message": _("Patient readings and alert activity"),
        "fieldname": "creation",
        "transactions": [
            {
                "label": _("Clinical"),
                "items": [
                    "Chronic Care Alert",
                    "Daily Reading",
                    "Nurse Task",
                    "Doctor Review",
                ],
            },
            {
                "label": _("Services"),
                "items": [
                    "Patient Appointment",
                    "Lab Test",
                    "Patient Device",
                ],
            },
            {
                "label": _("Billing"),
                "items": [
                    "Subscription Plan",
                    "Care Subscription",
                    "Subscription Payment",
                ],
            },
            {
                "label": _("Settings"),
                "items": [
                    "Care Station",
                    "Chronic Care Settings",
                ],
            },
        ],
    }
