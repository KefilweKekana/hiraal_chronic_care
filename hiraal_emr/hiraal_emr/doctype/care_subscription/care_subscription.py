import frappe
from frappe.model.document import Document
from frappe.utils import add_months, getdate, today


class CareSubscription(Document):
    def validate(self):
        if not self.next_billing_date:
            self.next_billing_date = add_months(self.start_date, 1)

    def process_payment(self):
        """Attempt to charge the subscription and create payment record."""
        payment = frappe.new_doc("Subscription Payment")
        payment.subscription = self.name
        payment.patient = self.patient
        payment.amount = self.monthly_fee
        payment.payment_method = self.payment_method
        payment.status = "Pending"
        payment.insert(ignore_permissions=True)

        # In production, integrate with Zaad/eDahab/Stripe API here
        success = self._charge_payment_gateway(payment)

        if success:
            payment.db_set("status", "Success")
            self.db_set("last_payment_date", today())
            self.db_set("last_payment_status", "Success")
            self.db_set("next_billing_date", add_months(getdate(self.next_billing_date), 1))
            self.db_set("retry_count", 0)
            self.db_set("total_collected", (self.total_collected or 0) + self.monthly_fee)
            self.db_set("status", "Active")
        else:
            payment.db_set("status", "Failed")
            self.db_set("last_payment_status", "Failed")
            retry = (self.retry_count or 0) + 1
            self.db_set("retry_count", retry)
            if retry >= (self.max_retries or 3):
                self.db_set("status", "Past Due")
            else:
                self.db_set("status", "Overdue")

        return payment.name

    def _charge_payment_gateway(self, payment):
        """Placeholder for payment gateway integration."""
        # TODO: Integrate Zaad API, eDahab API, Stripe
        if self.payment_method == "Cash":
            return True
        return True  # Placeholder — assume success
