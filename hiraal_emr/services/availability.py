"""Appointment slots from ERPNext Healthcare Practitioner Schedule.

Wraps Healthcare's availability logic. Never invents slots: if the site has
no Practitioner Schedule, return an empty-state payload the app can render.
"""

from __future__ import annotations

from datetime import datetime, timedelta, time as dt_time

import frappe
from frappe.utils import add_days, get_datetime, getdate, now_datetime, today


def _try_healthcare_availability(practitioner: str, date):
    """Call Healthcare's check-availability if the module is installed."""
    try:
        from healthcare.healthcare.doctype.patient_appointment.patient_appointment import (
            get_availability_data,
        )
    except Exception:
        return None
    try:
        return get_availability_data(practitioner, str(date))
    except TypeError:
        try:
            return get_availability_data(practitioner, str(date), None)
        except Exception:
            frappe.logger("hiraal_slots").exception(
                "get_availability_data failed for %s %s", practitioner, date
            )
            return None
    except Exception:
        frappe.logger("hiraal_slots").exception(
            "get_availability_data failed for %s %s", practitioner, date
        )
        return None


def _slots_from_healthcare_payload(payload) -> list[dict]:
    """Normalise Healthcare's availability payload into {time, available, label}."""
    if not payload:
        return []
    slots = []
    slot_details = []
    if isinstance(payload, dict):
        slot_details = (
            payload.get("slot_details")
            or payload.get("availability_details")
            or payload.get("slots")
            or []
        )
        if isinstance(payload.get("slot_details"), dict):
            slot_details = [payload.get("slot_details")]
    elif isinstance(payload, list):
        slot_details = payload

    for block in slot_details or []:
        if not isinstance(block, dict):
            continue
        avail = (
            block.get("avail_slot")
            or block.get("available_slots")
            or block.get("slots")
            or block.get("slot")
            or []
        )
        booked = set()
        for s in block.get("appointments") or block.get("booked") or []:
            if not s:
                continue
            if isinstance(s, dict):
                booked.add(_as_time_str(s.get("from_time") or s.get("appointment_time") or s))
            else:
                booked.add(_as_time_str(s))
        for slot in avail:
            if isinstance(slot, dict):
                start = slot.get("from_time") or slot.get("start") or slot.get("time")
                available = slot.get("available", 1)
            else:
                start = slot
                available = 1
            if not start:
                continue
            time_str = _as_time_str(start)
            if not time_str:
                continue
            is_free = bool(available) and time_str not in booked
            slots.append({
                "time": time_str,
                "label": _pretty_time(time_str),
                "available": 1 if is_free else 0,
            })
    return slots


def _as_time_str(value) -> str:
    """Normalise MySQL TIME / timedelta / datetime / string to HH:MM:SS."""
    if value is None:
        return ""
    if isinstance(value, timedelta):
        total = int(value.total_seconds()) % (24 * 3600)
        hours, rem = divmod(total, 3600)
        minutes, seconds = divmod(rem, 60)
        return f"{hours:02d}:{minutes:02d}:{seconds:02d}"
    if isinstance(value, dt_time):
        return value.strftime("%H:%M:%S")
    if isinstance(value, datetime):
        return value.strftime("%H:%M:%S")
    raw = str(value).strip()
    if not raw:
        return ""
    if " " in raw:
        raw = raw.split(" ")[-1]
    # "9:00:00" / "09:00" / "9:00"
    parts = raw.split(":")
    try:
        if len(parts) >= 2:
            h, m = int(parts[0]), int(parts[1])
            s = int(float(parts[2])) if len(parts) > 2 else 0
            return f"{h:02d}:{m:02d}:{s:02d}"
    except Exception:
        return raw
    return raw


def _pretty_time(time_str: str) -> str:
    try:
        t = datetime.strptime(time_str[:8], "%H:%M:%S")
        return t.strftime("%I:%M %p").lstrip("0")
    except Exception:
        return time_str


def _english_weekday(date) -> str:
	"""Always English Monday…Sunday — ignore server locale (e.g. Somali)."""
	names = (
		"Monday",
		"Tuesday",
		"Wednesday",
		"Thursday",
		"Friday",
		"Saturday",
		"Sunday",
	)
	# datetime.weekday(): Monday=0 … Sunday=6
	return names[getdate(date).weekday()]


def _day_matches(slot_day: str, weekday_english: str) -> bool:
	"""Match Practitioner Schedule day labels loosely (Monday / Mon / monday)."""
	raw = (slot_day or "").strip()
	if not raw:
		return False
	want = weekday_english.strip().lower()
	got = raw.lower()
	if got == want:
		return True
	# Abbreviations: Mon, Tue, Wed…
	if len(got) >= 3 and want.startswith(got[:3]):
		return True
	if len(want) >= 3 and got.startswith(want[:3]):
		return True
	return False


def _slot_duration_minutes(time_slot, sch) -> int:
	for raw in (
		time_slot.get("duration") if hasattr(time_slot, "get") else None,
		getattr(time_slot, "duration", None),
		sch.get("time_slot_duration") if hasattr(sch, "get") else None,
		sch.get("duration") if hasattr(sch, "get") else None,
	):
		try:
			if raw is None or raw == "":
				continue
			mins = int(float(raw))
			if mins > 0:
				return mins
		except Exception:
			continue
	return 30


def _schedule_names_for_practitioner(practitioner: str) -> list[str]:
	"""Collect Practitioner Schedule names linked to this doctor."""
	names: list[str] = []
	seen: set[str] = set()

	def _add(name):
		if name and name not in seen and frappe.db.exists("Practitioner Schedule", name):
			seen.add(name)
			names.append(name)

	try:
		pract = frappe.get_doc("Healthcare Practitioner", practitioner)
		# Any child table that links a schedule (name varies by Healthcare version).
		for tf in pract.meta.get_table_fields() or []:
			for row in pract.get(tf.fieldname) or []:
				for key in ("schedule", "practitioner_schedule", "practitioner_schedules"):
					_add(row.get(key) if hasattr(row, "get") else getattr(row, key, None))
		for key in ("default_schedule", "schedule"):
			_add(pract.get(key))
	except Exception:
		frappe.logger("hiraal_slots").exception("load practitioner schedules failed")

	# Direct SQL is more reliable than get_all on child tables across versions.
	try:
		if frappe.db.exists("DocType", "Practitioner Service Unit Schedule"):
			rows = frappe.db.sql(
				"""
				SELECT schedule
				FROM `tabPractitioner Service Unit Schedule`
				WHERE parent = %s
				  AND IFNULL(schedule, '') != ''
				""",
				practitioner,
				as_dict=True,
			)
			for r in rows or []:
				_add(r.get("schedule"))
	except Exception:
		frappe.logger("hiraal_slots").exception("SQL schedule lookup failed")

	# Standalone child DocType used by some Healthcare versions.
	for dt in (
		"Practitioner Service Unit Schedule",
		"Practitioner Schedule Detail",
	):
		if not frappe.db.exists("DocType", dt):
			continue
		try:
			meta = frappe.get_meta(dt)
			fields = {f.fieldname for f in meta.fields}
			schedule_field = next(
				(f for f in ("schedule", "practitioner_schedule") if f in fields),
				None,
			)
			if not schedule_field:
				continue
			filters = {}
			if "parent" in fields:
				filters["parent"] = practitioner
			elif "practitioner" in fields:
				filters["practitioner"] = practitioner
			else:
				continue
			rows = frappe.get_all(
				dt,
				filters=filters,
				fields=[schedule_field],
				ignore_permissions=True,
			)
			for r in rows:
				_add(r.get(schedule_field))
		except Exception:
			frappe.logger("hiraal_slots").exception("scan %s for schedules failed", dt)

	return names


def _slots_from_practitioner_schedule(practitioner: str, date) -> list[dict]:
	"""Read Practitioner Schedule child table when Healthcare helper is unavailable."""
	if not frappe.db.exists("DocType", "Practitioner Schedule"):
		return []
	weekday = _english_weekday(date)
	schedules = _schedule_names_for_practitioner(practitioner)
	if not schedules:
		return []

	slots = []
	booked = _booked_times(practitioner, date)
	for sch_name in schedules:
		try:
			sch = frappe.get_doc("Practitioner Schedule", sch_name)
		except Exception:
			continue
		if sch.get("disabled"):
			continue
		for time_slot in sch.get("time_slots") or []:
			day = ""
			if hasattr(time_slot, "get"):
				day = (time_slot.get("day") or "").strip()
			else:
				day = (getattr(time_slot, "day", None) or "").strip()
			if day and not _day_matches(day, weekday):
				continue
			start = _as_time_str(
				time_slot.get("from_time") if hasattr(time_slot, "get") else getattr(time_slot, "from_time", None)
			)
			end = _as_time_str(
				time_slot.get("to_time") if hasattr(time_slot, "get") else getattr(time_slot, "to_time", None)
			)
			duration = _slot_duration_minutes(time_slot, sch)
			cursor = _parse_time(start)
			end_t = _parse_time(end)
			if not cursor or not end_t or duration <= 0:
				continue
			# Allow a slot that ends exactly on to_time.
			while cursor + timedelta(minutes=duration) <= end_t + timedelta(seconds=1):
				time_str = cursor.strftime("%H:%M:%S")
				slots.append({
					"time": time_str,
					"label": _pretty_time(time_str),
					"available": 0 if time_str in booked else 1,
				})
				cursor += timedelta(minutes=duration)
	# de-dupe by time
	seen = {}
	for s in slots:
		seen[s["time"]] = s
	return [seen[k] for k in sorted(seen.keys())]


def _parse_time(time_str: str):
    try:
        return datetime.strptime(_as_time_str(time_str)[:8], "%H:%M:%S")
    except Exception:
        return None


def _booked_times(practitioner: str, date) -> set[str]:
    rows = frappe.get_all(
        "Patient Appointment",
        filters={
            "practitioner": practitioner,
            "appointment_date": date,
            "status": ["not in", ("Cancelled",)],
        },
        fields=["appointment_time"],
        ignore_permissions=True,
    )
    out = set()
    for r in rows:
        if r.get("appointment_time"):
            out.add(_as_time_str(r.appointment_time))
    return out


def get_available_slots(practitioner: str, days: int = 14, visit_type: str | None = None) -> dict:
    """Slots for the coming *days*, grouped by date, for one practitioner.

    Unavailable (already booked) slots are returned with available=0 so the
    app can grey them out instead of hiding them.
    """
    practitioner = (practitioner or "").strip()
    days = max(1, min(int(days or 14), 31))
    if not practitioner:
        return {
            "success": True,
            "days": [],
            "empty": True,
            "message": "Select a doctor to see available times.",
        }
    if not frappe.db.exists("Healthcare Practitioner", practitioner):
        return {
            "success": True,
            "days": [],
            "empty": True,
            "message": "No schedule found for this doctor.",
        }

    schedule_names = _schedule_names_for_practitioner(practitioner)
    out_days = []
    start = getdate(today())
    now = now_datetime()
    any_slot = False
    for i in range(days):
        d = add_days(start, i)
        payload = _try_healthcare_availability(practitioner, d)
        slots = _slots_from_healthcare_payload(payload)
        if not slots:
            slots = _slots_from_practitioner_schedule(practitioner, d)
        normalised = []
        for s in slots:
            time_str = s["time"]
            available = int(s.get("available") or 0)
            if d == start:
                try:
                    slot_dt = get_datetime(f"{d} {time_str}")
                    if slot_dt <= now:
                        available = 0
                except Exception:
                    pass
            normalised.append({
                "time": time_str,
                "label": s.get("label") or _pretty_time(time_str),
                "available": available,
            })
        if normalised:
            any_slot = True
        weekday = getdate(d).strftime("%a")
        out_days.append({
            "date": str(d),
            "weekday": weekday,
            "day_label": f"{weekday} {getdate(d).day}",
            "slots": normalised,
        })

    empty = not any_slot
    if empty and not schedule_names:
        message = (
            "No schedule is linked to this doctor. "
            "In Desk: Healthcare Practitioner → add a row under "
            "Practitioner Schedules → pick your Practitioner Schedule → Save."
        )
    elif empty:
        message = (
            "Schedule is linked, but no time rows match the next days. "
            "Open Practitioner Schedule and add Time Slots "
            "(Day = Monday…Sunday, From Time / To Time)."
        )
    else:
        message = None
    return {
        "success": True,
        "practitioner": practitioner,
        "schedules": schedule_names,
        "days": out_days,
        "empty": empty,
        "message": message,
    }


def slot_is_bookable(practitioner: str, appointment_date, appointment_time) -> bool:
    """True when this practitioner/date/time is still free."""
    if not practitioner or not appointment_date or not appointment_time:
        return False
    time_str = _as_time_str(appointment_time)
    booked = _booked_times(practitioner, appointment_date)
    if time_str in booked:
        return False
    payload = _try_healthcare_availability(practitioner, appointment_date)
    slots = _slots_from_healthcare_payload(payload)
    if not slots:
        slots = _slots_from_practitioner_schedule(practitioner, appointment_date)
    if not slots:
        return False
    for s in slots:
        if s.get("time") == time_str:
            return bool(s.get("available"))
    return False
