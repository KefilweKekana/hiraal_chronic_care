import frappe


def execute():
	"""Remove Free@$5 (and similar) from the live Subscription Plan catalog."""
	from hiraal_emr.services.subscription_catalog import repair_contradictory_free_plans

	repair_contradictory_free_plans()
