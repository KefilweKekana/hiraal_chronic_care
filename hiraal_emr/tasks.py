"""
Hiraal EMR — Scheduled background tasks.
Runs via Frappe's scheduler (hooks.scheduler_events).
"""

import frappe
from frappe.utils import add_days, getdate, now_datetime, today


def generate_missed_reading_alerts():
    """Daily: flag patients who haven't submitted readings for N days."""
    try:
        settings = frappe.get_single("Chronic Care Settings")
        threshold_days = settings.missed_reading_alert_days or 2
    except Exception:
        threshold_days = 2

    cutoff = str(add_days(getdate(today()), -threshold_days))

    # Find active patients without a recent reading
    patients_with_readings = frappe.db.sql_list(
        """SELECT DISTINCT patient FROM `tabDaily Reading`
           WHERE reading_date >= %s""",
        cutoff,
    )

    all_active = frappe.get_all(
        "Patient",
        filters={"status": "Active"},
        fields=["name", "patient_name"],
        limit=5000,
    )

    reading_set = set(patients_with_readings)
    for p in all_active:
        if p.name not in reading_set:
            # Check if there's already an open missed-reading alert
            existing = frappe.db.exists(
                "Chronic Care Alert",
                {"patient": p.name, "alert_type": "Missed Reading", "status": "Open"},
            )
            if not existing:
                alert = frappe.new_doc("Chronic Care Alert")
                alert.patient = p.name
                alert.alert_level = "Medium"
                alert.alert_type = "Missed Reading"
                alert.reason = f"No reading submitted for {threshold_days}+ days"
                alert.insert(ignore_permissions=True)

    frappe.db.commit()


def process_subscription_billing():
    """Daily: charge subscriptions due today."""
    due_subs = frappe.get_all(
        "Care Subscription",
        filters={
            "status": ["in", ["Active", "Overdue"]],
            "next_billing_date": ["<=", today()],
            "auto_renew": 1,
        },
        pluck="name",
        limit=500,
    )

    for sub_name in due_subs:
        try:
            sub = frappe.get_doc("Care Subscription", sub_name)
            sub.process_payment()
        except Exception as e:
            frappe.log_error(f"Billing error for {sub_name}: {e}", "Subscription Billing")

    frappe.db.commit()


def mark_overdue_nurse_tasks():
    """Daily: mark past-due pending tasks as Overdue."""
    frappe.db.sql(
        """UPDATE `tabNurse Task`
           SET status = 'Overdue'
           WHERE status = 'Pending'
             AND due_date < %s""",
        today(),
    )
    frappe.db.commit()


def escalate_unresolved_alerts():
    """Hourly: auto-escalate open alerts past the escalation threshold."""
    try:
        settings = frappe.get_single("Chronic Care Settings")
        minutes = settings.escalation_time_minutes or 30
    except Exception:
        minutes = 30

    cutoff = frappe.utils.add_to_date(now_datetime(), minutes=-minutes)

    stale_alerts = frappe.get_all(
        "Chronic Care Alert",
        filters={
            "status": "Open",
            "alert_level": ["in", ["Very High", "High"]],
            "creation": ["<=", cutoff],
        },
        pluck="name",
        limit=100,
    )

    for alert_name in stale_alerts:
        try:
            from hiraal_emr.api import escalate_alert
            escalate_alert(alert_name)
        except Exception as e:
            frappe.log_error(f"Escalation error for {alert_name}: {e}", "Alert Escalation")

    frappe.db.commit()


def check_device_connectivity():
    """Hourly: flag devices that haven't synced in 2+ hours as Offline."""
    cutoff = frappe.utils.add_to_date(now_datetime(), hours=-2)

    frappe.db.sql(
        """UPDATE `tabPatient Device`
           SET status = 'Offline'
           WHERE status = 'Online'
             AND last_sync IS NOT NULL
             AND last_sync < %s""",
        cutoff,
    )
    frappe.db.commit()


def generate_weekly_summaries():
    """Weekly: generate health summaries for all active patients for the previous week."""
    from frappe.utils import add_days, getdate, today as today_fn

    today_date = getdate(today_fn())
    week_ending = add_days(today_date, -1)
    week_starting = add_days(today_date, -7)

    patients = frappe.get_all(
        "Patient",
        filters={"status": "Active"},
        fields=["name", "patient_name"],
        limit=5000,
    )

    for p in patients:
        # Check if summary already exists for this week
        existing = frappe.db.exists(
            "Weekly Health Summary",
            {"patient": p.name, "week_starting": week_starting},
        )
        if existing:
            continue

        # Get readings for the previous week
        readings = frappe.get_all(
            "Daily Reading",
            filters={
                "patient": p.name,
                "reading_date": ["between", [week_starting, week_ending]],
            },
            fields=["bp_systolic", "bp_diastolic", "blood_sugar", "medicine_taken"],
        )

        if not readings:
            continue

        total = len(readings)
        systolics = [r.bp_systolic for r in readings if r.bp_systolic]
        diastolics = [r.bp_diastolic for r in readings if r.bp_diastolic]
        sugars = [r.blood_sugar for r in readings if r.blood_sugar]
        med_taken = [r for r in readings if r.medicine_taken == "Yes"]
        high_readings = 0

        for r in readings:
            if r.bp_systolic and r.bp_systolic > 160:
                high_readings += 1
            elif r.bp_diastolic and r.bp_diastolic > 100:
                high_readings += 1
            elif r.blood_sugar and r.blood_sugar > 250:
                high_readings += 1

        avg_sys = round(sum(systolics) / len(systolics), 1) if systolics else 0
        avg_dia = round(sum(diastolics) / len(diastolics), 1) if diastolics else 0
        avg_sugar = round(sum(sugars) / len(sugars), 1) if sugars else 0
        adherence = round((len(med_taken) / total) * 100) if total else 0

        # Determine status
        if avg_sys > 160 or avg_dia > 100 or (avg_sugar and avg_sugar > 250):
            status = "High"
        elif avg_sys > 140 or avg_dia > 90 or (avg_sugar and avg_sugar > 200):
            status = "Elevated"
        elif avg_sys > 120 or avg_dia > 80 or (avg_sugar and avg_sugar > 140):
            status = "Stable"
        else:
            status = "Good"

        try:
            summary = frappe.new_doc("Weekly Health Summary")
            summary.patient = p.name
            summary.week_starting = week_starting
            summary.week_ending = week_ending
            summary.avg_systolic = avg_sys
            summary.avg_diastolic = avg_dia
            summary.avg_blood_sugar = avg_sugar
            summary.medication_adherence_percent = adherence
            summary.total_readings = total
            summary.high_readings_count = high_readings
            summary.status = status
            summary.insert(ignore_permissions=True)
        except Exception as e:
            frappe.log_error(
                f"Weekly summary error for {p.name}: {e}",
                "Weekly Summary",
            )

    frappe.db.commit()
