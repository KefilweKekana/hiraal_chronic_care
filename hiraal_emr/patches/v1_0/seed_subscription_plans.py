import frappe


def execute():
	"""Seed default Subscription Plan catalog rows if none exist yet."""
	from hiraal_emr.services.subscription_catalog import ensure_default_plans

	ensure_default_plans()
