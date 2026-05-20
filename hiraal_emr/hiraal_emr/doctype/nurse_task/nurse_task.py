import frappe
from frappe.model.document import Document
from frappe.utils import now_datetime, today


class NurseTask(Document):
    def before_save(self):
        if self.has_value_changed("status"):
            if self.status == "In Progress" and not self.started_at:
                self.started_at = now_datetime()
            elif self.status == "Completed" and not self.completed_at:
                self.completed_at = now_datetime()

    def after_insert(self):
        if self.assigned_to:
            frappe.publish_realtime(
                "nurse_task_assigned",
                {"task": self.name, "patient": self.patient_name, "type": self.task_type},
                user=frappe.db.get_value("Healthcare Practitioner", self.assigned_to, "user_id"),
                after_commit=True,
            )

    @staticmethod
    def get_daily_stats(nurse=None):
        """Get task statistics for the dashboard."""
        filters = {"due_date": today()}
        if nurse:
            filters["assigned_to"] = nurse

        return {
            "due_today": frappe.db.count("Nurse Task", {**filters, "status": ["in", ["Pending", "In Progress"]]}),
            "overdue": frappe.db.count("Nurse Task", {**filters, "status": "Overdue"}),
            "high_priority": frappe.db.count("Nurse Task", {**filters, "priority": ["in", ["Very High", "High"]], "status": ["!=", "Completed"]}),
            "completed": frappe.db.count("Nurse Task", {**filters, "status": "Completed"}),
        }
