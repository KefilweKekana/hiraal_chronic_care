"""Medicine Request — Pharmacy fulfillment workflow (Section 4.9)."""

import frappe
from frappe.model.document import Document
from frappe.utils import now_datetime


class MedicineRequest(Document):
    def validate(self):
        self.total_items = len(self.medicines) if self.medicines else 0

    def before_save(self):
        if self.has_value_changed("status"):
            ts = now_datetime()
            if self.status == "Preparing":
                self.preparation_started = ts
            elif self.status == "Dispatched":
                self.dispatched_at = ts
            elif self.status == "Delivered":
                self.delivered_at = ts
                self.actual_delivery = ts

    def after_insert(self):
        # Auto-create nurse task for medicine follow-up
        if frappe.db.exists("DocType", "Nurse Task"):
            task = frappe.new_doc("Nurse Task")
            task.task_type = "Check Medication"
            task.patient = self.patient
            task.priority = "Medium" if self.priority == "Normal" else "High"
            task.due_date = frappe.utils.today()
            task.insert(ignore_permissions=True)
