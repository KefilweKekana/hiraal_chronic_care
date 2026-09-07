"""Appointment slots from ERPNext Healthcare Practitioner Schedule.

Wraps Healthcare's availability logic. Never invents slots: if the site has
no Practitioner Schedule, return an empty-state payload the app can render.
"""

from __future__ import annotations

from datetime import datetime, timedelta

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
        avail = block.get("avail_slot") or block.get("available_slots") or block.get("slots") or []
        booked = {
            str(s.get("from_time") or s.get("appointment_time") or s)
            for s in (block.get("appointments") or block.get("booked") or [])
            if s
        }
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
            is_free = bool(available) and time_str not in booked
            slots.append({
                "time": time_str,
                "label": _pretty_time(time_str),
                "available": 1 if is_free else 0,
            })
    return slots


def _as_time_str(value) -> str:
    raw = str(value)
    if " " in raw:
        raw = raw.split(" ")[-1]
    parts = raw.split(":")
    if len(parts) >= 2:
        return f"{int(parts[0]):02d}:{int(parts[1]):02d}:00"
    return raw


def _pretty_time(time_str: str) -> str:
    try:
        t = datetime.strptime(time_str[:8], "%H:%M:%S")
        return t.strftime("%I:%M %p").lstrip("0")
    except Exception:
        return time_str


def _slots_from_practitioner_schedule(practitioner: str, date) -> list[dict]:
    """Read Practitioner Schedule child table when Healthcare helper is unavailable."""
    if not frappe.db.exists("DocType", "Practitioner Schedule"):
        return []
    weekday = getdate(date).strftime("%A")
    schedules = []
    try:
        pract = frappe.get_doc("Healthcare Practitioner", practitioner)
        for row in pract.get("practitioner_schedules") or []:
            if row.get("schedule"):
                schedules.append(row.get("schedule"))
    except Exception:
        frappe.logger("hiraal_slots").exception("load practitioner schedules failed")

    if not schedules:
        return []

    slots = []
    booked = _booked_times(practitioner, date)
    for sch_name in schedules:
        try:
            sch = frappe.get_doc("Practitioner Schedule", sch_name)
        except Exception:
            continue
        for time_slot in sch.get("time_slots") or []:
            day = (time_slot.get("day") or "").strip()
            if day and day.lower() != weekday.lower():
                continue
            start = _as_time_str(time_slot.get("from_time"))
            end = _as_time_str(time_slot.get("to_time"))
            duration = int(time_slot.get("duration") or sch.get("duration") or 30)
            cursor = _parse_time(start)
            end_t = _parse_time(end)
            if not cursor or not end_t:
                continue
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
        return datetime.strptime(time_str[:8], "%H:%M:%S")
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
        # Drop times that have already passed today; keep them disabled rather
        # than hidden when they are in the past on the same day.
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
    return {
        "success": True,
        "practitioner": practitioner,
        "days": out_days,
        "empty": empty,
        "message": (
            "No available times yet. Ask the clinic to set a Practitioner Schedule."
            if empty
            else None
        ),
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
        # No schedule published for this day.
        return False
    for s in slots:
        if s.get("time") == time_str:
            return bool(s.get("available"))
    return False
