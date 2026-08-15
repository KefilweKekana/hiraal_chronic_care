"""Subscription plan catalog + free-trial helpers for the mobile app."""

from __future__ import annotations

import frappe
from frappe import _
from frappe.utils import add_days, flt, getdate, today


# Fallback when Subscription Plan DocType is empty / not migrated yet.
_FALLBACK_PLANS = [
	{
		"name": "Standard Care",
		"plan_name": "Standard Care",
		"category": "General",
		"monthly_fee": 5.0,
		"description": "",
		"allows_trial": 1,
		"is_featured": 0,
		"features": [
			"Daily vitals monitoring",
			"Nurse & doctor review",
			"Medicine delivery",
			"Telemedicine visits",
		],
	},
	{
		"name": "Premium Care",
		"plan_name": "Premium Care",
		"category": "General",
		"monthly_fee": 10.0,
		"description": "",
		"allows_trial": 1,
		"is_featured": 1,
		"features": [
			"Everything in Standard Care",
			"Priority alerts & faster review",
			"Optional 5G home hub",
			"Extended support",
		],
	},
]


def feature_list(raw):
	if not raw:
		return []
	if isinstance(raw, (list, tuple)):
		return [str(x).strip() for x in raw if str(x).strip()]
	return [ln.strip() for ln in str(raw).splitlines() if ln.strip()]


def subscription_plans_catalog():
	"""Active Subscription Plan rows for the app, or the hardcoded fallback."""
	if frappe.db.exists("DocType", "Subscription Plan"):
		try:
			rows = frappe.get_all(
				"Subscription Plan",
				filters={"is_active": 1},
				fields=[
					"name",
					"plan_name",
					"category",
					"monthly_fee",
					"description",
					"features",
					"allows_trial",
					"is_featured",
					"display_order",
				],
				order_by="display_order asc, plan_name asc",
				limit_page_length=100,
				ignore_permissions=True,
			)
		except Exception:
			frappe.logger("hiraal_sub").exception("subscription plan catalog failed")
			rows = []
		if rows:
			return [
				{
					"name": r.get("name") or r.get("plan_name"),
					"plan_name": r.get("plan_name") or r.get("name"),
					"category": r.get("category") or "General",
					"monthly_fee": flt(r.get("monthly_fee")),
					"description": r.get("description") or "",
					"allows_trial": 1 if int(r.get("allows_trial") or 0) else 0,
					"is_featured": 1 if int(r.get("is_featured") or 0) else 0,
					"features": feature_list(r.get("features")),
				}
				for r in rows
			]
	return [dict(p) for p in _FALLBACK_PLANS]


def trial_config():
	enabled = False
	days = 14
	try:
		if frappe.db.exists("DocType", "Chronic Care Settings"):
			settings = frappe.get_single("Chronic Care Settings")
			enabled = bool(int(getattr(settings, "enable_free_trial", 0) or 0))
			days = int(getattr(settings, "free_trial_days", 14) or 14)
	except Exception:
		frappe.logger("hiraal_sub").exception("trial config load failed")
	if days < 1:
		days = 1
	return {"enabled": enabled, "days": days}


def patient_trial_eligible(patient):
	"""New patients only — anyone who already had a Care Subscription is ineligible."""
	if not patient:
		return False
	return not bool(frappe.db.exists("Care Subscription", {"patient": patient}))


def resolve_plan(plan_name):
	if not plan_name:
		return None
	for p in subscription_plans_catalog():
		if p["name"] == plan_name or p.get("plan_name") == plan_name:
			return p
	if frappe.db.exists("DocType", "Subscription Plan") and frappe.db.exists(
		"Subscription Plan", plan_name
	):
		doc = frappe.db.get_value(
			"Subscription Plan",
			plan_name,
			[
				"name",
				"plan_name",
				"category",
				"monthly_fee",
				"description",
				"features",
				"allows_trial",
				"is_featured",
				"is_active",
			],
			as_dict=True,
		)
		if doc and int(doc.get("is_active") or 0):
			return {
				"name": doc.name,
				"plan_name": doc.plan_name or doc.name,
				"category": doc.category or "General",
				"monthly_fee": flt(doc.monthly_fee),
				"description": doc.description or "",
				"allows_trial": 1 if int(doc.allows_trial or 0) else 0,
				"is_featured": 1 if int(doc.is_featured or 0) else 0,
				"features": feature_list(doc.features),
			}
	return None


def has_active_subscription(patient):
	"""True when the patient may use paid app features (Active, including trial)."""
	if not patient:
		return False
	sub = frappe.db.get_value(
		"Care Subscription",
		{"patient": patient, "status": "Active"},
		["name", "is_on_trial", "trial_end_date"],
		as_dict=True,
		order_by="creation desc",
	)
	if not sub:
		return False
	if int(sub.get("is_on_trial") or 0) and sub.get("trial_end_date"):
		if getdate(sub.trial_end_date) < getdate(today()):
			return False
	return True


def ensure_default_plans():
	"""Create starter Subscription Plan rows if the catalog is empty."""
	if not frappe.db.exists("DocType", "Subscription Plan"):
		return
	if frappe.db.count("Subscription Plan") > 0:
		return
	defaults = [
		{
			"plan_name": "Standard Care",
			"category": "General",
			"monthly_fee": 5,
			"allows_trial": 1,
			"is_featured": 0,
			"display_order": 1,
			"features": "\n".join(_FALLBACK_PLANS[0]["features"]),
		},
		{
			"plan_name": "Premium Care",
			"category": "General",
			"monthly_fee": 10,
			"allows_trial": 1,
			"is_featured": 1,
			"display_order": 2,
			"features": "\n".join(_FALLBACK_PLANS[1]["features"]),
		},
		{
			"plan_name": "Hypertension Care",
			"category": "Hypertension",
			"monthly_fee": 5,
			"allows_trial": 1,
			"is_featured": 0,
			"display_order": 3,
			"description": "Focused monitoring for blood-pressure patients",
			"features": "Daily BP tracking\nNurse review\nMedicine delivery\nTelemedicine",
		},
		{
			"plan_name": "Diabetes Care",
			"category": "Diabetes",
			"monthly_fee": 5,
			"allows_trial": 1,
			"is_featured": 0,
			"display_order": 4,
			"description": "Focused monitoring for blood-sugar patients",
			"features": "Daily sugar tracking\nNurse review\nMedicine delivery\nTelemedicine",
		},
	]
	for row in defaults:
		doc = frappe.get_doc({"doctype": "Subscription Plan", "is_active": 1, **row})
		doc.insert(ignore_permissions=True)
	frappe.db.commit()
