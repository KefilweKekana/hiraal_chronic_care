"""Shared rate-limit helpers for public and mobile APIs."""

from __future__ import annotations

import frappe
from frappe import _


def rate_limit(key: str, limit: int, window_sec: int, message: str | None = None):
    """Increment a sliding counter; throw when limit exceeded."""
    cache_key = f"hiraal_rl:{key}"
    count = int(frappe.cache().get_value(cache_key) or 0)
    if count >= limit:
        frappe.throw(
            message or _("Too many attempts. Please try again later."),
            frappe.ValidationError,
        )
    frappe.cache().set_value(cache_key, count + 1, expires_in_sec=window_sec)


def client_rate_key(prefix: str, identifier: str) -> str:
    ip = (getattr(frappe.local, "request_ip", None) or "").strip() or "unknown"
    user = getattr(frappe.session, "user", None) or "Guest"
    ident = (identifier or "").strip().lower() or "-"
    return f"{prefix}:{user}:{ip}:{ident}"
