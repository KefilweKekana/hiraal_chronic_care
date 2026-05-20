import frappe
from frappe import _


def _get_settings():
    return frappe.get_doc("Chronic Care Settings", "Chronic Care Settings")


def _charge_zaad(amount, phone, settings=None):
    """Stub: Charge via Zaad (Telesom mobile money)."""
    if not settings:
        settings = _get_settings()
    frappe.log_error(
        title=_("Zaad payment stub"),
        message=f"Amount: {amount}, Phone: {phone}"
    )
    # TODO: integrate Zaad API
    return {"status": "stub", "provider": "Zaad", "success": True}


def _charge_edahab(amount, phone, settings=None):
    """Stub: Charge via eDahab (Dahabshiil mobile money)."""
    if not settings:
        settings = _get_settings()
    frappe.log_error(
        title=_("eDahab payment stub"),
        message=f"Amount: {amount}, Phone: {phone}"
    )
    # TODO: integrate eDahab API
    return {"status": "stub", "provider": "eDahab", "success": True}


def _charge_stripe(amount, token, settings=None):
    """Stub: Charge via Stripe (for diaspora/card payments)."""
    if not settings:
        settings = _get_settings()
    frappe.log_error(
        title=_("Stripe payment stub"),
        message=f"Amount: {amount}, Token: {token}"
    )
    # TODO: integrate Stripe Charges API or PaymentIntents
    return {"status": "stub", "provider": "Stripe", "success": True}


def process_payment(subscription, method=None):
    """Route a subscription payment to the correct provider and record the result."""
    settings = _get_settings()
    provider = method or settings.payment_provider or "Zaad"
    amount = subscription.monthly_fee
    phone = subscription.patient_phone

    result = {"status": "failed", "provider": provider}

    if provider == "Zaad":
        result = _charge_zaad(amount, phone, settings)
    elif provider == "eDahab":
        result = _charge_edahab(amount, phone, settings)
    elif provider == "Stripe":
        result = _charge_stripe(amount, subscription.get("stripe_token"), settings)
    elif provider == "Cash":
        result = {"status": "success", "provider": "Cash", "success": True}
    elif provider == "Bank Transfer":
        result = {"status": "success", "provider": "Bank Transfer", "success": True}
    else:
        result = {"status": "error", "reason": f"Unknown provider {provider}"}

    # Record payment attempt
    payment = frappe.get_doc({
        "doctype": "Subscription Payment",
        "subscription": subscription.name,
        "amount": amount,
        "payment_method": provider,
        "status": "Success" if result.get("success") else "Failed",
        "transaction_reference": result.get("transaction_id", ""),
    })
    payment.insert(ignore_permissions=True)
    frappe.db.commit()

    return result
