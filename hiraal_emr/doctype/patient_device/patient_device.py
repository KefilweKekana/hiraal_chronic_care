import frappe
from frappe.model.document import Document


class PatientDevice(Document):
    def validate(self):
        if self.battery_level and self.battery_level < 20:
            self.status = "Low Battery"
