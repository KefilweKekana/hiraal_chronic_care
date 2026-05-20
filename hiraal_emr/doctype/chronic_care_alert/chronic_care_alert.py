import frappe
from frappe import _
from frappe.model.document import Document
from frappe.utils import now_datetime


class ChronicCareAlert(Document):
    def validate(self):
        self.set_latest_reading_display()

    def before_save(self):
        if self.has_value_changed("status"):
            if self.status == "Resolved" and not self.resolved_at:
                self.resolved_at = now_datetime()
            elif self.status == "Escalated" and not self.escalation_time:
                self.escalation_time = now_datetime()

    def after_insert(self):
        self.auto_create_nurse_task()
        self.notify_care_team()

    def set_latest_reading_display(self):
        parts = []
        if self.bp_systolic and self.bp_diastolic:
            parts.append(f"BP {self.bp_systolic}/{self.bp_diastolic}")
        if self.blood_sugar:
            parts.append(f"Sugar: {self.blood_sugar}")
        self.latest_reading_display = ", ".join(parts) if parts else "No Reading"

    def auto_create_nurse_task(self):
        settings = frappe.get_single("Chronic Care Settings")
        if not settings.auto_assign_nurse_tasks:
            return

        task_type_map = {
            "Very High BP": "Call Patient",
            "Very High Sugar": "Call Patient",
            "High BP": "Follow Up",
            "High Sugar": "Follow Up",
            "Missed Reading": "Follow Up",
            "Missed Medication": "Check Medication",
            "Medium Risk": "Follow Up",
            "Slightly Elevated": "Follow Up",
        }

        task = frappe.new_doc("Nurse Task")
        task.task_type = task_type_map.get(self.alert_type, "Follow Up")
        task.patient = self.patient
        task.reason = self.reason or f"{self.alert_type}: {self.latest_reading_display}"
        task.priority = self.alert_level
        task.due_date = frappe.utils.today()
        task.assigned_to = self.assigned_nurse
        task.related_alert = self.name
        task.insert(ignore_permissions=True)

    def notify_care_team(self):
        if self.alert_level in ("Very High", "High"):
            frappe.publish_realtime(
                "chronic_care_alert",
                {
                    "alert_name": self.name,
                    "patient_name": self.patient_name,
                    "alert_level": self.alert_level,
                    "alert_type": self.alert_type,
                    "reading": self.latest_reading_display,
                },
                after_commit=True,
            )


# --- Alert threshold evaluation ---

THRESHOLDS = {
    "very_high": {
        "systolic": 180,
        "diastolic": 120,
        "sugar_mgdl": 300,
        "sugar_mmol": 16.7,
    },
    "high": {
        "systolic": 160,
        "diastolic": 100,
        "sugar_mgdl": 250,
        "sugar_mmol": 13.9,
    },
    "medium": {
        "systolic": 140,
        "diastolic": 90,
        "sugar_mgdl": 200,
        "sugar_mmol": 11.1,
    },
    "low": {
        "systolic": 130,
        "diastolic": 85,
        "sugar_mgdl": 180,
        "sugar_mmol": 10.0,
    },
}


def evaluate_reading(patient, bp_systolic, bp_diastolic, blood_sugar, sugar_unit="mg/dL", source_reading=None):
    """Evaluate a reading against alert thresholds and create alert if needed."""
    alert_level = None
    alert_type = None

    # Check BP thresholds
    if bp_systolic and bp_diastolic:
        if bp_systolic > 180 or bp_diastolic > 120:
            alert_level = "Very High"
            alert_type = "Very High BP"
        elif bp_systolic > 160 or bp_diastolic > 100:
            alert_level = "High"
            alert_type = "High BP"
        elif bp_systolic > 140 or bp_diastolic > 90:
            alert_level = "Medium"
            alert_type = "Medium Risk"
        elif bp_systolic > 130 or bp_diastolic > 85:
            alert_level = "Low"
            alert_type = "Slightly Elevated"

    # Check sugar thresholds (may upgrade alert level)
    if blood_sugar:
        sugar_val = blood_sugar
        if sugar_unit == "mmol/L":
            thresholds = [
                (16.7, "Very High", "Very High Sugar"),
                (13.9, "High", "High Sugar"),
                (11.1, "Medium", "Medium Risk"),
                (10.0, "Low", "Slightly Elevated"),
            ]
        else:
            thresholds = [
                (300, "Very High", "Very High Sugar"),
                (250, "High", "High Sugar"),
                (200, "Medium", "Medium Risk"),
                (180, "Low", "Slightly Elevated"),
            ]

        for threshold, level, atype in thresholds:
            if sugar_val > threshold:
                level_priority = {"Very High": 4, "High": 3, "Medium": 2, "Low": 1}
                current_priority = level_priority.get(alert_level, 0)
                new_priority = level_priority.get(level, 0)
                if new_priority > current_priority:
                    alert_level = level
                    alert_type = atype
                break

    if not alert_level:
        return None

    # Find assigned nurse
    assigned_nurse = frappe.db.get_value(
        "Patient",
        patient,
        "custom_assigned_nurse",
    )

    alert = frappe.new_doc("Chronic Care Alert")
    alert.patient = patient
    alert.alert_level = alert_level
    alert.alert_type = alert_type
    alert.bp_systolic = bp_systolic
    alert.bp_diastolic = bp_diastolic
    alert.blood_sugar = blood_sugar
    alert.blood_sugar_unit = sugar_unit
    alert.assigned_nurse = assigned_nurse
    alert.source_reading = source_reading
    alert.reason = f"Auto-generated: {alert_type}"
    alert.insert(ignore_permissions=True)

    return alert.name
