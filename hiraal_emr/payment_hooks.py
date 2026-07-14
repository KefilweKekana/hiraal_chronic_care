"""Real-time payment completion hooks.

Listens for the mobile_payments gateway to mark a transaction as Completed,
then immediately marks the linked order/subscription paid and pushes an FCM
notification to the patient so the app can transition instantly.
"""

import frappe


def on_mobile_payment_update(doc, method=None):
    """React when a Mobile Payment Transaction Log becomes Completed."""
    if doc.status != "Completed":
        return

    # Avoid duplicate processing: only act on the transition to Completed.
    if frappe.db.get_value("Mobile Payment Transaction Log", doc.name, "status") != "Completed":
        return

    patient = None
    notification = None
    order = None
    sub = None

    # 1. Medicine order — try the persistent link first.
    order = frappe.db.get_value(
        "Medicine Request", {"payment_reference": doc.name}, ["name", "patient"], as_dict=True
    )
    if not order and doc.sales_invoice:
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

    # 2. Care Subscription — persistent link.
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

    # 3. Fallback: cache binding from pay_my_order / pay_my_subscription.
    if not patient:
        patient = frappe.cache().get_value(f"hiraal_txn_owner:{doc.name}")
    if not patient:
        cached_order = frappe.cache().get_value(f"hiraal_txn_order:{doc.name}")
        if cached_order:
            order = frappe.db.get_value(
                "Medicine Request", cached_order, ["name", "patient"], as_dict=True
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
