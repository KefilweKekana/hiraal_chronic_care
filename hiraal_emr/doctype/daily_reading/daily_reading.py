import frappe
from frappe.model.document import Document
from frappe.utils import now_datetime


class DailyReading(Document):
    def validate(self):
        self.assess_risk_level()

    def after_insert(self):
        self.evaluate_and_alert()
        self.update_patient_last_submission()

    def assess_risk_level(self):
        """Classify reading risk based on thresholds."""
        level = "Normal"

        if self.bp_systolic:
            if self.bp_systolic > 180 or (self.bp_diastolic and self.bp_diastolic > 120):
                level = "Critical"
            elif self.bp_systolic > 160 or (self.bp_diastolic and self.bp_diastolic > 100):
                level = "High"
            elif self.bp_systolic > 140 or (self.bp_diastolic and self.bp_diastolic > 90):
                level = "Medium"

        if self.blood_sugar:
            sugar_thresholds = {
                "mg/dL": [(300, "Critical"), (250, "High"), (200, "Medium")],
                "mmol/L": [(16.7, "Critical"), (13.9, "High"), (11.1, "Medium")],
            }
            unit = self.blood_sugar_unit or "mg/dL"
            for threshold, risk in sugar_thresholds.get(unit, []):
                if self.blood_sugar > threshold:
                    priority = {"Critical": 4, "High": 3, "Medium": 2, "Normal": 1}
                    if priority.get(risk, 0) > priority.get(level, 0):
                        level = risk
                    break

        self.risk_level = level

    def evaluate_and_alert(self):
        """Trigger alert creation if reading is abnormal."""
        if self.risk_level in ("High", "Critical"):
            from hiraal_emr.hiraal_emr.doctype.chronic_care_alert.chronic_care_alert import (
                evaluate_reading,
            )

            alert_name = evaluate_reading(
                patient=self.patient,
                bp_systolic=self.bp_systolic,
                bp_diastolic=self.bp_diastolic,
                blood_sugar=self.blood_sugar,
                sugar_unit=self.blood_sugar_unit or "mg/dL",
                source_reading=self.name,
            )
            if alert_name:
                self.db_set("alert_generated", alert_name, update_modified=False)

    def update_patient_last_submission(self):
        """Update patient record with last submission timestamp."""
        frappe.db.set_value(
            "Patient",
            self.patient,
            "custom_last_submission",
            now_datetime(),
            update_modified=False,
        )
