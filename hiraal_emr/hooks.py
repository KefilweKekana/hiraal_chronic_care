app_name = "hiraal_emr"
app_title = "Hiraal EMR"
app_publisher = "Hiraal Health Center"
app_description = "Chronic Disease Management Platform for Somaliland — Alert Queue, Nurse Tasks, Doctor Review, Subscriptions, Device Management, Analytics"
app_email = "info@hiraalhealth.so"
app_license = "MIT"
required_apps = ["frappe", "erpnext", "health"]

# ---------- Website / Portal ----------
# home_page = "clinic-dashboard"

# ---------- Fixtures ----------
fixtures = [
    {"dt": "Role", "filters": [["name", "in", [
        "Chronic Care Nurse",
        "Chronic Care Doctor",
        "Chronic Care Admin",
        "Chronic Care Pharmacist",
        "Chronic Care Lab Tech",
    ]]]},
    {"dt": "Custom Field", "filters": [["module", "=", "Hiraal EMR"]]},
    {"dt": "Property Setter", "filters": [["module", "=", "Hiraal EMR"]]},
]

# ---------- Document Events ----------
doc_events = {
    "Vital Signs": {
        "after_insert": "hiraal_emr.api.on_vital_signs_insert",
    },
    "Patient Appointment": {
        "on_update": "hiraal_emr.api.on_appointment_update",
    },
    "Lab Test": {
        "on_update": "hiraal_emr.api.on_lab_test_update",
    },
    "Daily Reading": {
        "after_insert": "hiraal_emr.doctype.audit_log.audit_log.log_action",
    },
    "Chronic Care Alert": {
        "after_insert": "hiraal_emr.doctype.audit_log.audit_log.log_action",
        "on_update": "hiraal_emr.doctype.audit_log.audit_log.log_action",
    },
    "Doctor Review": {
        "after_insert": "hiraal_emr.doctype.audit_log.audit_log.log_action",
        "on_update": "hiraal_emr.doctype.audit_log.audit_log.log_action",
    },
    "Care Subscription": {
        "after_insert": "hiraal_emr.doctype.audit_log.audit_log.log_action",
        "on_update": "hiraal_emr.doctype.audit_log.audit_log.log_action",
    },
    "Subscription Payment": {
        "after_insert": "hiraal_emr.doctype.audit_log.audit_log.log_action",
        "on_update": "hiraal_emr.doctype.audit_log.audit_log.log_action",
    },
    "Medicine Request": {
        "on_update": "hiraal_emr.api.on_medicine_request_update",
    },
}

# ---------- Scheduled Tasks ----------
scheduler_events = {
    "daily": [
        "hiraal_emr.tasks.generate_missed_reading_alerts",
        "hiraal_emr.tasks.process_subscription_billing",
        "hiraal_emr.tasks.mark_overdue_nurse_tasks",
    ],
    "hourly": [
        "hiraal_emr.tasks.escalate_unresolved_alerts",
        "hiraal_emr.tasks.check_device_connectivity",
    ],
    "weekly": [
        "hiraal_emr.tasks.generate_weekly_summaries",
    ],
}

# ---------- Jinja ----------
# jinja = {"methods": [], "filters": []}

# ---------- Permissions ----------
has_permission = {
    "Daily Reading": "hiraal_emr.permissions.daily_reading_permission",
}

# ---------- Web Include ----------
app_include_css = "/assets/hiraal_emr/css/hiraal_emr.css"
app_include_js = [
    "/assets/hiraal_emr/js/hiraal_emr.js",
    "/assets/hiraal_emr/js/hiraal_sidebar.js",
]

# ---------- Override Whitelisted Methods ----------
override_whitelisted_methods = {}

# ---------- Boot Session ----------
boot_session = "hiraal_emr.api.boot_session"
