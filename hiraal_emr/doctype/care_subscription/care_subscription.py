import frappe
from frappe.model.document import Document
from frappe.utils import add_months, flt, getdate, today


class CareSubscription(Document):
    def validate(self):
        if self.plan and frappe.db.exists("DocType", "Subscription Plan"):
            plan = frappe.db.get_value(
                "Subscription Plan",
                self.plan,
                ["monthly_fee", "category"],
                as_dict=True,
            )
            if plan:
                if not self.monthly_fee:
                    self.monthly_fee = flt(plan.monthly_fee)
                if hasattr(self, "plan_category") and not self.plan_category:
                    self.plan_category = plan.category
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

        success = self._charge_payment_gateway(payment)

        if success:
            payment.db_set("status", "Success")
            self.db_set("last_payment_date", today())
            self.db_set("last_payment_status", "Success")
            self.db_set("next_billing_date", add_months(getdate(self.next_billing_date), 1))
            self.db_set("retry_count", 0)
            self.db_set("total_collected", (self.total_collected or 0) + self.monthly_fee)
            self.db_set("status", "Active")
            if hasattr(self, "is_on_trial"):
                self.db_set("is_on_trial", 0)
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
        if self.payment_method == "Cash":
            return True
        return True
