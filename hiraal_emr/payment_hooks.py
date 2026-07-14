"""Real-time payment completion hooks.

Listens for the mobile_payments gateway to mark a transaction as Completed,
then immediately notifies the patient via FCM so the app can transition from
the "waiting for payment" screen to "paid" without waiting for the next poll.
"""

import frappe


def on_mobile_payment_update(doc, method=None):
    """React when a Mobile Payment Transaction Log becomes Completed."""
    if doc.status != "Completed":
        return

    # Avoid duplicate processing: only act on the transition to Completed.
    if frappe.db.get_value("Mobile Payment Transaction Log", doc.name, "status") != "Completed":
        return

    # The transaction may be bound to a Medicine Request or a Care Subscription.
    patient = None
    notification = None

    # 1. Medicine order
    if doc.sales_invoice:
        order = frappe.db.get_value(
            "Medicine Request", {"payment_reference": doc.name}, ["name", "patient"], as_dict=True
        )
        if not order:
            order = frappe.db.get_value(
                "Medicine Request", {"sales_invoice": doc.sales_invoice}, ["name", "patient"], as_dict=True
            )
        if order:
            from hiraal_emr.api import mark_order_paid
            mark_order_paid(order.name, doc.name)
            patient = order.patient
            notification = {
                "title": "Payment received",
                "body": "Your medicine order payment was received. We're preparing it now.",
                "data": {"type": "payment_complete", "order": order.name},
            }

    # 2. Care Subscription
    if not patient:
        sub = frappe.db.get_value(
            "Care Subscription", {"payment_reference": doc.name}, ["name", "patient"], as_dict=True
        )
        if sub:
            from hiraal_emr.api import _mark_subscription_paid
            _mark_subscription_paid(sub.patient, doc.name)
            patient = sub.patient
            notification = {
                "title": "Subscription active",
                "body": "Your payment was received. Your Hiraal subscription is now active.",
                "data": {"type": "subscription_payment_complete", "subscription": sub.name},
            }

    # 3. Fallback: try to find the owner via the cache binding and push anyway.
    if not patient:
        patient = frappe.cache().get_value(f"hiraal_txn_owner:{doc.name}")
    if not patient:
        order = frappe.cache().get_value(f"hiraal_txn_order:{doc.name}")
        if order:
            patient = frappe.db.get_value("Medicine Request", order, "patient")

    if patient and notification:
        _push_to_patient(patient, notification)


def _push_to_patient(patient, notification):
    """Send an FCM push notification to every device registered for this patient."""
    try:
        tokens = frappe.get_all(
            "Hiraal Push Token",
            filters={"patient": patient, "enabled": 1},
            pluck="token",
        )
        if not tokens:
            return
        from hiraal_emr.api import _fcm_send
        _fcm_send(tokens, notification["title"], notification["body"], data=notification.get("data"))
    except Exception:
        frappe.logger("hiraal_pay").exception("Failed to push payment completion to %s", patient)
