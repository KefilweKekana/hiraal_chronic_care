import frappe
from frappe.model.document import Document


class TelemedicineSession(Document):
    def validate(self):
        if self.start_time and self.end_time:
            from frappe.utils import time_diff_in_minutes
            self.duration_minutes = int(time_diff_in_minutes(self.end_time, self.start_time) or 0)
