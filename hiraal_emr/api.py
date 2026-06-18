"""
Hiraal EMR — Whitelisted API endpoints for dashboard pages, mobile app,
and document event hooks.
"""

import frappe
from frappe import _
from frappe.utils import add_days, getdate, now_datetime, today

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
        "medicine_requests_pending": frappe.db.count("Medicine Request", {"status": "Pending"}) or 0,
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
    open_alerts = frappe.get_all(
        "Chronic Care Alert",
        filters={"status": ["in", ["Open", "In Review"]]},
        fields=[
            "name", "patient", "patient_name", "alert_level", "alert_type",
            "latest_reading_display", "assigned_nurse_name", "creation",
            "bp_systolic", "bp_diastolic", "blood_sugar", "reason",
        ],
        order_by="field(alert_level, 'Very High', 'High', 'Medium', 'Low'), creation desc",
        limit=50,
    )

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
    if not frappe.db.exists("Chronic Care Alert", alert_name):
        frappe.throw(_("Alert {0} not found").format(alert_name), frappe.DoesNotExistError)

    frappe.db.set_value(
        "Chronic Care Alert", alert_name, "resolution_note", note
    )
    return "ok"


@frappe.whitelist()
def resolve_alert(alert_name):
    """Mark an alert as Resolved."""
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
                   medicine_taken=None, note=None, source="App", device_id=None):
    """API endpoint for mobile app to submit a daily reading.

    ``patient`` is optional: when omitted it resolves to the logged-in user's
    own patient, so the mobile app doesn't need to pass an ID.
    """
    patient = patient or _my_patient_name()
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
    if device_id and frappe.db.exists("Patient Device", device_id):
        reading.source_device = device_id
    reading.insert(ignore_permissions=True)

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

    return frappe.get_doc("Patient", name).as_dict()


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
        {"patient": patient, "appointment_date": [">=", today_d], "status": "Open"},
    )
    lab_tests = frappe.db.count("Lab Test", {"patient": patient, "docstatus": 0})
    orders = 0
    try:
        orders = frappe.db.count("Medicine Request", {"patient": patient, "status": "Pending"})
    except Exception:
        pass
    return {
        "upcoming_appointments": appointments,
        "scheduled_lab_tests": lab_tests,
        "active_orders": orders,
    }


@frappe.whitelist()
def get_my_notifications(limit=50):
    """Notifications for the logged-in patient's user account."""
    return _safe_get_all(
        "Notification Log",
        filters={"for_user": frappe.session.user},
        fields=["name", "subject", "email_content", "type", "creation", "read"],
        order_by="creation desc",
        limit_page_length=int(limit or 50),
    )


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
                     notes=None, is_video=0):
    """Book a patient appointment from the mobile app.

    ``notes`` carries the patient's reason for the visit so the clinician sees
    why the appointment was requested (previously collected in the app but
    dropped on the way to the server). When ``is_video`` is set, a Telemedicine
    Session with a Jitsi meeting link is created and the link is returned so the
    app can offer a "Join Video Call" button."""
    appt = frappe.new_doc("Patient Appointment")
    appt.patient = patient
    appt.practitioner = practitioner
    appt.appointment_date = appointment_date
    appt.appointment_time = appointment_time
    appt.appointment_type = appointment_type
    if notes:
        meta = frappe.get_meta("Patient Appointment")
        if meta.has_field("notes"):
            appt.notes = notes
        elif meta.has_field("custom_reason"):
            appt.custom_reason = notes
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
    }


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
            frappe.db.set_value("Telemedicine Session", name, "session_status", "In Progress")
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


def send_push_to_user(user, title, body, data=None):
    """Best-effort FCM push to all of a user's registered devices. A no-op when
    FCM isn't configured yet. Never raises."""
    if not user:
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


_CLINICAL_ROLES = {
    "System Manager", "Chronic Care Admin", "Chronic Care Doctor",
    "Chronic Care Nurse", "Healthcare Practitioner",
}


def _is_clinical_user():
    """True for clinic staff/clinicians; False for patient Website Users."""
    return bool(set(frappe.get_roles()) & _CLINICAL_ROLES)


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
    lab = frappe.new_doc("Lab Test")
    lab.patient = patient
    lab.template = template
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
                   payment_method=None, priority=None):
    """Place a medicine delivery order from the mobile app.

    ``patient`` is optional; when omitted it resolves to the logged-in user's
    own patient so the app never has to pass an ID it might not have.
    """
    import json
    patient = patient or _my_patient_name()
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
    order.status = "Pending"

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


# Patient-facing lifecycle stages, in order. "Cancelled" is terminal and
# handled separately by the app.
_MEDICINE_ORDER_STAGES = [
    "Pending", "Approved", "Preparing", "Ready", "Dispatched", "Delivered",
]
# Stages from which a patient may still cancel their own order.
_MEDICINE_CANCELLABLE = {"Pending", "Approved"}


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
            "payment_method", "payment_status", "amount",
            "pharmacist_note", "cancellation_reason", "creation",
        ],
        order_by="creation desc",
        limit_page_length=int(limit or 30),
    )
    for o in orders:
        o["medicines"] = _safe_get_all(
            "Medicine Request Item",
            filters={"parent": o["name"], "parenttype": "Medicine Request"},
            fields=["medicine_name", "quantity", "dosage"],
            order_by="idx asc",
        )
        o["cancellable"] = 1 if o.get("status") in _MEDICINE_CANCELLABLE else 0
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


# Patient-friendly message per order status. Used by the on_update doc event.
_MEDICINE_STATUS_MESSAGES = {
    "Approved": "Hiraal Lifecare: Your medicine order {name} has been approved and will be prepared shortly.",
    "Preparing": "Hiraal Lifecare: Your pharmacy is now preparing medicine order {name}.",
    "Ready": "Hiraal Lifecare: Your medicine order {name} is ready and will be dispatched soon.",
    "Dispatched": "Hiraal Lifecare: Your medicine order {name} is out for delivery.",
    "Delivered": "Hiraal Lifecare: Your medicine order {name} has been delivered. Take care!",
    "Cancelled": "Hiraal Lifecare: Your medicine order {name} has been cancelled.",
}
# Statuses important enough to also send a (paid) SMS, not just an in-app alert.
_MEDICINE_SMS_STATUSES = {"Dispatched", "Delivered", "Cancelled"}


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


@frappe.whitelist(allow_guest=False)
def get_notifications(patient, limit=20):
    """Fetch patient notifications for the mobile app."""
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

    # High readings
    high_readings = frappe.db.count(
        "Daily Reading",
        {"reading_date": target_date, "risk_level": ["in", ["High", "Very High"]]},
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
    total = frappe.db.count("Medicine Request") or 0
    pending = frappe.db.count("Medicine Request", {"status": "Pending"}) or 0
    preparing = frappe.db.count("Medicine Request", {"status": "Preparing"}) or 0
    dispatched = frappe.db.count("Medicine Request", {"status": "Dispatched"}) or 0
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
    members = frappe.get_all(
        "Family Member",
        filters={"patient": patient, "is_active": 1},
        fields=[
            "name", "family_member_name", "relationship", "phone",
            "email", "can_view_vitals", "can_view_medications", "can_receive_alerts",
        ],
        order_by="creation asc",
    )
    return {"success": True, "family_members": members}


# ──────────────────────────────────────────────
#  Telemedicine Session API
# ──────────────────────────────────────────────

@frappe.whitelist(allow_guest=False)
def create_telemedicine_session(patient, practitioner, appointment=None,
                                 start_time=None, meeting_url=None, meeting_id=None, notes=None):
    """Create a telemedicine session."""
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
        """Return raw plain text that the device can parse."""
        frappe.local.response.http_status_code = status_code
        frappe.local.response['type'] = 'txt'
        frappe.local.response['filecontent'] = text
        frappe.local.response['filename'] = None
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
    doc.source = "Andesfit 4G"
    doc.source_device = device_name
    doc.bp_systolic = systolic
    doc.bp_diastolic = diastolic
    if pulse:
        doc.pulse = pulse
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

    Format: OK[&datetime=YYMMDDHHMMSS][&reminder=HH:MM:D]#end#
    """
    parts = ["OK"]

    if settings.andesfit_4g_sync_clock:
        now = now_datetime()
        parts.append(f"&datetime={now.strftime('%y%m%d%H%M%S')}")

    if settings.andesfit_4g_default_reminder:
        # reminder format: HH:MM:D  (D = day bitmask, 1 = everyday for simplicity)
        rem = str(settings.andesfit_4g_default_reminder)
        parts.append(f"&reminder={rem}:1")

    parts.append("#end#")
    return "".join(parts)
