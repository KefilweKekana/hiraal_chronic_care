"""
Hiraal EMR — Whitelisted API endpoints for dashboard pages, mobile app,
and document event hooks.
"""

import frappe
from frappe import _
from frappe.utils import add_days, add_months, add_to_date, flt, get_datetime, getdate, now_datetime, today
import json

from hiraal_emr.services.otp_service import generate_otp, verify_otp as otp_verify
from hiraal_emr.services.sms_service import send_otp_sms, send_alert_sms, send_sms
try:
    from hiraal_emr.doctype.audit_log.audit_log import log_action as audit_log
except Exception:
    # Audit logging must never break module import or site boot. If the
    # audit_log doctype module isn't importable in an environment, degrade to a
    # no-op rather than taking down the whole desk with a SessionBootFailed.
    def audit_log(*args, **kwargs):
        return None


# ──────────────────────────────────────────────
#  Boot session
# ──────────────────────────────────────────────

def boot_session(bootinfo):
    """Inject Hiraal EMR config into the boot payload."""
    if frappe.db.exists("DocType", "Chronic Care Settings"):
        try:
            settings = frappe.get_single("Chronic Care Settings")
            bootinfo["hiraal_emr"] = {
                "clinic_name": settings.clinic_name,
                "auto_assign": settings.auto_assign_nurse_tasks,
            }
        except Exception:
            pass


# ──────────────────────────────────────────────
#  Clinic Dashboard  (Section 4.1)
# ──────────────────────────────────────────────

@frappe.whitelist()
def get_dashboard_data():
    """Return all data needed for the Clinic Dashboard page."""
    _require_clinical()
    today_str = today()
    yesterday = str(add_days(getdate(today_str), -1))

    # Active patients
    active_patients = frappe.db.count("Patient", {"status": "Active"}) or 0
    new_patients_month = frappe.db.count(
        "Patient", {"creation": [">=", add_days(getdate(today_str), -30)]}
    ) or 0

    # Today's submissions
    todays_submissions = frappe.db.count(
        "Daily Reading", {"reading_date": today_str}
    ) or 0
    yesterdays_submissions = frappe.db.count(
        "Daily Reading", {"reading_date": yesterday}
    ) or 1
    submissions_change = round(
        ((todays_submissions - yesterdays_submissions) / max(yesterdays_submissions, 1)) * 100
    )

    # High-risk alerts
    high_risk_alerts = frappe.db.count(
        "Chronic Care Alert",
        {"alert_level": ["in", ["Very High", "High"]], "status": "Open"},
    ) or 0
    new_alerts = frappe.db.count(
        "Chronic Care Alert",
        {"creation": [">=", today_str], "status": "Open"},
    ) or 0

    # Missed submissions (patients who haven't submitted today)
    patients_submitted_today = frappe.db.sql(
        """SELECT COUNT(DISTINCT patient) FROM `tabDaily Reading`
           WHERE reading_date = %s""",
        today_str,
    )[0][0] or 0
    missed_submissions = max(0, active_patients - patients_submitted_today)

    # Unpaid subscriptions
    unpaid_subscriptions = frappe.db.count(
        "Care Subscription",
        {"status": ["in", ["Overdue", "Past Due"]]},
    ) or 0

    # Priority alerts (top 5)
    priority_alerts = frappe.get_all(
        "Chronic Care Alert",
        filters={"status": "Open", "alert_level": ["in", ["Very High", "High"]]},
        fields=[
            "name", "patient", "patient_name", "alert_level", "alert_type",
            "latest_reading_display", "assigned_nurse_name", "creation",
        ],
        order_by="creation desc",
        limit=5,
    )

    # Quick access counts
    appointments_today = frappe.db.count(
        "Patient Appointment", {"appointment_date": today_str}
    ) or 0
    appointments_upcoming = frappe.db.count(
        "Patient Appointment",
        {"appointment_date": [">", today_str], "status": ["!=", "Cancelled"]},
    ) or 0

    lab_requests_total = frappe.db.count("Lab Test") or 0
    lab_requests_pending = frappe.db.count(
        "Lab Test", {"docstatus": 0}
    ) or 0

    nurse_tasks_total = frappe.db.count(
        "Nurse Task", {"due_date": today_str}
    ) or 0
    nurse_tasks_pending = frappe.db.count(
        "Nurse Task", {"due_date": today_str, "status": "Pending"}
    ) or 0

    patients_at_risk = frappe.db.count(
        "Chronic Care Alert", {"status": "Open"}
    ) or 0
    patients_high_risk = frappe.db.count(
        "Chronic Care Alert",
        {"status": "Open", "alert_level": ["in", ["Very High", "High"]]},
    ) or 0

    # Today's appointments
    todays_appointments = frappe.get_all(
        "Patient Appointment",
        filters={"appointment_date": today_str},
        fields=[
            "name", "patient", "patient_name", "appointment_time",
            "appointment_type", "practitioner_name", "status",
        ],
        order_by="appointment_time asc",
        limit=10,
    )

    # Recent activity (last 10 readings/alerts/tasks)
    recent_activity = []

    # Recent readings
    recent_readings = frappe.get_all(
        "Daily Reading",
        filters={"reading_date": today_str},
        fields=["patient_name", "bp_systolic", "bp_diastolic", "blood_sugar", "creation"],
        order_by="creation desc",
        limit=5,
    )
    for r in recent_readings:
        bp = f"BP: {r.bp_systolic}/{r.bp_diastolic}" if r.bp_systolic else ""
        sugar = f"Sugar: {r.blood_sugar}" if r.blood_sugar else ""
        recent_activity.append({
            "icon": "✓",
            "icon_class": "success",
            "message": f"New reading received from <strong>{r.patient_name}</strong> — {', '.join(filter(None, [bp, sugar]))}",
            "time": frappe.utils.pretty_date(r.creation),
        })

    # Recent high alerts
    recent_alerts = frappe.get_all(
        "Chronic Care Alert",
        filters={"creation": [">=", today_str], "status": "Open"},
        fields=["patient_name", "alert_type", "alert_level", "creation"],
        order_by="creation desc",
        limit=3,
    )
    for a in recent_alerts:
        recent_activity.append({
            "icon": "⚠",
            "icon_class": "warning" if a.alert_level in ("Very High", "High") else "info",
            "message": f"High alert for <strong>{a.patient_name}</strong> — {a.alert_type}",
            "time": frappe.utils.pretty_date(a.creation),
        })

    # Recent new patients
    new_patients = frappe.get_all(
        "Patient",
        filters={"creation": [">=", add_days(getdate(today_str), -7)]},
        fields=["patient_name", "creation"],
        order_by="creation desc",
        limit=2,
    )
    for p in new_patients:
        recent_activity.append({
            "icon": "👤",
            "icon_class": "primary",
            "message": f"New patient registered: <strong>{p.patient_name}</strong>",
            "time": frappe.utils.pretty_date(p.creation),
        })

    # Sort by time and limit
    recent_activity.sort(key=lambda x: x["time"], reverse=True)
    recent_activity = recent_activity[:10]

    return {
        "active_patients": active_patients,
        "new_patients_month": new_patients_month,
        "todays_submissions": todays_submissions,
        "submissions_change": submissions_change,
        "high_risk_alerts": high_risk_alerts,
        "new_alerts": new_alerts,
        "missed_submissions": missed_submissions,
        "missed_change": 0,
        "unpaid_subscriptions": unpaid_subscriptions,
        "priority_alerts": priority_alerts,
        "appointments_today": appointments_today,
        "appointments_upcoming": appointments_upcoming,
        "lab_requests_total": lab_requests_total,
        "lab_requests_pending": lab_requests_pending,
        "medicine_requests_total": frappe.db.count("Medicine Request") or 0,
        "medicine_requests_pending": frappe.db.count(
            "Medicine Request",
            # "Pending" isn't in the current lifecycle but exists on legacy rows.
            {"status": ["in", ["Received", "Under Review", "Pending"]]},
        ) or 0,
        "nurse_tasks_total": nurse_tasks_total,
        "nurse_tasks_pending": nurse_tasks_pending,
        "patients_at_risk": patients_at_risk,
        "patients_high_risk": patients_high_risk,
        "todays_appointments": todays_appointments,
        "recent_activity": recent_activity,
        "alert_trend_data": _get_alert_trend_data(),
        "alerts_this_week": frappe.db.count(
            "Chronic Care Alert",
            {"creation": [">=", add_days(getdate(today_str), -7)]},
        ) or 0,
        "alerts_last_week": frappe.db.sql(
            """SELECT COUNT(*) FROM `tabChronic Care Alert`
               WHERE creation >= %s AND creation < %s""",
            (add_days(getdate(today_str), -14), add_days(getdate(today_str), -7)),
        )[0][0] or 0,
    }


def _get_alert_trend_data():
    """Get alert counts per day of the week for charts."""
    labels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    high = [0] * 7
    medium = [0] * 7
    low = [0] * 7

    seven_days_ago = add_days(getdate(today()), -6)
    alerts = frappe.get_all(
        "Chronic Care Alert",
        filters={"creation": [">=", str(seven_days_ago)]},
        fields=["creation", "alert_level"],
    )
    for a in alerts:
        day_idx = getdate(a.creation).weekday()
        if a.alert_level in ("Very High", "High"):
            high[day_idx] += 1
        elif a.alert_level == "Medium":
            medium[day_idx] += 1
        else:
            low[day_idx] += 1

    return {"labels": labels, "high": high, "medium": medium, "low": low}


# ──────────────────────────────────────────────
#  Alert Queue  (Section 4.2)
# ──────────────────────────────────────────────

@frappe.whitelist()
def get_alert_queue_data():
    """Return all data for the Alert Queue page."""
    _require_clinical()
    open_alerts = frappe.get_all(
        "Chronic Care Alert",
        filters={"status": ["in", ["Open", "In Review"]]},
        fields=[
            "name", "patient", "patient_name", "alert_level", "alert_type",
            "latest_reading_display", "assigned_nurse_name", "creation",
            "bp_systolic", "bp_diastolic", "blood_sugar", "reason",
        ],
        order_by="creation desc",
    )
    # Frappe v15 rejects FIELD() in order_by, so rank severity in Python:
    # Very High > High > Medium > Low, then newest first (the DB fetch above
    # is already newest-first and sort() is stable).
    _severity = {"Very High": 0, "High": 1, "Medium": 2, "Low": 3}
    open_alerts.sort(key=lambda a: _severity.get(a.alert_level, 4))
    open_alerts = open_alerts[:50]

    counts = {"very_high": 0, "high": 0, "medium": 0, "low": 0}
    for a in open_alerts:
        key = a.alert_level.lower().replace(" ", "_")
        counts[key] = counts.get(key, 0) + 1

    return {
        "alerts": open_alerts,
        "very_high": counts["very_high"],
        "high": counts["high"],
        "medium": counts["medium"],
        "low": counts["low"],
        "total": len(open_alerts),
    }


@frappe.whitelist()
def escalate_alert(alert_name):
    """Escalate an alert to doctor review."""
    _require_clinical()
    if not frappe.db.exists("Chronic Care Alert", alert_name):
        frappe.throw(_("Alert {0} not found").format(alert_name), frappe.DoesNotExistError)

    alert = frappe.get_doc("Chronic Care Alert", alert_name)
    alert.status = "Escalated"
    alert.escalation_time = now_datetime()
    alert.save(ignore_permissions=True)

    # Create a Doctor Review
    review = frappe.new_doc("Doctor Review")
    review.patient = alert.patient
    review.priority = alert.alert_level
    review.reason = f"Escalated: {alert.alert_type} — {alert.latest_reading_display}"
    review.related_alert = alert.name
    review.insert(ignore_permissions=True)

    return review.name


@frappe.whitelist()
def add_alert_note(alert_name, note):
    """Add a resolution note to an alert."""
    _require_clinical()
    if not frappe.db.exists("Chronic Care Alert", alert_name):
        frappe.throw(_("Alert {0} not found").format(alert_name), frappe.DoesNotExistError)

    frappe.db.set_value(
        "Chronic Care Alert", alert_name, "resolution_note", note
    )
    return "ok"


@frappe.whitelist()
def resolve_alert(alert_name):
    """Mark an alert as Resolved."""
    _require_clinical()
    if not frappe.db.exists("Chronic Care Alert", alert_name):
        frappe.throw(_("Alert {0} not found").format(alert_name), frappe.DoesNotExistError)
    frappe.db.set_value("Chronic Care Alert", alert_name, {
        "status": "Resolved",
        "resolved_at": now_datetime(),
    })
    return "ok"


# ──────────────────────────────────────────────
#  Analytics Dashboard  (Section 7.2)
# ──────────────────────────────────────────────

@frappe.whitelist()
def get_analytics_data():
    """Return data for the Analytics Dashboard page."""
    _require_clinical()
    total_patients = frappe.db.count("Patient", {"status": "Active"}) or 0

    active_subscriptions = frappe.db.count(
        "Care Subscription", {"status": "Active"}
    ) or 0

    monthly_revenue = frappe.db.sql(
        """SELECT IFNULL(SUM(amount), 0) FROM `tabSubscription Payment`
           WHERE status='Success' AND MONTH(payment_date)=MONTH(NOW())
           AND YEAR(payment_date)=YEAR(NOW())""",
    )[0][0] or 0

    high_risk_patients = frappe.db.count(
        "Chronic Care Alert",
        {"status": "Open", "alert_level": ["in", ["Very High", "High"]]},
    ) or 0

    # Nurse/Doctor operations
    nurse_tasks_completed = frappe.db.count(
        "Nurse Task",
        {"status": "Completed", "completed_at": [">=", add_days(getdate(today()), -30)]},
    ) or 0
    doctor_reviews_done = frappe.db.count(
        "Doctor Review",
        {"review_status": "Reviewed", "reviewed_at": [">=", add_days(getdate(today()), -30)]},
    ) or 0

    # Risk distribution
    risk_high = frappe.db.count(
        "Chronic Care Alert", {"status": "Open", "alert_level": ["in", ["Very High", "High"]]}
    ) or 0
    risk_medium = frappe.db.count(
        "Chronic Care Alert", {"status": "Open", "alert_level": "Medium"}
    ) or 0
    risk_low = max(0, total_patients - risk_high - risk_medium)

    total_risk = risk_high + risk_medium + risk_low or 1

    # Insights
    insights = []
    if risk_high > 0:
        insights.append({
            "icon": "⚠",
            "title": f"High-Risk patients: {risk_high}",
            "description": f"Follow up on {risk_high} patients with critical readings.",
        })
    if nurse_tasks_completed > 0:
        insights.append({
            "icon": "✅",
            "title": f"Nurse tasks completed: {nurse_tasks_completed}",
            "description": "Great job! Keep it up.",
        })
    if monthly_revenue > 0:
        insights.append({
            "icon": "💰",
            "title": f"Revenue this month: ${monthly_revenue:,.0f}",
            "description": "On track for growth.",
        })

    return {
        "total_patients": total_patients,
        "patient_growth": "↑ 0%",
        "active_subscriptions": active_subscriptions,
        "subscription_growth": "↑ 0%",
        "monthly_revenue": monthly_revenue,
        "revenue_growth": "↑ 0%",
        "high_risk_patients": high_risk_patients,
        "risk_growth": "↑ 0%",
        "engagement_score": 72,
        "engagement_growth": "↑ 0%",
        "controlled_bp": 65,
        "controlled_sugar": 58,
        "uncontrolled": 22,
        "nurse_tasks_completed": nurse_tasks_completed,
        "doctor_reviews_done": doctor_reviews_done,
        "avg_response_hours": 2.4,
        "funnel_submitted": total_patients,
        "funnel_nurse_reviewed": int(total_patients * 0.78),
        "funnel_doctor_reviewed": int(total_patients * 0.49),
        "funnel_action_taken": int(total_patients * 0.41),
        "funnel_nurse_pct": 78,
        "funnel_doctor_pct": 49,
        "funnel_action_pct": 41,
        "risk_high": risk_high,
        "risk_high_pct": round(risk_high / total_risk * 100, 1),
        "risk_high_trend": "",
        "risk_medium": risk_medium,
        "risk_medium_pct": round(risk_medium / total_risk * 100, 1),
        "risk_medium_trend": "",
        "risk_low": risk_low,
        "risk_low_pct": round(risk_low / total_risk * 100, 1),
        "risk_low_trend": "",
        "insights": insights,
        "revenue_trend": _get_revenue_trend_data(),
    }


def _get_revenue_trend_data():
    """Get revenue trend for the last 6 months from Subscription Payment data."""
    from frappe.utils import get_first_day, add_months, formatdate

    labels = []
    collected = []
    pending = []

    for i in range(5, -1, -1):
        month_date = add_months(get_first_day(today()), -i)
        month_label = formatdate(month_date, "MMM YYYY")
        labels.append(month_label)

        month_start = get_first_day(month_date)
        month_end = add_months(month_start, 1)

        col = frappe.db.sql(
            """SELECT IFNULL(SUM(amount), 0) FROM `tabSubscription Payment`
               WHERE status='Success' AND payment_date >= %s AND payment_date < %s""",
            (month_start, month_end),
        )[0][0] or 0

        pend = frappe.db.sql(
            """SELECT IFNULL(SUM(amount), 0) FROM `tabSubscription Payment`
               WHERE status IN ('Pending', 'Failed')
               AND payment_date >= %s AND payment_date < %s""",
            (month_start, month_end),
        )[0][0] or 0

        collected.append(round(col, 2))
        pending.append(round(pend, 2))

    return {"labels": labels, "collected": collected, "pending": pending}


# ──────────────────────────────────────────────
#  Document Event Hooks
# ──────────────────────────────────────────────

def on_vital_signs_insert(doc, method):
    """When a Vital Signs doc is created in ERPNext Healthcare, mirror to Daily Reading."""
    # Guard: skip if a Daily Reading was already synced from this Vital Signs event
    if not doc.get("patient"):
        return

    reading = frappe.new_doc("Daily Reading")
    reading.patient = doc.patient
    reading.reading_date = doc.get("signs_date") or today()
    # Vital Signs uses bp_systolic/bp_diastolic; fall back to legacy names
    reading.bp_systolic = doc.get("bp_systolic") or doc.get("systolic")
    reading.bp_diastolic = doc.get("bp_diastolic") or doc.get("diastolic")
    # Blood sugar field is not standard on Vital Signs; read defensively
    reading.blood_sugar = doc.get("blood_sugar") or doc.get("blood_sugar_level")
    reading.source = "Clinic"
    reading.insert(ignore_permissions=True)


def on_appointment_update(doc, method):
    """When appointment status changes, create/update nurse tasks."""
    if doc.status == "Scheduled" and doc.has_value_changed("status"):
        task = frappe.new_doc("Nurse Task")
        task.task_type = "Schedule Visit"
        task.patient = doc.patient
        task.priority = "Medium"
        task.due_date = doc.appointment_date
        task.related_appointment = doc.name
        task.insert(ignore_permissions=True)
    elif doc.status == "Cancelled" and doc.has_value_changed("status"):
        # Cancel related nurse tasks
        tasks = frappe.get_all(
            "Nurse Task",
            filters={"related_appointment": doc.name, "status": ["in", ["Pending", "In Progress"]]},
            pluck="name",
        )
        for t in tasks:
            frappe.db.set_value("Nurse Task", t, "status", "Cancelled")


def on_lab_test_update(doc, method):
    """When lab test completes, create nurse follow-up task."""
    if doc.docstatus == 1 and doc.has_value_changed("docstatus"):
        task = frappe.new_doc("Nurse Task")
        task.task_type = "Lab Follow Up"
        task.patient = doc.patient
        task.priority = "Medium"
        task.due_date = today()
        task.related_lab_test = doc.name
        task.insert(ignore_permissions=True)


# ──────────────────────────────────────────────
#  Mobile App API (Section 6.2)
# ──────────────────────────────────────────────

@frappe.whitelist(allow_guest=False)
def submit_reading(patient=None, bp_systolic=None, bp_diastolic=None,
                   blood_sugar=None, sugar_unit="mg/dL", weight=None,
                   medicine_taken=None, note=None, source="App", device_id=None,
                   reference_id=None, reading_date=None, reading_time=None):
    """API endpoint for mobile app to submit a daily reading.

    ``patient`` is optional: when omitted it resolves to the logged-in user's
    own patient, so the mobile app doesn't need to pass an ID.

    ``reference_id`` is the app's local id for the reading. Re-submitting the
    same reference (offline retry, background sync) is idempotent — the
    existing Daily Reading is returned instead of creating a duplicate.
    """
    patient = patient or _my_patient_name()
    _require_patient_access(patient)
    # reference_id is a globally-unique field on Daily Reading; namespace it by
    # patient so two patients using the same app-side id can never collide.
    ref_key = f"{patient}::{reference_id}" if reference_id else None

    def _existing():
        if not ref_key:
            return None
        row = frappe.db.get_value(
            "Daily Reading", {"reference_id": ref_key},
            ["name", "risk_level", "alert_generated"], as_dict=True,
        )
        if row:
            return {
                "success": True,
                "reference_id": row.name,
                "risk_level": row.risk_level,
                "alert_generated": row.alert_generated,
                "duplicate": True,
            }
        return None

    dup = _existing()
    if dup:
        return dup

    reading = frappe.new_doc("Daily Reading")
    reading.patient = patient
    reading.bp_systolic = int(bp_systolic) if bp_systolic else None
    reading.bp_diastolic = int(bp_diastolic) if bp_diastolic else None
    reading.blood_sugar = float(blood_sugar) if blood_sugar else None
    reading.blood_sugar_unit = sugar_unit
    reading.weight = float(weight) if weight else None
    reading.medicine_taken = medicine_taken
    reading.patient_note = note
    reading.source = source
    # The app may send the reading's capture date/time (offline-synced readings
    # carry when they were actually taken). Bad values fall back to the
    # doctype's today/now defaults — never throw on them.
    if reading_date:
        try:
            reading.reading_date = getdate(reading_date)
        except Exception:
            reading.reading_date = getdate(today())
    if reading_time:
        try:
            reading.reading_time = frappe.utils.get_time(reading_time)
        except Exception:
            reading.reading_time = now_datetime().time()
    if ref_key:
        reading.reference_id = ref_key
    if device_id and frappe.db.exists("Patient Device", device_id):
        reading.source_device = device_id
    try:
        reading.insert(ignore_permissions=True)
    except (frappe.UniqueValidationError, frappe.DuplicateEntryError):
        # Raced with another submit of the same reference — return the winner.
        dup = _existing()
        if dup:
            return dup
        raise

    audit_log("Create", "Daily Reading", reading.name, "Patient submitted reading via app")

    return {
        "success": True,
        "reference_id": reading.name,
        "risk_level": reading.risk_level,
        "alert_generated": reading.alert_generated,
    }


# ──────────────────────────────────────────────
#  Mobile API — Remaining endpoints (Section 6.2)
# ──────────────────────────────────────────────

@frappe.whitelist(allow_guest=True)
def request_otp(mobile=None, channel="sms", email=None):
    """Generate and send an OTP via the chosen channel.

    - channel="email": the patient signs in with their email. The code is sent
      to that email — but only if it belongs to a registered patient (we never
      email login codes to arbitrary addresses), and login later resolves the
      patient by that email. The OTP is keyed by the email.
    - channel="sms" (default): the code is sent by SMS to the mobile; if the SMS
      send fails and the patient has an email on file, it falls back to email.

    Always reports success so we don't reveal who is registered. The OTP itself
    is never logged.
    """
    channel = (channel or "sms").strip().lower()

    if channel == "email":
        email = (email or "").strip().lower()
        if "@" not in email or "." not in email.rsplit("@", 1)[-1]:
            frappe.throw(_("A valid email is required"))
        otp = generate_otp(email)
        # Only actually deliver to a registered patient's email address.
        if frappe.db.exists("Patient", {"email": email, "status": "Active"}):
            send_otp_email(email, otp)
        frappe.logger("hiraal_otp").info("OTP request via email")
        return {"success": True, "message": "OTP sent", "channel": "email", "sent_to": _mask_email(email)}

    # ── SMS path ──
    if not mobile or len(str(mobile).strip()) < 6:
        frappe.throw(_("Valid mobile number is required"))
    mobile = str(mobile).strip()
    otp = generate_otp(mobile)
    used = "sms"
    sent_to = None
    sms_result = send_otp_sms(mobile, otp)
    if (sms_result or {}).get("status") != "sent":
        # SMS failed — fall back to the email on file, if any.
        on_file = _patient_email_for_mobile(mobile)
        if on_file and send_otp_email(on_file, otp):
            used = "email"
            sent_to = _mask_email(on_file)
    frappe.logger("hiraal_otp").info(f"OTP request {mobile}: delivered={used}")
    return {"success": True, "message": "OTP sent", "channel": used, "sent_to": sent_to}


def _patient_email_for_mobile(mobile):
    """Email on file for the Active patient matching this mobile, if any."""
    try:
        return frappe.db.get_value(
            "Patient",
            {"mobile": ["in", _mobile_candidates(mobile)], "status": "Active"},
            "email",
        )
    except Exception:
        return None


def _mask_email(email):
    """Mask an email for display: 'name@host.com' -> 'n***@host.com'."""
    try:
        local, _, domain = str(email).partition("@")
        if not domain:
            return None
        return f"{(local[:1] or '*')}***@{domain}"
    except Exception:
        return None


def send_otp_email(email, otp):
    """Send the OTP by email as an SMS fallback. Sent synchronously so a
    delivery failure surfaces immediately and we can report the real channel.
    Returns True only if the mail was handed off without error."""
    try:
        frappe.sendmail(
            recipients=[email],
            subject=_("Your Hiraal Lifecare verification code"),
            message=(
                f"<p>Your Hiraal Lifecare verification code is "
                f"<strong>{otp}</strong>.</p>"
                f"<p>It expires in 5 minutes. Do not share this code with anyone.</p>"
            ),
            now=True,
        )
        return True
    except Exception:
        frappe.log_error(title="Hiraal OTP email failed", message=frappe.get_traceback())
        return False


@frappe.whitelist(allow_guest=True)
def resend_otp(mobile=None, channel="sms", email=None):
    """Resend OTP via the chosen channel (SMS to mobile, or email login)."""
    return request_otp(mobile=mobile, channel=channel, email=email)


def _otp_step_log(step, detail=""):
    """Write a committed Error Log entry for a verify_otp step so it survives
    the request rollback that follows frappe.throw. UAT diagnostics only."""
    try:
        frappe.log_error(title=f"Hiraal OTP: {step}", message=detail)
        frappe.db.commit()
    except Exception:
        frappe.logger("hiraal_otp").exception("failed to write OTP step log")


def _mobile_candidates(mobile):
    """Common stored formats for a phone number, so patient lookup matches
    whether it was saved as +252…, 252…, 0…, or the bare national number."""
    raw = str(mobile or "").strip()
    digits = "".join(c for c in raw if c.isdigit())
    nsn = digits[3:] if digits.startswith("252") else digits
    nsn = nsn.lstrip("0")
    cands = {raw, digits}
    if nsn:
        cands.update({nsn, "0" + nsn, "252" + nsn, "+252" + nsn})
    return [c for c in cands if c]


def _provision_patient_user(patient_name, patient_label, mobile):
    """Ensure the patient has a linked login User (Website User) so OTP login
    can issue API credentials. Returns the user's email/name."""
    email = frappe.db.get_value("Patient", patient_name, "email")
    if not email:
        digits = "".join(c for c in str(mobile or "") if c.isdigit()) or patient_name
        email = f"{digits}@patient.hiraal.local"
    if not frappe.db.exists("User", email):
        user_doc = frappe.new_doc("User")
        user_doc.email = email
        user_doc.first_name = patient_label or "Patient"
        user_doc.mobile_no = str(mobile or "")
        user_doc.send_welcome_email = 0
        user_doc.user_type = "Website User"
        user_doc.insert(ignore_permissions=True)
    frappe.db.set_value("Patient", patient_name, "user_id", email)
    return email


def _issue_login(patient, contact_mobile=None):
    """Provision the patient's login User if needed and return API credentials.
    Shared by both the SMS and email verify paths."""
    user = frappe.db.get_value("Patient", patient.name, "user_id")
    if not user:
        # Auto-provision a login User so first-time OTP login works without a
        # clinic having to create a Frappe User per patient by hand.
        user = _provision_patient_user(patient.name, patient.patient_name, contact_mobile)

    user_doc = frappe.get_doc("User", user)
    api_key = user_doc.api_key
    if not api_key:
        api_key = frappe.generate_hash(length=15)
        user_doc.api_key = api_key
        user_doc.save(ignore_permissions=True)
    api_secret = frappe.utils.password.get_decrypted_password(
        "User", user, "api_secret", raise_exception=False
    )
    if not api_secret:
        api_secret = frappe.generate_hash(length=15)
        user_doc.api_secret = api_secret
        user_doc.save(ignore_permissions=True)

    return {
        "success": True,
        "patient": patient.name,
        "patient_name": patient.patient_name,
        "api_key": api_key,
        "api_secret": api_secret,
    }


@frappe.whitelist(allow_guest=True)
def verify_otp(mobile=None, otp=None, email=None, channel="sms"):
    """Verify an OTP and return the patient's API credentials.

    Supports both sign-in methods: SMS (resolve patient by mobile) and email
    (resolve patient by email). Idempotent within a short window so a duplicate
    submit returns the same credentials instead of failing.
    """
    otp = str(otp or "").strip()
    channel = (channel or "sms").strip().lower()

    if channel == "email":
        email = (email or "").strip().lower()
        result_key = f"hiraal_otp_result_email|{email}|{otp}"
        cached = frappe.cache().get_value(result_key)
        if cached:
            return cached
        if not otp_verify(email, otp):
            frappe.throw(_("Invalid or expired OTP"), frappe.AuthenticationError)
        patient = frappe.db.get_value(
            "Patient", {"email": email, "status": "Active"},
            ["name", "patient_name"], as_dict=True,
        )
        if not patient:
            frappe.throw(_("No patient is registered with this email"), frappe.AuthenticationError)
        result = _issue_login(patient, contact_mobile=None)
        frappe.cache().set_value(result_key, result, expires_in_sec=120)
        return result

    # ── SMS / mobile path ──
    mobile = str(mobile or "").strip()
    result_key = f"hiraal_otp_result_{mobile}_{otp}"
    cached_result = frappe.cache().get_value(result_key)
    if cached_result:
        return cached_result

    if not otp_verify(mobile, otp):
        frappe.throw(_("Invalid or expired OTP"), frappe.AuthenticationError)

    patient = frappe.db.get_value(
        "Patient",
        {"mobile": ["in", _mobile_candidates(mobile)], "status": "Active"},
        ["name", "patient_name"],
        as_dict=True,
    )
    if not patient:
        _otp_step_log("verify -> Patient not found", f"mobile={mobile!r}")
        frappe.throw(_("Patient not found"), frappe.AuthenticationError)

    try:
        result = _issue_login(patient, contact_mobile=mobile)
    except Exception:
        _otp_step_log("verify -> credential error", f"patient={patient.name}\n{frappe.get_traceback()}")
        raise

    frappe.cache().set_value(result_key, result, expires_in_sec=120)
    return result


@frappe.whitelist(allow_guest=True)
def self_register(full_name=None, mobile=None, otp=None, email=None,
                  sex=None, dob=None):
    """Create a new patient account from the app after verifying phone ownership
    by OTP (SMS channel).

    The account is created **Active** so the patient can sign in immediately,
    but it has no subscription — the app gates features until the patient
    subscribes to a plan and pays. Returns API credentials just like verify_otp,
    so the app logs the new patient straight in.
    """
    full_name = (full_name or "").strip()
    mobile = str(mobile or "").strip()
    otp = str(otp or "").strip()
    email = ((email or "").strip().lower()) or None
    sex = (sex or "").strip() or None
    dob = (dob or "").strip() or None

    # ── validate ──
    if len(full_name) < 2:
        frappe.throw(_("Please enter your full name"))
    if len(mobile) < 6:
        frappe.throw(_("A valid phone number is required"))
    if not sex:
        frappe.throw(_("Please select your gender"))
    if not dob:
        frappe.throw(_("Your date of birth is required"))

    # ── verify phone ownership ──
    if not otp_verify(mobile, otp):
        frappe.throw(_("Invalid or expired code"), frappe.AuthenticationError)

    # ── gender must be a real Gender record (Patient.sex is a Link) ──
    if not frappe.db.exists("Gender", sex):
        frappe.throw(_("Please select a valid gender"))

    # ── already registered? make it idempotent, don't create a duplicate ──
    existing = frappe.db.get_value(
        "Patient", {"mobile": ["in", _mobile_candidates(mobile)]},
        ["name", "patient_name", "status"], as_dict=True,
    )
    if not existing and email:
        existing = frappe.db.get_value(
            "Patient", {"email": email}, ["name", "patient_name", "status"], as_dict=True,
        )
    if existing:
        if existing.status == "Active":
            # Their number is already an account — just sign them in.
            result = _issue_login(existing, contact_mobile=mobile)
            result["already_registered"] = True
            return result
        frappe.throw(_("This number is already registered. Please contact the clinic."))

    # ── create the patient ──
    patient = frappe.new_doc("Patient")
    patient.first_name = full_name
    patient.patient_name = full_name
    patient.sex = sex
    patient.dob = dob
    patient.mobile = mobile
    if email:
        patient.email = email
    patient.status = "Active"
    patient.insert(ignore_permissions=True)
    frappe.db.commit()

    audit_log("Create", "Patient", patient.name, "Self-registered via app")

    result = _issue_login(patient, contact_mobile=mobile)
    result["new_account"] = True
    return result


def _has_active_subscription(patient):
    """True when the patient may use paid app features (Active, including trial)."""
    from hiraal_emr.services.subscription_catalog import has_active_subscription

    return has_active_subscription(patient)


@frappe.whitelist()
def get_my_patient():
    """Return the Patient profile linked to the currently authenticated user.

    Used by the mobile app after OTP login. Scoped to the caller's own record
    via the session user, so it needs no doctype read permission and isn't
    affected by how the mobile number was formatted/stored.
    """
    user = frappe.session.user
    if not user or user == "Guest":
        frappe.throw(_("Not authenticated"), frappe.AuthenticationError)

    name = frappe.db.get_value("Patient", {"user_id": user}, "name")
    if not name:
        frappe.throw(_("No patient linked to this account"), frappe.AuthenticationError)

    data = frappe.get_doc("Patient", name).as_dict()
    # Feature gate for the app: whether this patient may use paid features.
    data["subscription_active"] = _has_active_subscription(name)
    return data


def _my_patient_name():
    """Resolve the Patient linked to the currently authenticated user."""
    user = frappe.session.user
    if not user or user == "Guest":
        frappe.throw(_("Not authenticated"), frappe.AuthenticationError)
    name = frappe.db.get_value("Patient", {"user_id": user}, "name")
    if not name:
        frappe.throw(_("No patient linked to this account"), frappe.AuthenticationError)
    return name


def _safe_get_all(doctype, **kwargs):
    """get_all that degrades to [] instead of 500-ing a screen if a field or
    doctype is unavailable in this environment."""
    try:
        return frappe.get_all(doctype, **kwargs)
    except Exception:
        frappe.logger("hiraal_api").exception(f"get_all failed for {doctype}")
        return []


@frappe.whitelist()
def export_my_data():
    """Assemble everything the app's "Export My Data" feature needs: the
    patient's own profile, readings, medicine orders, subscription and payment
    history. Patient-scoped — only the caller's own records. The app formats
    this into a shareable report."""
    patient = _my_patient_name()
    p = frappe.db.get_value(
        "Patient",
        patient,
        ["patient_name", "mobile", "email", "sex", "dob", "status",
         "blood_group"],
        as_dict=True,
    ) or {}

    readings = _safe_get_all(
        "Daily Reading",
        filters={"patient": patient},
        fields=["reading_date", "reading_time", "bp_systolic", "bp_diastolic",
                "blood_sugar", "blood_sugar_unit", "weight", "medicine_taken",
                "risk_level", "source", "patient_note"],
        order_by="reading_date desc, reading_time desc",
        limit_page_length=1000,
    )

    orders = _safe_get_all(
        "Medicine Request",
        filters={"patient": patient},
        fields=["name", "creation", "status", "payment_status", "total",
                "delivery_fee", "tax", "payment_reference"],
        order_by="creation desc",
        limit_page_length=200,
    )

    sub = frappe.db.get_value(
        "Care Subscription",
        {"patient": patient},
        ["plan", "monthly_fee", "status", "start_date", "next_billing_date",
         "last_payment_date", "total_collected"],
        as_dict=True, order_by="creation desc",
    )

    payments = _safe_get_all(
        "Subscription Payment",
        filters={"patient": patient},
        fields=["amount", "payment_date", "payment_method", "status", "reference_id"],
        order_by="payment_date desc",
        limit_page_length=200,
    )

    return {
        "generated_at": _to_utc_iso(now_datetime()),
        "patient": p,
        "readings": readings,
        "medicine_orders": orders,
        "subscription": sub,
        "subscription_payments": payments,
        "counts": {
            "readings": len(readings),
            "medicine_orders": len(orders),
            "subscription_payments": len(payments),
        },
    }


@frappe.whitelist()
def get_my_records():
    """Medical history (Patient Encounters) for the logged-in patient."""
    patient = _my_patient_name()
    return _safe_get_all(
        "Patient Encounter",
        filters={"patient": patient},
        fields=["name", "encounter_date", "encounter_type",
                "practitioner", "practitioner_name", "medical_department"],
        order_by="encounter_date desc",
        limit_page_length=50,
    )


@frappe.whitelist()
def get_my_addresses():
    """Addresses linked to the logged-in patient."""
    patient = _my_patient_name()
    links = _safe_get_all(
        "Dynamic Link",
        filters={"link_doctype": "Patient", "link_name": patient, "parenttype": "Address"},
        fields=["parent"],
    )
    out = []
    for link in links:
        try:
            out.append(frappe.get_doc("Address", link["parent"]).as_dict())
        except Exception:
            pass
    return out


@frappe.whitelist()
def get_my_readings(limit=60):
    """Daily Reading history for the logged-in patient."""
    patient = _my_patient_name()
    return _safe_get_all(
        "Daily Reading",
        filters={"patient": patient},
        fields=["name", "reference_id", "reading_date", "reading_time",
                "bp_systolic", "bp_diastolic", "blood_sugar", "blood_sugar_unit", "weight",
                "medicine_taken", "patient_note", "source", "sync_status", "risk_level"],
        order_by="reading_date desc",
        limit_page_length=int(limit or 60),
    )


@frappe.whitelist()
def get_my_activity_counts():
    """Counts for the profile activity cards."""
    patient = _my_patient_name()
    today_d = today()
    appointments = frappe.db.count(
        "Patient Appointment",
        # Same "upcoming" definition as get_my_appointments: confirmed
        # appointments leave "Open" (e.g. become "Scheduled"), so filtering on
        # "Open" alone undercounts. Count anything not Closed/Cancelled.
        {"patient": patient, "appointment_date": [">=", today_d],
         "status": ["not in", ["Closed", "Cancelled"]]},
    )
    lab_tests = frappe.db.count("Lab Test", {"patient": patient, "docstatus": 0})
    orders = 0
    try:
        # "Active" = still moving through the lifecycle. The old filter used
        # status="Pending", which isn't a Medicine Request status at all
        # (Received/Under Review/Awaiting Payment/Paid/Preparing/Out for
        # Delivery/Delivered/Cancelled), so the card always showed 0.
        orders = frappe.db.count(
            "Medicine Request",
            {"patient": patient, "status": ["not in", ["Delivered", "Cancelled"]]},
        )
    except Exception:
        pass
    return {
        "upcoming_appointments": appointments,
        "scheduled_lab_tests": lab_tests,
        "active_orders": orders,
    }


def _to_utc_iso(dt):
    """Convert a Frappe (site-timezone, naive) datetime to a UTC ISO-8601 string
    ending in 'Z'. Mobile clients can then parse it as an absolute instant and
    show correct relative times ("just now") regardless of the device timezone.
    Falls back to the original value on any error."""
    if not dt:
        return dt
    try:
        import pytz
        from frappe.utils import get_datetime, get_system_timezone
        site_tz = pytz.timezone(get_system_timezone())
        naive = get_datetime(dt)
        return site_tz.localize(naive).astimezone(pytz.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    except Exception:
        return str(dt)


@frappe.whitelist()
def get_my_notifications(limit=50):
    """Notifications for the logged-in patient's user account."""
    rows = _safe_get_all(
        "Notification Log",
        filters={"for_user": frappe.session.user},
        fields=["name", "subject", "email_content", "type", "creation", "read",
                "document_type", "document_name"],
        order_by="creation desc",
        limit_page_length=int(limit or 50),
    )
    for r in rows:
        r["creation"] = _to_utc_iso(r.get("creation"))
    return rows


@frappe.whitelist()
def mark_my_notification_read(name):
    """Mark one of the caller's own notifications as read."""
    if frappe.db.get_value("Notification Log", name, "for_user") != frappe.session.user:
        frappe.throw(_("Not permitted"), frappe.PermissionError)
    frappe.db.set_value("Notification Log", name, "read", 1)
    frappe.db.commit()
    return {"success": True}


@frappe.whitelist()
def get_doctors():
    """Healthcare practitioners for the booking screen.

    No status filter (different setups use different status values), with a
    bare-fields fallback so a non-standard custom field can't blank the list.
    """
    docs = _safe_get_all(
        "Healthcare Practitioner",
        fields=["name", "practitioner_name", "department"],
        order_by="practitioner_name asc",
        limit_page_length=200,
    )
    if not docs:
        docs = _safe_get_all(
            "Healthcare Practitioner",
            fields=["name", "practitioner_name"],
            limit_page_length=200,
        )
    return docs


@frappe.whitelist()
def get_care_stations():
    """Active Care Stations for in-person booking in the mobile app.

    Staff maintain these under Hiraal EMR → Care Stations. Only active rows
    are returned, ordered for display. Lat/lng are included when set so the
    app can later sort by distance.
    """
    if not frappe.db.exists("DocType", "Care Station"):
        return []
    return _safe_get_all(
        "Care Station",
        filters={"is_active": 1},
        fields=[
            "name",
            "station_name",
            "address",
            "city",
            "phone",
            "display_order",
            "latitude",
            "longitude",
        ],
        order_by="display_order asc, station_name asc",
        limit_page_length=200,
        ignore_permissions=True,
    )


@frappe.whitelist()
def get_lab_test_templates():
    """Enabled lab test templates for the lab test screen."""
    return _safe_get_all(
        "Lab Test Template",
        filters={"disabled": 0},
        fields=["name", "lab_test_name", "lab_test_rate", "department"],
        order_by="lab_test_name asc",
        limit_page_length=100,
    )


@frappe.whitelist()
def get_my_lab_tests(limit=20):
    """The logged-in patient's lab tests, newest first — backs the app's
    'My Lab Tests' screen (where the profile activity card leads)."""
    patient = _my_patient_name()
    return _safe_get_all(
        "Lab Test",
        filters={"patient": patient},
        fields=["name", "template", "status", "creation", "result_date"],
        order_by="creation desc",
        limit_page_length=int(limit or 20),
    )


# Lab tests a patient may still cancel themselves — once the sample is
# collected (or the test is done/cancelled), only the lab can touch it.
_LAB_TEST_CANCELLABLE = {"Draft", "Approved", "Printed"}


@frappe.whitelist()
def cancel_my_lab_test(name):
    """Let a patient cancel their own lab test while it hasn't been
    collected or completed yet."""
    patient = _my_patient_name()
    owner = frappe.db.get_value("Lab Test", name, "patient")
    if owner != patient:
        frappe.throw(_("Not permitted"), frappe.PermissionError)
    status = frappe.db.get_value("Lab Test", name, "status")
    if status not in _LAB_TEST_CANCELLABLE:
        frappe.throw(_("This lab test can no longer be cancelled"))
    doc = frappe.get_doc("Lab Test", name)
    doc.status = "Cancelled"
    doc.save(ignore_permissions=True)
    frappe.db.commit()
    audit_log("Update", "Lab Test", name, "Patient cancelled lab test via app")
    return {"success": True, "status": "Cancelled"}


@frappe.whitelist()
def add_my_address(label=None, address_type="Personal", address_line1=None,
                   city=None, is_primary=0):
    """Add an address for the logged-in patient and link it to them."""
    patient = _my_patient_name()
    doc = frappe.new_doc("Address")
    doc.address_title = label or patient
    doc.address_type = address_type or "Personal"
    doc.address_line1 = address_line1 or "-"
    doc.city = city or "-"
    try:
        doc.is_primary_address = 1 if int(is_primary or 0) else 0
    except Exception:
        doc.is_primary_address = 0
    doc.append("links", {"link_doctype": "Patient", "link_name": patient})
    doc.insert(ignore_permissions=True)
    frappe.db.commit()
    return doc.as_dict()


@frappe.whitelist()
def delete_my_address(name):
    """Delete one of the logged-in patient's own addresses."""
    patient = _my_patient_name()
    owned = frappe.db.exists("Dynamic Link", {
        "parent": name, "parenttype": "Address",
        "link_doctype": "Patient", "link_name": patient,
    })
    if not owned:
        frappe.throw(_("Not permitted"), frappe.PermissionError)
    frappe.delete_doc("Address", name, ignore_permissions=True)
    frappe.db.commit()
    return {"success": True}


@frappe.whitelist(allow_guest=False)
def biometric_token():
    """Exchange a valid biometric session for a fresh JWT/session token."""
    user = frappe.session.user
    if user == "Guest":
        frappe.throw(_("Not authenticated"), frappe.AuthenticationError)

    # Verify that a biometric challenge was recently completed for this user
    bio_key = f"hiraal_biometric:{user}"
    biometric_verified = frappe.cache().get_value(bio_key)
    if not biometric_verified:
        frappe.throw(_("Biometric verification required"), frappe.AuthenticationError)

    # Consume the one-time biometric verification
    frappe.cache().delete_value(bio_key)

    return {
        "success": True,
        "user": user,
        "sid": frappe.session.sid,
        "csrf_token": frappe.sessions.get_csrf_token(),
    }


@frappe.whitelist(allow_guest=False)
def sync_readings_batch(patient, readings, device_id=None):
    """Bulk sync offline readings from mobile app."""
    _require_patient_access(patient)
    import json
    if isinstance(readings, str):
        readings = json.loads(readings)

    results = []
    for r in readings:
        try:
            doc = frappe.new_doc("Daily Reading")
            doc.patient = patient
            doc.reading_date = r.get("date", today())
            doc.reading_time = r.get("time")
            doc.bp_systolic = int(r["bp_systolic"]) if r.get("bp_systolic") else None
            doc.bp_diastolic = int(r["bp_diastolic"]) if r.get("bp_diastolic") else None
            doc.blood_sugar = float(r["blood_sugar"]) if r.get("blood_sugar") else None
            doc.blood_sugar_unit = r.get("sugar_unit", "mg/dL")
            doc.medicine_taken = r.get("medicine_taken")
            doc.patient_note = r.get("note")
            doc.source = r.get("source", "App")
            if device_id and frappe.db.exists("Patient Device", device_id):
                doc.source_device = device_id
            doc.insert(ignore_permissions=True)
            results.append({"ref": r.get("local_id"), "name": doc.name, "status": "ok"})
        except Exception as e:
            results.append({"ref": r.get("local_id"), "status": "error", "error": str(e)})

    frappe.db.commit()
    return {"success": True, "synced": len([r for r in results if r["status"] == "ok"]), "results": results}


@frappe.whitelist(allow_guest=False)
def pair_device(patient, device_id, device_type, device_name=None,
                manufacturer=None, model=None, serial_number=None):
    """Register a device pairing for a patient."""
    _require_patient_access(patient)
    existing = frappe.db.exists("Patient Device", {"device_id": device_id})
    if existing:
        dev = frappe.get_doc("Patient Device", existing)
        dev.patient = patient
        dev.status = "Online"
        dev.assigned_on = today()
        dev.save(ignore_permissions=True)
    else:
        dev = frappe.new_doc("Patient Device")
        dev.device_id = device_id
        dev.device_name = device_name or f"{device_type} - {device_id[:8]}"
        dev.device_type = device_type
        dev.patient = patient
        dev.manufacturer = manufacturer
        dev.model = model
        dev.serial_number = serial_number
        dev.status = "Online"
        dev.assigned_on = today()
        dev.insert(ignore_permissions=True)

    return {"success": True, "device": dev.name, "status": dev.status}


def _telemed_room_url(appointment_name):
    """A unique, hard-to-guess Jitsi Meet room URL for a video visit. The same
    URL is shared by patient and clinician so both land in the same room."""
    token = frappe.generate_hash(length=12)
    safe = "".join(c for c in str(appointment_name) if c.isalnum())
    return f"https://meet.jit.si/HiraalCare-{safe}-{token}"


@frappe.whitelist(allow_guest=False)
def book_appointment(patient, practitioner, appointment_date,
                     appointment_time=None, appointment_type="Chronic Care Follow Up",
                     notes=None, is_video=0, care_station=None):
    """Book a patient appointment from the mobile app.

    ``notes`` carries the patient's reason for the visit so the clinician sees
    why the appointment was requested (previously collected in the app but
    dropped on the way to the server). When ``is_video`` is set, a Telemedicine
    Session with a Jitsi meeting link is created and the link is returned so the
    app can offer a "Join Video Call" button.

    ``care_station`` is the Care Station name for in-person visits (nearest
    clinic location). Stored on the appointment when a custom link field exists,
    and always appended into notes for desk visibility.
    """
    _require_patient_access(patient)

    station_label = None
    if care_station and not int(is_video or 0):
        station = frappe.db.get_value(
            "Care Station",
            {"name": care_station, "is_active": 1},
            ["name", "station_name", "address", "city"],
            as_dict=True,
        )
        if not station:
            frappe.throw(_("Please choose a valid care station for the in-person visit."))
        station_label = station.station_name or station.name
        if station.city:
            station_label = f"{station_label} — {station.city}"
        if station.address:
            station_label = f"{station_label} ({station.address})"

    appt = frappe.new_doc("Patient Appointment")
    meta = frappe.get_meta("Patient Appointment")
    appt.patient = patient
    appt.practitioner = practitioner
    # Frappe Healthcare requires "Appointment For" (Visit Details) — we always
    # book against a practitioner.
    if meta.has_field("appointment_for"):
        appt.appointment_for = "Practitioner"
    appt.appointment_date = appointment_date
    appt.appointment_time = appointment_time
    appt.appointment_type = appointment_type
    if care_station and meta.has_field("custom_care_station"):
        appt.custom_care_station = care_station

    note_parts = []
    if notes:
        note_parts.append(str(notes).strip())
    if station_label:
        note_parts.append(_("Care station: {0}").format(station_label))
    combined_notes = "\n\n".join(note_parts) if note_parts else None
    if combined_notes:
        if meta.has_field("notes"):
            appt.notes = combined_notes
        elif meta.has_field("custom_reason"):
            appt.custom_reason = combined_notes
    appt.insert(ignore_permissions=True)

    meeting_url = None
    if int(is_video or 0):
        # Video visit — provision a telemedicine session with a join link.
        meeting_url = _telemed_room_url(appt.name)
        try:
            session = frappe.new_doc("Telemedicine Session")
            session.patient = patient
            session.practitioner = practitioner
            session.appointment = appt.name
            session.start_time = f"{appointment_date} {appointment_time or '00:00:00'}"
            session.meeting_url = meeting_url
            session.session_status = "Scheduled"
            session.insert(ignore_permissions=True)
        except Exception:
            frappe.logger("hiraal_telemed").exception("telemedicine session create failed")

    return {
        "success": True,
        "appointment": appt.name,
        "status": appt.status,
        "meeting_url": meeting_url,
        "care_station": care_station,
    }


@frappe.whitelist()
def get_my_appointments():
    """Upcoming Patient Appointments for the logged-in patient, soonest first
    (today onward, not Closed/Cancelled) — powers the app's 'Next appointment'
    card on the home screen."""
    patient = _my_patient_name()
    return _safe_get_all(
        "Patient Appointment",
        filters={
            "patient": patient,
            "appointment_date": [">=", today()],
            "status": ["not in", ("Closed", "Cancelled")],
        },
        fields=["name", "practitioner", "practitioner_name",
                "appointment_date", "appointment_time", "status",
                "appointment_type"],
        order_by="appointment_date asc, appointment_time asc",
        limit_page_length=10,
    )


@frappe.whitelist()
def get_my_telemedicine_sessions(limit=20):
    """Video (telemedicine) sessions for the logged-in patient, with their
    join URLs and status — powers the app's 'Video Visits' screen."""
    patient = _my_patient_name()
    return _safe_get_all(
        "Telemedicine Session",
        filters={"patient": patient},
        fields=["name", "appointment", "practitioner", "practitioner_name",
                "session_status", "start_time", "end_time", "meeting_url",
                "duration_minutes", "notes"],
        order_by="start_time desc",
        limit_page_length=int(limit or 20),
    )


@frappe.whitelist()
def join_my_telemedicine_session(name):
    """Called when the patient taps 'Join' on a video visit. Marks the session
    In Progress and alerts the assigned doctor (in-app immediately, SMS in the
    background) so they know to join. Returns the meeting link."""
    patient = _my_patient_name()
    sess = frappe.db.get_value(
        "Telemedicine Session", name,
        ["patient", "practitioner", "meeting_url", "session_status"],
        as_dict=True,
    )
    if not sess or sess.patient != patient:
        frappe.throw(_("Not permitted"), frappe.PermissionError)

    # Only the first join (from a not-yet-started state) advances the status and
    # alerts the doctor — so repeated taps / a rejoin don't spam them.
    first_join = sess.session_status in (None, "", "Scheduled", "No Show")
    if first_join:
        try:
            # Stamp the actual call start so duration is accurate on completion.
            frappe.db.set_value("Telemedicine Session", name, {
                "session_status": "In Progress",
                "start_time": now_datetime(),
            })
            frappe.db.commit()
        except Exception:
            frappe.logger("hiraal_telemed").exception("set In Progress failed")

        patient_label = frappe.db.get_value("Patient", patient, "patient_name") or patient
        message = (
            f"Hiraal Lifecare: {patient_label} has joined the video visit and is "
            f"waiting for you. Join: {sess.meeting_url or ''}"
        )
        _notify_practitioner(
            sess.practitioner,
            subject=f"Patient waiting: {patient_label}",
            message=message,
        )

    return {"success": True, "meeting_url": sess.meeting_url, "status": "In Progress"}


@frappe.whitelist()
def complete_telemedicine_session(name):
    """Mark a video visit finished: set Completed, stamp the end time, and
    compute the call duration from the start time. Either clinic staff or the
    session's own patient may end the call."""
    sess = frappe.db.get_value(
        "Telemedicine Session", name,
        ["start_time", "session_status", "patient"], as_dict=True,
    )
    if not sess:
        frappe.throw(_("Session not found"))

    allowed = _is_clinical_user()
    if not allowed:
        try:
            allowed = sess.patient and sess.patient == _my_patient_name()
        except Exception:
            allowed = False
    if not allowed:
        frappe.throw(_("Not permitted"), frappe.PermissionError)

    if sess.session_status in ("Completed", "Cancelled"):
        return {"success": True, "status": sess.session_status}

    end = now_datetime()
    values = {"session_status": "Completed", "end_time": end}
    if sess.start_time:
        mins = int(round((end - get_datetime(sess.start_time)).total_seconds() / 60.0))
        if 0 <= mins <= 600:  # sanity cap (10h)
            values["duration_minutes"] = mins
    frappe.db.set_value("Telemedicine Session", name, values)
    frappe.db.commit()
    return {
        "success": True,
        "status": "Completed",
        "duration_minutes": values.get("duration_minutes"),
    }


def auto_close_stale_telemedicine():
    """Scheduled safety net: close video sessions left In Progress for too long
    (the clinician forgot to end them). Marks Completed + stamps the end time
    but does not invent a duration."""
    cutoff = add_to_date(now_datetime(), hours=-3)
    stale = frappe.get_all(
        "Telemedicine Session",
        filters={"session_status": "In Progress", "start_time": ["<", cutoff]},
        pluck="name",
    )
    for sname in stale:
        try:
            frappe.db.set_value(
                "Telemedicine Session", sname,
                {"session_status": "Completed", "end_time": now_datetime()},
            )
        except Exception:
            frappe.logger("hiraal_telemed").exception("auto-close failed")
    if stale:
        frappe.db.commit()


def _notify_practitioner(practitioner, subject, message):
    """Best-effort alert to a Healthcare Practitioner: an in-app Notification
    Log now, plus an SMS enqueued in the background so a slow gateway never
    delays the patient joining the call. Never raises."""
    if not practitioner:
        return
    info = frappe.db.get_value(
        "Healthcare Practitioner", practitioner,
        ["user_id", "mobile_phone"], as_dict=True,
    ) or {}
    user = info.get("user_id")
    mobile = info.get("mobile_phone")
    if not mobile and user:
        mobile = frappe.db.get_value("User", user, "mobile_no")

    if user:
        try:
            note = frappe.new_doc("Notification Log")
            note.subject = subject
            note.email_content = message
            note.for_user = user
            note.type = "Alert"
            note.document_type = "Telemedicine Session"
            note.insert(ignore_permissions=True)
            frappe.db.commit()
        except Exception:
            frappe.logger("hiraal_telemed").exception("practitioner notification log failed")
        send_push_to_user(user, subject, message, {"type": "telemedicine"})

    if mobile:
        try:
            frappe.enqueue(
                "hiraal_emr.api._send_sms_bg",
                queue="short",
                mobile=mobile,
                message=message,
            )
        except Exception:
            frappe.logger("hiraal_telemed").exception("practitioner SMS enqueue failed")


def _send_sms_bg(mobile, message):
    """Background SMS send for non-latency-critical alerts."""
    try:
        send_sms(mobile, message)
    except Exception:
        frappe.logger("hiraal_telemed").exception("background SMS failed")


# ──────────────────────────────────────────────
#  Push notifications (Firebase Cloud Messaging, HTTP v1)
# ──────────────────────────────────────────────

@frappe.whitelist()
def register_push_token(token, platform="Android"):
    """Register/refresh this device's FCM token for the logged-in patient so we
    can push to it. Called by the app after login and on token refresh."""
    user = frappe.session.user
    if not user or user == "Guest":
        frappe.throw(_("Not authenticated"), frappe.AuthenticationError)
    token = (token or "").strip()
    if not token:
        return {"success": False}
    if not frappe.db.exists("DocType", "Hiraal Push Token"):
        return {"success": False, "reason": "push not configured"}

    import hashlib
    key = hashlib.md5(token.encode("utf-8")).hexdigest()
    values = {
        "user": user,
        "patient": frappe.db.get_value("Patient", {"user_id": user}, "name"),
        "platform": platform or "Android",
        "enabled": 1,
        "token": token,
        "last_seen": now_datetime(),
    }
    if frappe.db.exists("Hiraal Push Token", key):
        doc = frappe.get_doc("Hiraal Push Token", key)
        doc.update(values)
        doc.save(ignore_permissions=True)
    else:
        doc = frappe.new_doc("Hiraal Push Token")
        doc.token_key = key
        doc.update(values)
        doc.insert(ignore_permissions=True)
    frappe.db.commit()
    return {"success": True}


@frappe.whitelist()
def unregister_my_push_token(token=None):
    """Disable this user's push tokens (all of them, or just ``token``).
    Called by the app on logout so a shared/handed-over phone stops receiving
    the previous patient's health notifications."""
    user = frappe.session.user
    if not user or user == "Guest":
        return {"success": False}
    if not frappe.db.exists("DocType", "Hiraal Push Token"):
        return {"success": True}
    filters = {"user": user}
    if token:
        filters["token"] = token
    for name in frappe.get_all("Hiraal Push Token", filters=filters, pluck="name"):
        frappe.db.set_value("Hiraal Push Token", name, "enabled", 0)
    frappe.db.commit()
    return {"success": True}


def send_push_to_user(user, title, body, data=None):
    """Best-effort FCM push to all of a user's registered devices. A no-op when
    FCM isn't configured yet. Never raises — and never blocks the caller's save
    (e.g. a pharmacist changing an order status) even if push isn't set up."""
    if not user:
        return
    # Guard: if the push-token doctype isn't installed, querying it would emit a
    # "DocType ... not found" message to the user. Skip silently instead.
    if not frappe.db.exists("DocType", "Hiraal Push Token"):
        return
    try:
        tokens = frappe.get_all(
            "Hiraal Push Token", filters={"user": user, "enabled": 1}, pluck="token"
        )
        tokens = [t for t in tokens if t]
        if tokens:
            _fcm_send(tokens, title, body, data or {})
    except Exception:
        frappe.logger("hiraal_push").exception("send_push_to_user failed")


def _fcm_access_token():
    """OAuth2 access token + project id for FCM HTTP v1, from the service-account
    JSON whose path is set in site_config.json as 'hiraal_fcm_service_account'."""
    path = frappe.conf.get("hiraal_fcm_service_account")
    if not path:
        return None, None
    try:
        from google.oauth2 import service_account
        from google.auth.transport.requests import Request
        creds = service_account.Credentials.from_service_account_file(
            path, scopes=["https://www.googleapis.com/auth/firebase.messaging"]
        )
        creds.refresh(Request())
        return creds.token, creds.project_id
    except Exception:
        frappe.logger("hiraal_push").exception(
            "FCM access token failed (install google-auth + set hiraal_fcm_service_account)"
        )
        return None, None


def _fcm_send(tokens, title, body, data):
    import requests
    access_token, project_id = _fcm_access_token()
    if not access_token or not project_id:
        return  # FCM not configured — silently skip.
    url = f"https://fcm.googleapis.com/v1/projects/{project_id}/messages:send"
    headers = {"Authorization": f"Bearer {access_token}", "Content-Type": "application/json"}
    str_data = {str(k): str(v) for k, v in (data or {}).items()}
    for token in tokens:
        payload = {
            "message": {
                "token": token,
                "notification": {"title": title, "body": body},
                "data": str_data,
                "android": {"priority": "high"},
            }
        }
        try:
            r = requests.post(url, headers=headers, json=payload, timeout=10)
            if r.status_code in (400, 403, 404) and "not-registered" in r.text.lower().replace("_", "-"):
                # Stale token — stop pushing to it.
                frappe.db.set_value("Hiraal Push Token", {"token": token}, "enabled", 0)
        except Exception:
            frappe.logger("hiraal_push").exception("FCM send failed")


@frappe.whitelist()
def fcm_diagnostics(user=None, send_test=0):
    """Admin-only push diagnostics — pinpoints which link in the FCM chain is
    broken. Check, in order: google-auth installed, service account configured,
    OAuth access token obtainable, the push-token doctype migrated, and how many
    device tokens are registered for ``user``. With send_test=1 it fires a real
    test push to the first token and returns FCM's raw HTTP response.

    Call as Administrator, e.g. in the browser:
      /api/method/hiraal_emr.api.fcm_diagnostics?user=<login-email>&send_test=1
    """
    import os
    if "System Manager" not in frappe.get_roles():
        frappe.throw(_("Not permitted"), frappe.PermissionError)

    out = {}

    # 1) google-auth library present?
    try:
        from google.oauth2 import service_account  # noqa: F401
        from google.auth.transport.requests import Request  # noqa: F401
        out["google_auth_installed"] = True
    except Exception as e:
        out["google_auth_installed"] = False
        out["google_auth_error"] = str(e)

    # 2) service-account JSON configured + present on disk?
    path = frappe.conf.get("hiraal_fcm_service_account")
    out["service_account_path_set"] = bool(path)
    out["service_account_file_exists"] = bool(path and os.path.exists(path))

    # 3) can we actually mint an OAuth token + read the project id?
    access_token, project_id = _fcm_access_token()
    out["access_token_ok"] = bool(access_token)
    out["project_id"] = project_id

    # 4) is the push-token doctype migrated, and how many devices are registered?
    out["push_token_doctype_exists"] = bool(frappe.db.exists("DocType", "Hiraal Push Token"))
    target = user or frappe.session.user
    out["user"] = target
    tokens = []
    if out["push_token_doctype_exists"]:
        try:
            tokens = frappe.get_all(
                "Hiraal Push Token",
                filters={"user": target, "enabled": 1}, pluck="token",
            )
        except Exception as e:
            out["token_query_error"] = str(e)
    out["registered_token_count"] = len(tokens)

    # 5) optional: fire one real test push and report FCM's response verbatim.
    if int(send_test or 0) and tokens and access_token and project_id:
        import requests
        url = f"https://fcm.googleapis.com/v1/projects/{project_id}/messages:send"
        headers = {"Authorization": f"Bearer {access_token}", "Content-Type": "application/json"}
        payload = {"message": {
            "token": tokens[0],
            "notification": {"title": "Hiraal Lifecare", "body": "Push test ✅"},
            "android": {"priority": "high"},
        }}
        try:
            r = requests.post(url, headers=headers, json=payload, timeout=10)
            out["test_send_status"] = r.status_code
            out["test_send_body"] = r.text[:600]
        except Exception as e:
            out["test_send_error"] = str(e)
    elif int(send_test or 0):
        out["test_send_skipped"] = "Missing a token, access token, or project id (see above)."

    return out


_CLINICAL_ROLES = {
    "System Manager", "Chronic Care Admin", "Chronic Care Doctor",
    "Chronic Care Nurse", "Healthcare Practitioner",
}


def _is_clinical_user():
    """True for clinic staff/clinicians; False for patient Website Users."""
    return bool(set(frappe.get_roles()) & _CLINICAL_ROLES)


def _require_clinical():
    """Gate desk/clinic endpoints: clinic-wide data and actions must never be
    reachable by a patient Website User."""
    if not _is_clinical_user():
        frappe.throw(_("Not permitted"), frappe.PermissionError)


def _require_patient_access(patient):
    """Clinic staff may act on any patient; a patient user only on themselves."""
    if _is_clinical_user():
        return
    if not patient or patient != _my_patient_name():
        frappe.throw(_("Not permitted"), frappe.PermissionError)


@frappe.whitelist()
def get_waiting_telemedicine_sessions():
    """Clinic-side feed for the Telemedicine Waiting Room desk page: video
    visits needing a clinician now — every session currently In Progress (a
    patient has joined and is waiting) plus today's still-Scheduled visits.

    Gated to clinical roles so a patient Website User can't read the clinic-wide
    list of who's waiting."""
    if not _is_clinical_user():
        return []

    rows = _safe_get_all(
        "Telemedicine Session",
        filters={"session_status": ["in", ["In Progress", "Scheduled"]]},
        fields=["name", "patient", "patient_name", "practitioner",
                "practitioner_name", "session_status", "start_time", "meeting_url"],
        order_by="start_time asc",
        limit_page_length=100,
    )

    today_str = str(today())
    out = [
        r for r in rows
        if r.get("session_status") == "In Progress"
        or (r.get("session_status") == "Scheduled"
            and str(r.get("start_time") or "").startswith(today_str))
    ]
    # Patients who've actually joined (In Progress) float to the top.
    out.sort(key=lambda r: 0 if r.get("session_status") == "In Progress" else 1)
    return out


@frappe.whitelist(allow_guest=False)
def request_lab_test(patient, template, practitioner=None, note=None):
    """Request a lab test from the mobile app."""
    _require_patient_access(patient)
    lab = frappe.new_doc("Lab Test")
    lab.patient = patient
    lab.template = template
    # patient_sex is mandatory on Lab Test; populate it from the Patient record
    # (app-created patients may predate sex collection, so fall back safely).
    lab.patient_sex = frappe.db.get_value("Patient", patient, "sex") or "Other"
    if practitioner:
        lab.practitioner = practitioner
    if note:
        # custom_note may be a custom field; set it only if defined on the doctype
        meta = frappe.get_meta("Lab Test")
        if meta.has_field("custom_note"):
            lab.custom_note = note
        elif meta.has_field("description"):
            lab.description = note
    lab.insert(ignore_permissions=True)

    return {"success": True, "lab_test": lab.name}


@frappe.whitelist(allow_guest=False)
def order_medicine(patient=None, items=None, delivery_address=None,
                   payment_method=None, priority=None, note=None):
    """Place a medicine delivery order from the mobile app.

    The patient uploads a prescription image (see ``attach_my_prescription``);
    the pharmacy then reviews it, fills in the medicines + pricing, and moves the
    order through the lifecycle. ``items`` stays optional/legacy — a fresh
    prescription order normally starts with no lines and status "Received".

    ``patient`` is optional; when omitted it resolves to the logged-in user's
    own patient so the app never has to pass an ID it might not have.
    """
    import json
    patient = patient or _my_patient_name()
    _require_patient_access(patient)
    if isinstance(items, str):
        items = json.loads(items or "[]")
    items = items or []

    order = frappe.new_doc("Medicine Request")
    order.patient = patient
    order.delivery_address = delivery_address
    order.delivery_type = "Delivery" if delivery_address else "Pickup"
    order.payment_method = payment_method or "Zaad"
    order.payment_status = "Unpaid"
    order.priority = priority or "Normal"
    order.status = "Received"
    if note:
        order.pharmacist_note = note

    count = 0
    for item in items:
        name = (item.get("name") or item.get("medicine_name") or "").strip()
        if not name:
            continue
        order.append("medicines", {
            "medicine_name": name,
            "quantity": int(item.get("quantity", 1) or 1),
            "dosage": item.get("dosage"),
        })
        count += 1
    order.total_items = count

    order.insert(ignore_permissions=True)
    audit_log("Create", "Medicine Request", order.name, "Patient ordered medicine via app")
    return {"success": True, "order": order.name, "status": order.status}


def _my_order_or_throw(order):
    """Resolve a Medicine Request the logged-in patient owns, or 403."""
    patient = _my_patient_name()
    owner = frappe.db.get_value("Medicine Request", order, "patient")
    if not owner:
        frappe.throw(_("Order not found"), frappe.DoesNotExistError)
    if owner != patient:
        frappe.throw(_("Not permitted"), frappe.PermissionError)
    return patient


@frappe.whitelist()
def attach_my_prescription(order, filename, content_base64):
    """Attach a prescription image (base64) to the patient's own order and set
    it as the order's prescription. Used right after order_medicine."""
    import base64
    _my_order_or_throw(order)
    try:
        content = base64.b64decode(content_base64)
    except Exception:
        frappe.throw(_("Could not read the prescription image"))

    safe_name = (filename or "prescription.jpg").split("/")[-1].split("\\")[-1]
    file_doc = frappe.get_doc({
        "doctype": "File",
        "file_name": f"{order}-{safe_name}",
        "attached_to_doctype": "Medicine Request",
        "attached_to_name": order,
        "is_private": 1,
        "content": content,
    })
    file_doc.save(ignore_permissions=True)

    frappe.db.set_value("Medicine Request", order, "prescription", file_doc.file_url)
    frappe.db.commit()
    audit_log("Update", "Medicine Request", order, "Patient uploaded prescription via app")
    return {"success": True, "file_url": file_doc.file_url}


# Patient-facing lifecycle stages, in order. "Cancelled" is terminal and
# handled separately by the app.
_MEDICINE_ORDER_STAGES = [
    "Received", "Under Review", "Awaiting Payment", "Paid",
    "Preparing", "Out for Delivery", "Delivered",
]
# Stages from which a patient may still cancel their own order — before they've
# paid. Once "Paid"/"Preparing" the pharmacy is already acting on it.
_MEDICINE_CANCELLABLE = {"Received", "Under Review", "Awaiting Payment"}


def _lazy_reconcile_order_payment(order):
    """Best-effort self-heal for "paid but still Awaiting Payment": if the
    order carries a payment_reference whose transaction has since Completed,
    settle it now. Covers completions the real-time hook and the cron missed
    (e.g. the gateway wrote the log without doc.save(), or the scheduler was
    down). Mutates the passed row dict so the response reflects the new state.
    Never raises — order listing must keep working when the gateway is down."""
    txn = (order.get("payment_reference") or "").strip()
    if not txn or order.get("payment_status") == "Paid":
        return
    try:
        pos = _mobile_payments_pos()
        if not pos:
            return
        result = _as_admin(pos.check_pos_payment_status, txn) or {}
        if (result.get("status") or "").strip().lower() != "completed":
            return
        mark_order_paid(order["name"], txn)
        order["payment_status"] = "Paid"
        if order.get("status") == "Awaiting Payment":
            order["status"] = "Paid"
    except Exception:
        frappe.logger("hiraal_pay").exception(
            "lazy reconcile failed for %s", order.get("name")
        )


@frappe.whitelist()
def get_my_orders(limit=30):
    """Medicine orders for the logged-in patient, newest first, with their
    current status, delivery timeline, and line items — so the app can show
    real order tracking."""
    patient = _my_patient_name()
    orders = _safe_get_all(
        "Medicine Request",
        filters={"patient": patient},
        fields=[
            "name", "status", "priority", "total_items",
            "delivery_type", "delivery_address", "estimated_delivery",
            "preparation_started", "dispatched_at", "delivered_at",
            "payment_method", "payment_status", "payment_reference",
            "amount", "delivery_fee", "tax", "total",
            "prescription", "received_confirmed",
            "pharmacist_note", "cancellation_reason", "creation",
        ],
        order_by="creation desc",
        limit_page_length=int(limit or 30),
    )
    for o in orders:
        _lazy_reconcile_order_payment(o)
        o["medicines"] = _safe_get_all(
            "Medicine Request Item",
            filters={"parent": o["name"], "parenttype": "Medicine Request"},
            fields=["medicine_name", "quantity", "dosage", "frequency",
                    "unit_price", "total_price", "in_stock"],
            order_by="idx asc",
        )
        o["cancellable"] = 1 if o.get("status") in _MEDICINE_CANCELLABLE else 0
        # The patient can pay only once the pharmacy has priced & requested it.
        o["payable"] = 1 if o.get("status") == "Awaiting Payment" else 0
    return orders


@frappe.whitelist()
def cancel_my_order(name, reason=None):
    """Let a patient cancel their own order while it's still cancellable."""
    patient = _my_patient_name()
    owner = frappe.db.get_value("Medicine Request", name, "patient")
    if owner != patient:
        frappe.throw(_("Not permitted"), frappe.PermissionError)
    status = frappe.db.get_value("Medicine Request", name, "status")
    if status not in _MEDICINE_CANCELLABLE:
        frappe.throw(_("This order can no longer be cancelled"))
    doc = frappe.get_doc("Medicine Request", name)
    doc.status = "Cancelled"
    doc.cancellation_reason = reason or "Cancelled by patient"
    doc.save(ignore_permissions=True)
    frappe.db.commit()
    audit_log("Update", "Medicine Request", name, "Patient cancelled order via app")
    return {"success": True, "status": "Cancelled"}


@frappe.whitelist()
def pay_my_order(order, provider, method, phone):
    """Start a mobile-money charge for a priced medicine order (Zaad / eDahab).
    Only valid while the order is "Awaiting Payment"; charges the order total
    (medicines + delivery_fee + tax). Returns a transaction_log to poll with
    check_my_order_payment."""
    _my_order_or_throw(order)
    info = frappe.db.get_value(
        "Medicine Request", order, ["status", "total"], as_dict=True
    ) or {}
    if info.get("status") != "Awaiting Payment":
        frappe.throw(_("This order is not awaiting payment"))
    amount = flt(info.get("total"))
    if amount <= 0:
        frappe.throw(_("This order has no amount to pay yet"))

    pos = _mobile_payments_pos()
    if not pos:
        frappe.throw(_("Payment gateway is not available"))

    # Idempotency: if this order already has an initiation in flight, an app
    # retry must not double-charge the wallet.
    existing_txn = frappe.db.get_value("Medicine Request", order, "payment_reference")
    if existing_txn:
        try:
            existing = _as_admin(pos.check_pos_payment_status, existing_txn) or {}
        except Exception:
            existing = {}  # unknown — fall through to a fresh initiation
        raw = (existing.get("status") or "").strip().lower()
        if raw == "pending":
            return {
                "success": True,
                "transaction_log": existing_txn,
                "amount": amount,
                "order": order,
                "message": "Payment already in progress — approve it on your phone.",
            }
        if raw == "completed":
            mark_order_paid(order, existing_txn)
            return {
                "success": True,
                "transaction_log": existing_txn,
                "amount": amount,
                "order": order,
                "message": "Payment already received.",
            }
        # Failed/unknown — proceed with a fresh initiation.

    result = _as_admin(
        pos.initiate_pos_payment,
        provider=provider, method=method, phone=phone, amount=amount, currency="USD",
    ) or {}

    # Log the raw gateway response so we can diagnose "could not start" failures.
    frappe.logger("hiraal_pay").info(
        "pay_my_order initiate: order=%s provider=%s method=%s phone=%s amount=%s result=%s",
        order, provider, method, phone, amount, result,
    )

    if not result.get("success"):
        msg = result.get("message") or _("Could not start the payment")
        frappe.log_error(
            title="Payment initiation failed",
            message=f"order={order} provider={provider} method={method} phone={phone} amount={amount} gateway_result={result}",
        )
        frappe.throw(msg)

    txn = result.get("transaction_log")
    if not txn:
        # The gateway said success but didn't hand back a transaction id. Without
        # it the app cannot poll and the order can never be marked paid.
        frappe.logger("hiraal_pay").error(
            "pay_my_order missing transaction_log: order=%s result=%s", order, result
        )
        frappe.throw(_("Payment started but no transaction id was returned. Please try again."))

    # Bind the transaction to this order: in cache (fast permission check) AND
    # persistently on the order itself. The persistent link is what lets the
    # reconciliation job mark the order paid when the wallet approval arrives
    # AFTER the app stopped polling (ZAAD/eDahab can take minutes) — without it,
    # money left the wallet but the order stayed "Awaiting Payment" forever.
    # We never let a persistence/cache error hide a successfully-initiated charge.
    try:
        frappe.cache().set_value(f"hiraal_txn_order:{txn}", order, expires_in_sec=86400)
    except Exception:
        frappe.logger("hiraal_pay").exception("pay_my_order cache bind failed for %s", txn)
    try:
        frappe.db.set_value("Medicine Request", order, "payment_reference", txn,
                            update_modified=False)
        frappe.db.commit()
    except Exception:
        frappe.logger("hiraal_pay").exception("pay_my_order db bind failed for %s", txn)
        # If the DB bind fails we still return success so the app can poll; the
        # every-5-min reconciliation job can later settle the order because the
        # gateway transaction itself exists.

    return {
        "success": True,
        "transaction_log": txn,
        "amount": amount,
        "order": order,
        "message": result.get("message"),
    }


def mark_order_paid(order, transaction_log):
    """Mark a medicine order paid against a completed gateway transaction.
    Idempotent. Shared by the app's polling endpoint and the reconciliation job."""
    cur = frappe.db.get_value("Medicine Request", order, "payment_status")
    if cur == "Paid":
        return
    # Underpayment guard (mirrors reconcile_mobile_payments): a completed
    # transaction that covered less than the order total needs a human look —
    # never settle it. Overpayment settles.
    txn_amount = frappe.db.get_value(
        "Mobile Payment Transaction Log", transaction_log, "amount"
    )
    if txn_amount is not None:
        total = frappe.db.get_value("Medicine Request", order, "total")
        if flt(txn_amount) < flt(total) - 0.01:
            frappe.log_error(
                f"{order}: completed txn {transaction_log} amount "
                f"{txn_amount} < order total {total}",
                "Payment Reconciliation Mismatch",
            )
            return
    doc = frappe.get_doc("Medicine Request", order)
    doc.payment_status = "Paid"
    doc.payment_reference = transaction_log
    if doc.status == "Awaiting Payment":
        doc.status = "Paid"
    doc.save(ignore_permissions=True)
    frappe.db.commit()
    audit_log("Update", "Medicine Request", order, "Order paid via mobile money")


@frappe.whitelist()
def check_my_order_payment(order, transaction_log):
    """Poll a medicine-order payment. On completion, mark the order Paid and
    record the payment reference. Idempotent. The transaction must be the one
    initiated for this order (cache binding, with the persistent link on the
    order as fallback — the cache doesn't survive a server restart)."""
    _my_order_or_throw(order)
    bound = frappe.cache().get_value(f"hiraal_txn_order:{transaction_log}")
    if bound != order:
        persisted = frappe.db.get_value("Medicine Request", order, "payment_reference")
        if persisted != transaction_log:
            frappe.throw(_("Not permitted"), frappe.PermissionError)
    pos = _mobile_payments_pos()
    if not pos:
        frappe.throw(_("Payment gateway is not available"))
    result = _as_admin(pos.check_pos_payment_status, transaction_log) or {}
    # The gateway's status casing isn't guaranteed ("completed"/"COMPLETED");
    # the Flutter app exact-matches the canonical values, so normalize here.
    raw = (result.get("status") or "").strip()
    status = {
        "completed": "Completed", "failed": "Failed", "pending": "Pending",
    }.get(raw.lower(), "Pending")
    if status == "Completed":
        mark_order_paid(order, transaction_log)
    return {"status": status}


@frappe.whitelist()
def confirm_my_order_received(order):
    """Let the patient confirm they received a delivered order."""
    _my_order_or_throw(order)
    status = frappe.db.get_value("Medicine Request", order, "status")
    if status != "Delivered":
        frappe.throw(_("This order has not been delivered yet"))
    frappe.db.set_value("Medicine Request", order, "received_confirmed", 1)
    frappe.db.commit()
    audit_log("Update", "Medicine Request", order, "Patient confirmed receipt of order")
    return {"success": True}


# Patient-friendly message per order status. Used by the on_update doc event.
_MEDICINE_STATUS_MESSAGES = {
    "Under Review": "Hiraal Pharma: Your prescription for order {name} is being reviewed by our pharmacist.",
    "Awaiting Payment": "Hiraal Pharma: Order {name} is priced and ready. Please confirm & pay in the app to proceed.",
    "Paid": "Hiraal Pharma: Payment received for order {name}. We're preparing your medicines.",
    "Preparing": "Hiraal Pharma: Your pharmacy is now preparing medicine order {name}.",
    "Out for Delivery": "Hiraal Pharma: Your medicine order {name} is out for delivery.",
    "Delivered": "Hiraal Pharma: Your medicine order {name} has been delivered. Please confirm receipt in the app. Take care!",
    "Cancelled": "Hiraal Pharma: Your medicine order {name} has been cancelled.",
}
# Statuses important enough to also send a (paid) SMS, not just an in-app alert.
_MEDICINE_SMS_STATUSES = {"Awaiting Payment", "Out for Delivery", "Delivered", "Cancelled"}


def on_chronic_care_alert_insert(doc, method=None):
    """Notify linked caregivers when a clinical alert is created."""
    try:
        from hiraal_emr.services.caregiver_service import notify_sponsors_of_alert

        notify_sponsors_of_alert(
            doc.patient,
            doc.alert_type or doc.alert_level or "Alert",
            doc.reason or doc.name,
        )
    except Exception:
        frappe.logger("hiraal_caregiver").exception("caregiver alert hook failed")


def on_medicine_request_update(doc, method=None):
    """Notify the patient when their medicine order's status changes.

    In-app notification for every meaningful transition; an SMS for the key
    milestones (out-for-delivery / delivered / cancelled). Best-effort — a
    notification failure must never block the pharmacy's status update."""
    try:
        if not doc.has_value_changed("status"):
            return
        template = _MEDICINE_STATUS_MESSAGES.get(doc.status)
        if not template:
            return
        message = template.format(name=doc.name)
        notify_patient(
            doc.patient,
            subject=f"Order {doc.name}: {doc.status}",
            message=message,
            sms=doc.status in _MEDICINE_SMS_STATUSES,
            document_type="Medicine Request",
            document_name=doc.name,
        )
    except Exception:
        frappe.logger("hiraal_orders").exception("medicine status notify failed")


def notify_patient(patient, subject, message, sms=False,
                   document_type=None, document_name=None):
    """Best-effort patient notification: an in-app Notification Log entry (read
    by the app's notification centre) plus an optional SMS. Never raises."""
    if not patient:
        return
    info = frappe.db.get_value(
        "Patient", patient, ["user_id", "mobile"], as_dict=True
    ) or {}

    if info.get("user_id"):
        try:
            note = frappe.new_doc("Notification Log")
            note.subject = subject
            note.email_content = message
            note.for_user = info["user_id"]
            note.type = "Alert"
            if document_type:
                note.document_type = document_type
            if document_name:
                note.document_name = document_name
            note.insert(ignore_permissions=True)
        except Exception:
            frappe.logger("hiraal_orders").exception("notification log insert failed")
        send_push_to_user(info["user_id"], subject, message, {"type": document_type or "alert"})

    if sms and info.get("mobile"):
        try:
            send_sms(info["mobile"], message)
        except Exception:
            frappe.logger("hiraal_orders").exception("order status SMS failed")


@frappe.whitelist(allow_guest=False)
def pay_subscription(patient, payment_method="Zaad", reference=None):
    """Process a subscription payment from the mobile app."""
    _require_clinical()
    if payment_method not in ("Cash", "Bank Transfer"):
        frappe.throw(_("Manual settlement is only for Cash or Bank Transfer. Mobile money goes through the patient app."))
    sub = frappe.db.get_value(
        "Care Subscription",
        {"patient": patient, "status": ["in", ["Active", "Overdue", "Past Due"]]},
        "name",
        order_by="creation desc",
    )
    if not sub:
        frappe.throw(_("No active subscription found for this patient"))

    doc = frappe.get_doc("Care Subscription", sub)
    doc.payment_method = payment_method
    if reference:
        doc.payment_reference = reference
    doc.save(ignore_permissions=True)
    doc.process_payment()

    audit_log("Update", "Care Subscription", doc.name, f"Payment processed via {payment_method}")
    return {"success": True, "subscription": doc.name, "status": doc.status}


# ──────────────────────────────────────────────
#  Mobile-money payments (WaafiPay / eDahab via the mobile_payments app)
# ──────────────────────────────────────────────

def _mobile_payments_pos():
    """The installed mobile_payments POS API, or None if the app isn't present."""
    try:
        from mobile_payments.api import pos
        return pos
    except Exception:
        return None


def _as_admin(fn, *args, **kwargs):
    """Run a gateway call with elevated rights, then restore the session user.
    The caller is always resolved/scoped to the patient *before* this is used."""
    original = frappe.session.user
    try:
        frappe.set_user("Administrator")
        return fn(*args, **kwargs)
    finally:
        frappe.set_user(original)


@frappe.whitelist()
def get_payment_methods():
    """Mobile-money methods available for the app's payment screen
    (WaafiPay ZAAD/SAHAL/EVCPlus, eDahab). Empty when the gateway is off."""
    _my_patient_name()  # require a logged-in patient
    pos = _mobile_payments_pos()
    if not pos:
        return {"enabled": False, "methods": []}
    try:
        return _as_admin(pos.get_mobile_payment_methods)
    except Exception:
        frappe.logger("hiraal_pay").exception("get_payment_methods failed")
        return {"enabled": False, "methods": []}


# Subscription statuses that represent a live/payable subscription (a brand-new
# unpaid one starts "Overdue" since the doctype has no "Pending" status).
# "Suspended" must stay payable — otherwise a suspended subscriber can never
# pay their way back and the paywall dead-ends.
_SUB_PAYABLE_STATUSES = ["Active", "Overdue", "Past Due", "Expiring Soon", "Suspended"]


def _my_active_subscription(patient):
    return frappe.db.get_value(
        "Care Subscription",
        {"patient": patient, "status": ["in", _SUB_PAYABLE_STATUSES]},
        ["name", "monthly_fee", "plan", "is_on_trial", "trial_end_date", "status"],
        as_dict=True, order_by="creation desc",
    )


@frappe.whitelist()
def get_my_subscription():
    """The logged-in patient's Care Subscription, ERPNext plan catalog,
    category list, free-trial settings, and payment history."""
    from hiraal_emr.services.subscription_catalog import (
        patient_trial_eligible,
        subscription_plans_catalog,
        trial_config,
        has_active_subscription,
    )

    patient = _my_patient_name()
    fields = [
        "name", "plan", "monthly_fee", "status", "start_date", "next_billing_date",
        "last_payment_date", "last_payment_status", "auto_renew", "total_collected",
    ]
    # Trial / category columns may be missing until migrate on older sites.
    meta = frappe.get_meta("Care Subscription")
    for extra in ("plan_category", "is_on_trial", "trial_end_date"):
        if meta.has_field(extra):
            fields.append(extra)

    sub = frappe.db.get_value(
        "Care Subscription",
        {"patient": patient, "status": ["in", _SUB_PAYABLE_STATUSES + ["Suspended"]]},
        fields,
        as_dict=True, order_by="creation desc",
    )
    history = []
    if frappe.db.exists("DocType", "Subscription Payment"):
        history = _safe_get_all(
            "Subscription Payment",
            filters={"patient": patient},
            fields=["amount", "payment_date", "payment_method", "status", "reference_id"],
            order_by="payment_date desc", limit_page_length=10,
        )
    plans = subscription_plans_catalog()
    trial = trial_config()
    trial_eligible = bool(trial["enabled"] and patient_trial_eligible(patient))
    categories = []
    for p in plans:
        cat = p.get("category") or "General"
        if cat not in categories:
            categories.append(cat)
    return {
        "subscription": sub,
        "plans": plans,
        "categories": categories,
        "history": history,
        "trial": {
            "enabled": trial["enabled"],
            "days": trial["days"],
            "eligible": trial_eligible,
        },
        "active": has_active_subscription(patient),
    }


@frappe.whitelist()
def subscribe_my_plan(plan, start_trial=0):
    """Create a Care Subscription for the logged-in patient on the chosen plan.

    When ``start_trial`` is set and free trial is enabled in Chronic Care
    Settings (and the plan allows it), activate immediately with no payment.
    Otherwise create an Overdue subscription for the app to collect payment.
    """
    from hiraal_emr.services.subscription_catalog import (
        patient_trial_eligible,
        resolve_plan,
        trial_config,
    )

    patient = _my_patient_name()
    plan_row = resolve_plan(plan)
    if not plan_row:
        frappe.throw(_("Unknown or inactive plan"))

    fee = flt(plan_row["monthly_fee"])
    existing = _my_active_subscription(patient)
    if existing:
        on_trial = 1 if int(existing.get("is_on_trial") or 0) else 0
        return {
            "subscription": existing.name,
            "monthly_fee": flt(existing.monthly_fee),
            "plan": existing.plan or plan,
            "status": "existing",
            "amount_due_now": 0 if (existing.status == "Active" and on_trial) else flt(existing.monthly_fee),
            "is_on_trial": on_trial,
            "trial_end_date": existing.get("trial_end_date"),
        }

    want_trial = int(start_trial or 0)
    trial = trial_config()
    can_trial = (
        want_trial
        and trial["enabled"]
        and int(plan_row.get("allows_trial") or 0)
        and patient_trial_eligible(patient)
    )
    if want_trial and not can_trial:
        frappe.throw(_("Free trial is not available for this plan or account."))

    sub = frappe.new_doc("Care Subscription")
    sub.patient = patient
    sub.patient_phone = frappe.db.get_value("Patient", patient, "mobile")
    sub.plan = plan_row["name"]
    if hasattr(sub, "plan_category"):
        sub.plan_category = plan_row.get("category") or "General"
    sub.monthly_fee = fee
    sub.auto_renew = 1
    sub.start_date = today()

    if can_trial:
        trial_end = add_days(getdate(today()), trial["days"])
        sub.status = "Active"
        if hasattr(sub, "is_on_trial"):
            sub.is_on_trial = 1
            sub.trial_end_date = trial_end
        sub.next_billing_date = trial_end
        sub.insert(ignore_permissions=True)
        frappe.db.commit()
        audit_log(
            "Create", "Care Subscription", sub.name,
            f"Patient started {trial['days']}-day trial on {plan_row['name']}",
        )
        return {
            "subscription": sub.name,
            "monthly_fee": fee,
            "plan": plan_row["name"],
            "status": sub.status,
            "amount_due_now": 0,
            "is_on_trial": 1,
            "trial_end_date": str(trial_end),
            "trial_days": trial["days"],
        }

    sub.status = "Overdue"  # unpaid; becomes Active once paid
    if hasattr(sub, "is_on_trial"):
        sub.is_on_trial = 0
    sub.next_billing_date = today()
    sub.insert(ignore_permissions=True)
    frappe.db.commit()
    audit_log(
        "Create", "Care Subscription", sub.name,
        f"Patient subscribed to {plan_row['name']} via app",
    )
    return {
        "subscription": sub.name,
        "monthly_fee": fee,
        "plan": plan_row["name"],
        "status": sub.status,
        "amount_due_now": fee,
        "is_on_trial": 0,
        "trial_end_date": None,
    }


@frappe.whitelist()
def pay_my_subscription(provider, method, phone):
    """Start a mobile-money charge for the logged-in patient's care subscription.
    Sends a USSD prompt to ``phone``; returns a transaction_log to poll with
    check_my_payment."""
    patient = _my_patient_name()
    sub = _my_active_subscription(patient)
    if not sub:
        frappe.throw(_("No subscription found for your account"))
    if int(sub.get("is_on_trial") or 0):
        frappe.throw(_("You are on a free trial. Payment is due when the trial ends."))
    amount = flt(sub.monthly_fee)
    if amount <= 0:
        frappe.throw(_("Your subscription amount is not set"))

    pos = _mobile_payments_pos()
    if not pos:
        frappe.throw(_("Payment gateway is not available"))

    # Idempotency: if this subscription already has an initiation in flight, an
    # app retry must not double-charge the wallet.
    existing_txn = frappe.db.get_value("Care Subscription", sub.name, "payment_reference")
    if existing_txn:
        try:
            existing = _as_admin(pos.check_pos_payment_status, existing_txn) or {}
        except Exception:
            existing = {}  # unknown — fall through to a fresh initiation
        raw = (existing.get("status") or "").strip().lower()
        if raw == "pending":
            return {
                "success": True,
                "transaction_log": existing_txn,
                "amount": amount,
                "subscription": sub.name,
                "message": "Payment already in progress — approve it on your phone.",
            }
        if raw == "completed":
            _mark_subscription_paid(patient, existing_txn)
            return {
                "success": True,
                "transaction_log": existing_txn,
                "amount": amount,
                "subscription": sub.name,
                "message": "Payment already received.",
            }
        # Failed/unknown — proceed with a fresh initiation.

    result = _as_admin(
        pos.initiate_pos_payment,
        provider=provider, method=method, phone=phone, amount=amount, currency="USD",
    ) or {}

    frappe.logger("hiraal_pay").info(
        "pay_my_subscription initiate: patient=%s sub=%s provider=%s method=%s phone=%s amount=%s result=%s",
        patient, sub.name, provider, method, phone, amount, result,
    )

    if not result.get("success"):
        msg = result.get("message") or _("Could not start the payment")
        frappe.log_error(
            title="Subscription payment initiation failed",
            message=f"patient={patient} sub={sub.name} provider={provider} method={method} phone={phone} amount={amount} gateway_result={result}",
        )
        frappe.throw(msg)

    txn = result.get("transaction_log")
    if not txn:
        frappe.logger("hiraal_pay").error(
            "pay_my_subscription missing transaction_log: sub=%s result=%s", sub.name, result
        )
        frappe.throw(_("Payment started but no transaction id was returned. Please try again."))

    # Bind the transaction to its initiator: transaction-log names are
    # sequential/guessable, so without this another patient could poll a
    # completed transaction and get their own subscription credited with it.
    # Also persist the link on the subscription so the reconciliation job can
    # activate it when the wallet approval lands after the app stopped polling.
    try:
        frappe.cache().set_value(f"hiraal_txn_owner:{txn}", patient, expires_in_sec=86400)
    except Exception:
        frappe.logger("hiraal_pay").exception("pay_my_subscription cache bind failed for %s", txn)
    try:
        frappe.db.set_value("Care Subscription", sub.name, "payment_reference", txn,
                            update_modified=False)
        frappe.db.commit()
    except Exception:
        frappe.logger("hiraal_pay").exception("pay_my_subscription db bind failed for %s", txn)

    return {
        "success": True,
        "transaction_log": txn,
        "amount": amount,
        "subscription": sub.name,
        "message": result.get("message"),
    }


@frappe.whitelist()
def check_my_payment(transaction_log):
    """Poll a subscription payment. On completion, mark the patient's
    subscription paid and record a Subscription Payment (once). The
    transaction must have been initiated by this patient (cache binding, with
    the persistent link on their subscription as restart-safe fallback)."""
    patient = _my_patient_name()
    owner = frappe.cache().get_value(f"hiraal_txn_owner:{transaction_log}")
    if owner != patient:
        persisted = frappe.db.get_value(
            "Care Subscription",
            {"patient": patient, "payment_reference": transaction_log},
            "name",
        )
        if not persisted:
            frappe.throw(_("Not permitted"), frappe.PermissionError)
    pos = _mobile_payments_pos()
    if not pos:
        frappe.throw(_("Payment gateway is not available"))
    result = _as_admin(pos.check_pos_payment_status, transaction_log) or {}
    # The gateway's status casing isn't guaranteed ("completed"/"COMPLETED");
    # the Flutter app exact-matches the canonical values, so normalize here.
    raw = (result.get("status") or "").strip()
    status = {
        "completed": "Completed", "failed": "Failed", "pending": "Pending",
    }.get(raw.lower(), "Pending")
    if status == "Completed":
        _mark_subscription_paid(patient, transaction_log)
    return {"status": status}


_SUB_PAYMENT_METHODS = ("Zaad", "eDahab", "Visa/Mastercard", "Cash", "Bank Transfer")


def _resolve_payment_method(sub, reference):
    """Pick a valid Subscription Payment.payment_method option.

    App subscribers never have sub.payment_method set; derive the provider
    from the gateway transaction, falling back to Zaad (the default wallet).
    """
    if sub.payment_method in _SUB_PAYMENT_METHODS:
        return sub.payment_method
    try:
        meta = frappe.get_meta("Mobile Payment Transaction Log")
        for field in ("provider", "payment_provider", "method", "payment_method"):
            if meta.has_field(field):
                val = (frappe.db.get_value(
                    "Mobile Payment Transaction Log", reference, field) or "").lower()
                if "dahab" in val:
                    return "eDahab"
                if val:
                    return "Zaad"
    except Exception:
        pass
    return "Zaad"


def _mark_subscription_paid(patient, reference):
    """Mirror Care Subscription.process_payment()'s success branch after the
    real gateway confirms payment. Idempotent per transaction reference."""
    if frappe.db.exists("Subscription Payment", {"reference_id": reference}):
        return
    sub_name = frappe.db.get_value(
        "Care Subscription",
        {"patient": patient, "status": ["in", _SUB_PAYABLE_STATUSES]},
        "name", order_by="creation desc",
    )
    if not sub_name:
        return
    sub = frappe.get_doc("Care Subscription", sub_name)
    amount = flt(sub.monthly_fee)
    base_date = getdate(sub.next_billing_date) if sub.next_billing_date else getdate(today())

    pay = frappe.new_doc("Subscription Payment")
    pay.subscription = sub.name
    pay.patient = patient
    pay.amount = amount
    pay.payment_date = now_datetime()
    pay.payment_method = _resolve_payment_method(sub, reference)
    pay.status = "Success"
    pay.reference_id = reference
    pay.transaction_id = reference
    pay.insert(ignore_permissions=True)

    sub.db_set("last_payment_date", today())
    sub.db_set("last_payment_status", "Success")
    sub.db_set("payment_reference", reference)
    sub.db_set("next_billing_date", add_months(base_date, 1))
    sub.db_set("retry_count", 0)
    sub.db_set("total_collected", flt(sub.total_collected) + amount)
    sub.db_set("status", "Active")
    frappe.db.commit()
    audit_log("Update", "Care Subscription", sub.name, "Subscription paid via mobile money")


@frappe.whitelist(allow_guest=False)
def get_notifications(patient, limit=20):
    """Fetch patient notifications for the mobile app."""
    _require_patient_access(patient)
    notifications = frappe.get_all(
        "Notification Log",
        filters={"for_user": frappe.session.user},
        fields=["name", "subject", "email_content", "creation", "read"],
        order_by="creation desc",
        limit=int(limit),
    )

    # Also include recent alerts for this patient
    alerts = frappe.get_all(
        "Chronic Care Alert",
        filters={"patient": patient, "creation": [">=", add_days(getdate(today()), -7)]},
        fields=["name", "alert_level", "alert_type", "creation"],
        order_by="creation desc",
        limit=10,
    )

    return {
        "success": True,
        "notifications": notifications,
        "recent_alerts": alerts,
    }


# ──────────────────────────────────────────────
#  Patient Management (Section 4.3)
# ──────────────────────────────────────────────

@frappe.whitelist()
def get_patient_registry_data(risk_filter=None, condition_filter=None,
                               subscription_filter=None, search=None):
    """Return data for the Patient Management page."""
    _require_clinical()
    filters = {"status": "Active"}
    if condition_filter:
        filters["chronic_conditions"] = ["like", f"%{condition_filter}%"]

    patients = frappe.get_all(
        "Patient",
        filters=filters,
        fields=[
            "name", "patient_name", "mobile", "sex", "dob",
            "status", "creation",
        ],
        order_by="patient_name asc",
        limit=200,
    )

    # Enrich with risk level, subscription, and assigned nurse
    for p in patients:
        # Risk level from latest alert
        latest_alert = frappe.db.get_value(
            "Chronic Care Alert",
            {"patient": p.name, "status": "Open"},
            ["alert_level"],
            order_by="creation desc",
        )
        p["risk_level"] = latest_alert or "Normal"

        # Subscription
        sub = frappe.db.get_value(
            "Care Subscription",
            {"patient": p.name, "status": ["!=", "Cancelled"]},
            ["plan", "status"],
            as_dict=True,
        )
        p["subscription_plan"] = sub.plan if sub else "None"
        p["subscription_status"] = sub.status if sub else "None"

        # Last reading
        last_reading = frappe.db.get_value(
            "Daily Reading",
            {"patient": p.name},
            ["reading_date", "bp_systolic", "bp_diastolic", "blood_sugar"],
            order_by="reading_date desc",
            as_dict=True,
        )
        p["last_reading_date"] = last_reading.reading_date if last_reading else None
        p["last_bp"] = f"{last_reading.bp_systolic}/{last_reading.bp_diastolic}" if last_reading and last_reading.bp_systolic else None
        p["last_sugar"] = last_reading.blood_sugar if last_reading else None

    # Apply client-side style filters
    if risk_filter and risk_filter != "All":
        patients = [p for p in patients if p["risk_level"] == risk_filter]
    if subscription_filter and subscription_filter != "All":
        patients = [p for p in patients if p["subscription_status"] == subscription_filter]
    if search:
        s = search.lower()
        patients = [p for p in patients if s in (p.patient_name or "").lower() or s in (p.name or "").lower()]

    # Risk distribution for pie chart
    risk_counts = {"Very High": 0, "High": 0, "Medium": 0, "Low": 0, "Normal": 0}
    for p in patients:
        risk_counts[p["risk_level"]] = risk_counts.get(p["risk_level"], 0) + 1

    # Subscription breakdown
    sub_counts = {"Active": 0, "Overdue": 0, "Past Due": 0, "None": 0}
    for p in patients:
        sub_counts[p.get("subscription_status", "None")] = sub_counts.get(p.get("subscription_status", "None"), 0) + 1

    return {
        "patients": patients,
        "total": len(patients),
        "risk_distribution": risk_counts,
        "subscription_breakdown": sub_counts,
    }


@frappe.whitelist()
def get_patient_profile(patient):
    """Return comprehensive patient profile data (Section 4.3b)."""
    _require_clinical()
    p = frappe.get_doc("Patient", patient)

    # Vital sign trends (last 30 days)
    readings = frappe.get_all(
        "Daily Reading",
        filters={"patient": patient, "reading_date": [">=", add_days(getdate(today()), -30)]},
        fields=["reading_date", "bp_systolic", "bp_diastolic", "blood_sugar", "medicine_taken", "source"],
        order_by="reading_date asc",
    )

    # Active alerts
    alerts = frappe.get_all(
        "Chronic Care Alert",
        filters={"patient": patient, "status": ["in", ["Open", "In Review"]]},
        fields=["name", "alert_level", "alert_type", "creation", "status"],
        order_by="creation desc",
        limit=10,
    )

    # Subscription
    sub = frappe.db.get_value(
        "Care Subscription",
        {"patient": patient, "status": ["!=", "Cancelled"]},
        ["name", "plan", "status", "monthly_fee", "next_billing_date"],
        as_dict=True,
    )

    # Devices
    devices = frappe.get_all(
        "Patient Device",
        filters={"patient": patient},
        fields=["device_name", "device_type", "status", "battery_level", "last_sync"],
    )

    # Doctor plans
    reviews = frappe.get_all(
        "Doctor Review",
        filters={"patient": patient},
        fields=["name", "review_status", "assessment", "plan_notes", "next_review_date", "creation"],
        order_by="creation desc",
        limit=5,
    )

    # Nurse notes (completed tasks)
    nurse_notes = frappe.get_all(
        "Nurse Task",
        filters={"patient": patient, "status": "Completed"},
        fields=["task_type", "completion_note", "completed_at"],
        order_by="completed_at desc",
        limit=10,
    )

    # Medication adherence (last 7 days)
    seven_days_ago = add_days(getdate(today()), -7)
    total_readings_7d = frappe.db.count(
        "Daily Reading", {"patient": patient, "reading_date": [">=", seven_days_ago]}
    ) or 0
    med_taken_7d = frappe.db.count(
        "Daily Reading", {"patient": patient, "reading_date": [">=", seven_days_ago], "medicine_taken": "Yes"}
    ) or 0
    adherence_pct = round((med_taken_7d / max(total_readings_7d, 1)) * 100)

    return {
        "patient": {
            "name": p.name,
            "patient_name": p.patient_name,
            "mobile": p.mobile,
            "sex": p.sex,
            "dob": p.dob,
            "blood_group": p.blood_group,
            "status": p.status,
        },
        "readings": readings,
        "alerts": alerts,
        "subscription": sub,
        "devices": devices,
        "reviews": reviews,
        "nurse_notes": nurse_notes,
        "medication_adherence": adherence_pct,
        "readings_7d": total_readings_7d,
    }


# ──────────────────────────────────────────────
#  Daily Readings Dashboard (Section 4.4)
# ──────────────────────────────────────────────

@frappe.whitelist()
def get_readings_dashboard_data(date=None):
    """Return data for the Daily Readings dashboard page."""
    _require_clinical()
    target_date = date or today()

    total_readings = frappe.db.count("Daily Reading", {"reading_date": target_date}) or 0

    # Source breakdown
    sources = frappe.db.sql(
        """SELECT source, COUNT(*) as cnt FROM `tabDaily Reading`
           WHERE reading_date = %s GROUP BY source""",
        target_date,
        as_dict=True,
    )
    source_map = {s.source: s.cnt for s in sources}

    # High readings — Daily Reading risk levels are Normal/Medium/High/Critical
    # (see DailyReading.assess_risk_level); "Very High" only exists on alerts.
    high_readings = frappe.db.count(
        "Daily Reading",
        {"reading_date": target_date, "risk_level": ["in", ["High", "Critical"]]},
    ) or 0

    # Synced vs pending
    synced = frappe.db.count(
        "Daily Reading", {"reading_date": target_date, "sync_status": "Synced"}
    ) or 0
    pending_sync = frappe.db.count(
        "Daily Reading", {"reading_date": target_date, "sync_status": "Pending"}
    ) or 0

    # Recent readings list
    readings = frappe.get_all(
        "Daily Reading",
        filters={"reading_date": target_date},
        fields=[
            "name", "patient", "patient_name", "reading_time",
            "bp_systolic", "bp_diastolic", "blood_sugar", "blood_sugar_unit",
            "medicine_taken", "source", "risk_level", "alert_generated",
            "reviewed_by_nurse", "reviewed_by_doctor", "creation",
        ],
        order_by="creation desc",
        limit=100,
    )

    return {
        "date": target_date,
        "total_readings": total_readings,
        "from_app": source_map.get("App", 0),
        "from_bp_device": source_map.get("BP Device", 0),
        "from_glucometer": source_map.get("Glucometer", 0),
        "from_clinic": source_map.get("Clinic", 0),
        "from_hub": source_map.get("5G Hub", 0),
        "high_readings": high_readings,
        "synced": synced,
        "pending_sync": pending_sync,
        "readings": readings,
    }


# ──────────────────────────────────────────────
#  Medicine Requests (Section 4.9)
# ──────────────────────────────────────────────

@frappe.whitelist()
def get_medicine_requests_data():
    """Return data for the clinic dashboard medicine section."""
    _require_clinical()
    total = frappe.db.count("Medicine Request") or 0
    # Real lifecycle: Received → Under Review → Awaiting Payment → Paid →
    # Preparing → Out for Delivery → Delivered (Cancelled terminal).
    # "Pending" is legacy data (older rows predate the lifecycle);
    # "Dispatched" never existed.
    pending = frappe.db.count(
        "Medicine Request",
        {"status": ["in", ["Received", "Under Review", "Pending"]]},
    ) or 0
    preparing = frappe.db.count("Medicine Request", {"status": "Preparing"}) or 0
    dispatched = frappe.db.count("Medicine Request", {"status": "Out for Delivery"}) or 0
    delivered = frappe.db.count("Medicine Request", {"status": "Delivered"}) or 0

    recent = frappe.get_all(
        "Medicine Request",
        filters={"status": ["!=", "Cancelled"]},
        fields=[
            "name", "patient", "patient_name", "status",
            "delivery_address", "payment_method", "creation",
        ],
        order_by="creation desc",
        limit=20,
    )

    return {
        "total": total,
        "pending": pending,
        "preparing": preparing,
        "dispatched": dispatched,
        "delivered": delivered,
        "requests": recent,
    }


# ──────────────────────────────────────────────
#  Health Tips API
# ──────────────────────────────────────────────

@frappe.whitelist(allow_guest=False)
def get_health_tips(condition=None):
    """Return active health tips, optionally filtered by condition."""
    filters = {"is_active": 1}
    if condition:
        filters["condition"] = ["in", [condition, "Both", "General"]]

    tips = frappe.get_all(
        "Health Tip",
        filters=filters,
        fields=["name", "title", "content", "category", "condition", "image", "display_order"],
        order_by="display_order asc",
        limit=100,
    )
    return {"success": True, "tips": tips}


# ──────────────────────────────────────────────
#  Care Plan API
# ──────────────────────────────────────────────

@frappe.whitelist(allow_guest=False)
def get_care_plan(patient):
    """Return the active care plan for a patient."""
    _require_patient_access(patient)
    plan = frappe.db.get_value(
        "Care Plan",
        {"patient": patient, "status": "Active"},
        ["name", "plan_type", "status", "start_date", "end_date",
         "assigned_nurse", "assigned_doctor", "goals", "instructions", "next_review_date"],
        as_dict=True,
    )
    if not plan:
        return {"success": True, "care_plan": None}
    return {"success": True, "care_plan": plan}


# ──────────────────────────────────────────────
#  Weekly Health Summary API
# ──────────────────────────────────────────────

@frappe.whitelist(allow_guest=False)
def get_weekly_summary(patient):
    """Return the latest weekly health summary for a patient."""
    _require_patient_access(patient)
    summary = frappe.get_all(
        "Weekly Health Summary",
        filters={"patient": patient},
        fields=[
            "name", "week_starting", "week_ending", "avg_systolic",
            "avg_diastolic", "avg_blood_sugar", "medication_adherence_percent",
            "total_readings", "high_readings_count", "status", "doctor_notes",
        ],
        order_by="week_starting desc",
        limit=1,
    )
    return {"success": True, "summary": summary[0] if summary else None}


# ──────────────────────────────────────────────
#  Family Members API
# ──────────────────────────────────────────────

@frappe.whitelist(allow_guest=False)
def get_family_members(patient):
    """Return authorized family members for a patient."""
    from hiraal_emr.services.caregiver_service import list_caregivers_for_patient

    _require_patient_access(patient)
    return {"success": True, "family_members": list_caregivers_for_patient(patient)}


@frappe.whitelist(allow_guest=False)
def invite_caregiver(country_code, whatsapp_number, relationship, family_member_name=None, permissions=None):
    """Patient invites a caregiver/sponsor by WhatsApp number."""
    from hiraal_emr.services.caregiver_service import invite_caregiver as _invite, whatsapp_invite_url, _serialize_link

    patient = _my_patient_name()
    doc = _invite(patient, country_code, whatsapp_number, relationship, family_member_name, permissions)
    audit_log("Create", "Family Member", doc.name, "Caregiver invited from app")
    row = doc.as_dict()
    return {
        "success": True,
        "link": _serialize_link(row),
        "invite_code": doc.invite_code,
        "whatsapp_url": whatsapp_invite_url(doc.name),
    }


@frappe.whitelist(allow_guest=False)
def request_sponsor_connection(country_code, whatsapp_number, relationship, sponsor_name=None):
    """Sponsor requests connection to a patient by their WhatsApp number."""
    from hiraal_emr.services.caregiver_service import request_sponsor_connection as _req, _serialize_link

    doc, patient_row = _req(country_code, whatsapp_number, relationship, sponsor_name)
    audit_log("Create", "Family Member", doc.name, "Sponsor connection requested")
    return {
        "success": True,
        "link": _serialize_link(doc.as_dict()),
        "patient_name": patient_row.patient_name,
    }


@frappe.whitelist(allow_guest=False)
def find_patient_for_sponsor(query):
    """Find a patient by phone or member ID for sponsorship."""
    from hiraal_emr.services.caregiver_service import find_patient_for_sponsor as _find

    row = _find(query)
    if not row:
        return {"success": False, "message": _("No patient found")}
    return {"success": True, "patient": row}


@frappe.whitelist(allow_guest=False)
def redeem_invitation_code(code):
    """Accept a caregiver invitation using a short code."""
    from hiraal_emr.services.caregiver_service import redeem_invitation_code as _redeem, _serialize_link

    doc = _redeem(code, frappe.session.user)
    return {"success": True, "link": _serialize_link(doc.as_dict())}


@frappe.whitelist(allow_guest=False)
def list_my_caregivers():
    """Caregivers linked to the logged-in patient."""
    from hiraal_emr.services.caregiver_service import list_caregivers_for_patient, list_pending_for_patient

    patient = _my_patient_name()
    return {
        "success": True,
        "caregivers": list_caregivers_for_patient(patient),
        "pending": list_pending_for_patient(patient),
    }


@frappe.whitelist(allow_guest=False)
def respond_caregiver_request(name, action):
    """Patient accepts or rejects a caregiver/sponsor request."""
    from hiraal_emr.services.caregiver_service import respond_to_request, _serialize_link

    patient = _my_patient_name()
    doc = respond_to_request(name, action, patient=patient)
    audit_log("Update", "Family Member", doc.name, f"Caregiver request {action}")
    return {"success": True, "link": _serialize_link(doc.as_dict())}


@frappe.whitelist(allow_guest=False)
def update_caregiver_permissions(name, permissions=None):
    """Patient updates what a caregiver may access."""
    from hiraal_emr.services.caregiver_service import update_permissions, _serialize_link

    patient = _my_patient_name()
    perms = permissions
    if isinstance(permissions, str):
        import json as _json
        perms = _json.loads(permissions)
    doc = update_permissions(name, patient, perms or {})
    return {"success": True, "link": _serialize_link(doc.as_dict())}


@frappe.whitelist(allow_guest=False)
def revoke_caregiver(name):
    """Patient removes caregiver access."""
    from hiraal_emr.services.caregiver_service import revoke_link

    patient = _my_patient_name()
    doc = revoke_link(name, patient=patient)
    audit_log("Update", "Family Member", doc.name, "Caregiver access revoked")
    return {"success": True, "link_status": doc.link_status}


@frappe.whitelist(allow_guest=False)
def get_caregiver_whatsapp_invite(name):
    """Return a wa.me URL for re-sending an invitation."""
    from hiraal_emr.services.caregiver_service import whatsapp_invite_url

    patient = _my_patient_name()
    if frappe.db.get_value("Family Member", name, "patient") != patient:
        frappe.throw(_("Not permitted"), frappe.PermissionError)
    return {"success": True, "whatsapp_url": whatsapp_invite_url(name)}


@frappe.whitelist(allow_guest=False)
def list_my_sponsorships():
    """Patients the logged-in user sponsors or cares for."""
    from hiraal_emr.services.caregiver_service import list_sponsorships_for_user

    return {"success": True, "sponsorships": list_sponsorships_for_user(frappe.session.user)}


@frappe.whitelist(allow_guest=False)
def get_sponsorship_dashboard(name):
    """Sponsor dashboard for one linked patient."""
    from hiraal_emr.services.caregiver_service import sponsorship_dashboard

    return {"success": True, **sponsorship_dashboard(name, frappe.session.user)}


@frappe.whitelist(allow_guest=False)
def sponsor_patient_subscription(patient, plan, provider, method, phone, family_member=None):
    """Sponsor pays a patient's care subscription."""
    from hiraal_emr.services.caregiver_service import activate_sponsored_care
    from hiraal_emr.services.subscription_catalog import resolve_plan

    sponsor_user = frappe.session.user
    link_name = family_member
    if not link_name:
        link_name = frappe.db.get_value(
            "Family Member",
            {
                "patient": patient,
                "caregiver_user": sponsor_user,
                "can_pay_for_care": 1,
                "link_status": ["in", ["Accepted", "Active", "Pending"]],
            },
            "name",
        )
    if not link_name:
        frappe.throw(_("You are not authorized to pay for this patient"))

    plan_row = resolve_plan(plan)
    if not plan_row:
        frappe.throw(_("Unknown or inactive plan"))

    # Ensure subscription exists for patient
    sub_name = frappe.db.get_value(
        "Care Subscription",
        {"patient": patient, "status": ["in", _SUB_PAYABLE_STATUSES + ["Suspended"]]},
        "name",
    )
    if not sub_name:
        sub = frappe.new_doc("Care Subscription")
        sub.patient = patient
        sub.plan = plan_row["name"]
        sub.monthly_fee = flt(plan_row["monthly_fee"])
        sub.status = "Overdue"
        sub.start_date = today()
        sub.next_billing_date = add_days(getdate(today()), 30)
        sub.auto_renew = 1
        if hasattr(sub, "sponsor_user"):
            sub.sponsor_user = sponsor_user
        if hasattr(sub, "sponsor_family_member"):
            sub.sponsor_family_member = link_name
        if hasattr(sub, "paid_by_sponsor"):
            sub.paid_by_sponsor = 1
        sub.insert(ignore_permissions=True)
        sub_name = sub.name
    else:
        sub_doc = frappe.get_doc("Care Subscription", sub_name)
        if hasattr(sub_doc, "sponsor_user"):
            sub_doc.sponsor_user = sponsor_user
        if hasattr(sub_doc, "sponsor_family_member"):
            sub_doc.sponsor_family_member = link_name
        if hasattr(sub_doc, "paid_by_sponsor"):
            sub_doc.paid_by_sponsor = 1
        sub_doc.plan = plan_row["name"]
        sub_doc.monthly_fee = flt(plan_row["monthly_fee"])
        sub_doc.save(ignore_permissions=True)

    amount = flt(plan_row["monthly_fee"])
    pos = _mobile_payments_pos()
    if not pos:
        frappe.throw(_("Payment gateway is not available"))

    result = _as_admin(
        pos.initiate_pos_payment,
        provider=provider, method=method, phone=phone, amount=amount, currency="USD",
    ) or {}
    if not result.get("success"):
        frappe.throw(result.get("message") or _("Could not start the payment"))

    txn = result.get("transaction_log")
    frappe.cache().set_value(
        f"hiraal_txn_owner:{txn}",
        json.dumps({"patient": patient, "sponsor": sponsor_user, "family_member": link_name}),
        expires_in_sec=86400,
    )
    frappe.db.set_value("Care Subscription", sub_name, "payment_reference", txn)
    return {
        "success": True,
        "transaction_log": txn,
        "amount": amount,
        "subscription": sub_name,
        "patient": patient,
    }


@frappe.whitelist(allow_guest=False)
def check_sponsor_payment(transaction_log):
    """Poll sponsor payment and activate patient care when complete."""
    from hiraal_emr.services.caregiver_service import activate_sponsored_care

    owner_raw = frappe.cache().get_value(f"hiraal_txn_owner:{transaction_log}")
    if not owner_raw:
        frappe.throw(_("Unknown payment"))
    if isinstance(owner_raw, str) and owner_raw.startswith("{"):
        owner = json.loads(owner_raw)
    else:
        owner = {"patient": owner_raw}

    pos = _mobile_payments_pos()
    if not pos:
        frappe.throw(_("Payment gateway is not available"))
    status_row = _as_admin(pos.check_pos_payment_status, transaction_log) or {}
    raw = (status_row.get("status") or "").strip().lower()
    if raw == "completed":
        patient = owner.get("patient")
        if patient:
            _mark_subscription_paid(patient, transaction_log)
            fm = owner.get("family_member")
            if fm:
                activate_sponsored_care(fm)
        return {"success": True, "status": "Completed"}
    return {"success": True, "status": status_row.get("status") or "Pending"}


@frappe.whitelist(allow_guest=False)
def get_sponsored_patient_data(patient, data_type="readings"):
    """Permission-gated data for a sponsor/caregiver."""
    user = frappe.session.user
    link = frappe.db.get_value(
        "Family Member",
        {
            "patient": patient,
            "caregiver_user": user,
            "link_status": ["in", ["Accepted", "Active"]],
        },
        ["name", "can_view_vitals", "can_view_appointments", "can_view_medications"],
        as_dict=True,
    )
    if not link:
        frappe.throw(_("Not permitted"), frappe.PermissionError)

    if data_type == "readings" and link.can_view_vitals:
        rows = _safe_get_all(
            "Daily Reading",
            filters={"patient": patient},
            fields=["reading_date", "bp_systolic", "bp_diastolic", "blood_sugar", "weight", "risk_level"],
            order_by="reading_date desc",
            limit_page_length=30,
        )
        return {"success": True, "readings": rows}
    if data_type == "appointments" and link.can_view_appointments:
        rows = _safe_get_all(
            "Patient Appointment",
            filters={"patient": patient},
            fields=["name", "appointment_date", "appointment_time", "practitioner_name", "status"],
            order_by="appointment_date desc",
            limit_page_length=20,
        )
        return {"success": True, "appointments": rows}
    if data_type == "orders" and link.can_view_medications:
        rows = _safe_get_all(
            "Medicine Request",
            filters={"patient": patient},
            fields=["name", "status", "modified", "total_amount"],
            order_by="modified desc",
            limit_page_length=20,
        )
        return {"success": True, "orders": rows}
    frappe.throw(_("Not permitted"), frappe.PermissionError)


# ──────────────────────────────────────────────
#  Telemedicine Session API
# ──────────────────────────────────────────────

@frappe.whitelist(allow_guest=False)
def create_telemedicine_session(patient, practitioner, appointment=None,
                                 start_time=None, meeting_url=None, meeting_id=None, notes=None):
    """Create a telemedicine session."""
    _require_clinical()
    session = frappe.new_doc("Telemedicine Session")
    session.patient = patient
    session.practitioner = practitioner
    if appointment:
        session.appointment = appointment
    if start_time:
        session.start_time = start_time
    if meeting_url:
        session.meeting_url = meeting_url
    if meeting_id:
        session.meeting_id = meeting_id
    if notes:
        session.notes = notes
    session.session_status = "Scheduled"
    session.insert(ignore_permissions=True)
    audit_log("Create", "Telemedicine Session", session.name, "Telemedicine session created")
    return {"success": True, "session": session.name, "status": session.session_status}


@frappe.whitelist(allow_guest=False)
def get_telemedicine_sessions(patient, limit=20):
    """Return telemedicine sessions for a patient."""
    _require_patient_access(patient)
    sessions = frappe.get_all(
        "Telemedicine Session",
        filters={"patient": patient},
        fields=[
            "name", "appointment", "practitioner", "practitioner_name",
            "session_status", "start_time", "end_time", "meeting_url",
            "meeting_id", "duration_minutes", "notes",
        ],
        order_by="start_time desc",
        limit=int(limit),
    )
    return {"success": True, "sessions": sessions}


# ──────────────────────────────────────────────
#  BLE Device Protocol API
# ──────────────────────────────────────────────

@frappe.whitelist(allow_guest=False)
def get_ble_protocols():
    """Return all active BLE device protocols for the mobile app.
    
    The Flutter app calls this on startup to build its protocol registry
    dynamically instead of relying on hardcoded parsers.
    """
    protocols = frappe.get_all(
        "BLE Device Protocol",
        filters={"is_active": 1},
        fields=["name"],
        order_by="protocol_name asc",
    )

    result = []
    for p in protocols:
        doc = frappe.get_doc("BLE Device Protocol", p.name)
        result.append(doc.to_mobile_dict())

    return {"success": True, "protocols": result}


# ──────────────────────────────────────────────
#  Andesfit 4G Cellular Device API
# ──────────────────────────────────────────────

@frappe.whitelist(allow_guest=True)
def receive_andesfit_4g_reading():
    """Receive blood-pressure readings from Andesfit 4G cellular devices (ADF-H62).

    The device uploads via HTTPS POST with a JSON body and X-Api-Key header.
    Expected response: plain text starting with "OK" (HTTP 200).
    """

    def _respond(status_code, text):
        """Return raw plain text that the device can parse.

        Frappe v15's as_txt handler reads TWO keys: the download filename
        from response['doctype'] and the body from response['result'].
        The original code set 'filecontent' (that's for type='download'),
        so every response 500ed with KeyError — the device showed "Er",
        retried once, then discarded the reading.
        """
        frappe.local.response.http_status_code = status_code
        frappe.local.response['type'] = 'txt'
        frappe.local.response['doctype'] = 'andesfit_4g'
        frappe.local.response['result'] = text
        return

    # ── 1. Validate method ──
    if frappe.request.method != "POST":
        return _respond(405, "ERROR: Method Not Allowed")

    # ── 2. Validate X-Api-Key ──
    api_key = (frappe.request.headers.get("X-Api-Key") or "").strip()
    settings = frappe.get_doc("Chronic Care Settings", "Chronic Care Settings")

    if not settings.andesfit_4g_enabled:
        return _respond(503, "ERROR: 4G endpoint disabled")

    expected_key = settings.get_password("andesfit_4g_api_key") or ""
    if not api_key or api_key != expected_key:
        return _respond(401, "ERROR: Invalid API Key")

    # ── 3. Parse JSON payload ──
    try:
        payload = frappe.request.get_json(force=True) or {}
    except Exception:
        return _respond(400, "ERROR: Invalid JSON")

    imei = str(payload.get("imei", "")).strip()
    if not imei:
        return _respond(400, "ERROR: IMEI required")

    # ── 4. Look up device by IMEI ──
    device_name = frappe.db.get_value("Patient Device", {"device_imei": imei}, "name")
    if not device_name:
        # Device not registered – still return OK so the device doesn't retry
        return _respond(200, _andesfit_4g_response(settings))

    device = frappe.get_doc("Patient Device", device_name)
    patient = device.patient
    if not patient:
        return _respond(200, _andesfit_4g_response(settings))

    # ── 5. Extract readings ──
    try:
        systolic = int(payload.get("sys", "0"))
        diastolic = int(payload.get("dia", "0"))
        pulse = int(payload.get("pul", "0")) if payload.get("pul") else None
        abnormal_heartbeat = payload.get("ano") == "1"
        reading_time = payload.get("time", "")
        battery = int(payload.get("BAT", "0")) if payload.get("BAT") else None
        signal = int(payload.get("CSQ", "0")) if payload.get("CSQ") else None
    except (ValueError, TypeError):
        return _respond(400, "ERROR: Invalid numeric data")

    if systolic <= 0 or diastolic <= 0:
        return _respond(400, "ERROR: Invalid BP values")

    # ── 6. Create Daily Reading ──
    doc = frappe.new_doc("Daily Reading")
    doc.patient = patient
    doc.source = "5G Hub"
    doc.source_device = device_name
    doc.bp_systolic = systolic
    doc.bp_diastolic = diastolic
    if abnormal_heartbeat:
        doc.patient_note = (doc.patient_note or "") + " [Abnormal heartbeat detected]"

    # Parse device timestamp if present: "2023-05-31/07:19:22"
    if reading_time and "/" in reading_time:
        try:
            dt_str = reading_time.replace("/", " ")
            doc.reading_date = dt_str.split()[0]
            doc.reading_time = dt_str.split()[1]
        except Exception:
            pass

    doc.insert(ignore_permissions=True)

    # ── 7. Update device health ──
    device.last_sync = now_datetime()
    device.total_syncs = (device.total_syncs or 0) + 1
    if battery is not None:
        device.battery_level = battery
    if signal is not None:
        device.signal_strength = signal
    device.save(ignore_permissions=True)

    audit_log(
        "Create",
        "Daily Reading",
        doc.name,
        f"Received via Andesfit 4G (IMEI {imei})",
    )

    # ── 8. Return device-compatible plain-text response ──
    return _respond(200, _andesfit_4g_response(settings))


def _andesfit_4g_response(settings):
    """Build the plain-text response the Andesfit 4G device expects.

    Spec (Data Exchange Protocol v2.0.0):  OK[YYYYMMDDHHMM][&reminder=HH:MM:S]#end#
    - Clock sync: the datetime is appended DIRECTLY after "OK" — 4-digit
      year, no key name, no seconds (e.g. OK202305310719…). The previous
      "&datetime=YYMMDDHHMMSS" form did not match the spec, so the device
      never actually synced its clock.
    - Reminder: HH:MM followed by the state digit (0=off, 1=on). The setting
      is a Time field which stringifies to HH:MM:SS — truncate to HH:MM or
      the device receives a malformed reminder.
    """
    parts = ["OK"]

    if settings.andesfit_4g_sync_clock:
        now = now_datetime()
        parts.append(now.strftime('%Y%m%d%H%M'))

    if settings.andesfit_4g_default_reminder:
        rem = str(settings.andesfit_4g_default_reminder)[:5]  # HH:MM
        parts.append(f"&reminder={rem}:1")

    parts.append("#end#")
    return "".join(parts)
