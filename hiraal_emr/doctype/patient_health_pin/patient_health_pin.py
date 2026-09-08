import frappe
from frappe import _
from frappe.model.document import Document


class PatientHealthPIN(Document):
    def before_save(self):
        # Never keep a reversible or plaintext copy on the document.
        self.pin_hash = (self.pin_hash or "").strip()
        self.pin_salt = (self.pin_salt or "").strip()
        if not self.pin_hash or not self.pin_salt:
            frappe.throw(_("Health PIN hash is missing"))
