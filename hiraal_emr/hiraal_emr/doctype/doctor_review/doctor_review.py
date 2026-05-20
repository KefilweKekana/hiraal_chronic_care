import frappe
from frappe.model.document import Document
from frappe.utils import add_days, add_to_date, now_datetime, today


class DoctorReview(Document):
    def validate(self):
        self.compute_clinical_summary()
        self.set_next_review_date()

    def before_save(self):
        if self.has_value_changed("review_status") and self.review_status == "Reviewed":
            self.reviewed_at = now_datetime()

    def compute_clinical_summary(self):
        """Pull 7-day stats from Daily Reading for this patient."""
        seven_days_ago = add_days(today(), -7)

        readings = frappe.get_all(
            "Daily Reading",
            filters={
                "patient": self.patient,
                "reading_date": [">=", seven_days_ago],
            },
            fields=["bp_systolic", "bp_diastolic", "blood_sugar", "blood_sugar_unit", "medicine_taken", "reading_date", "risk_level"],
            order_by="reading_date desc",
            limit=50,
        )

        if not readings:
            return

        # Latest reading
        latest = readings[0]
        if latest.bp_systolic and latest.bp_diastolic:
            self.latest_bp = f"{latest.bp_systolic}/{latest.bp_diastolic} mmHg"
        if latest.blood_sugar:
            unit = latest.blood_sugar_unit or "mg/dL"
            self.latest_sugar = f"{latest.blood_sugar} {unit}"

        # Averages
        bp_vals = [(r.bp_systolic, r.bp_diastolic) for r in readings if r.bp_systolic and r.bp_diastolic]
        if bp_vals:
            avg_sys = sum(v[0] for v in bp_vals) // len(bp_vals)
            avg_dia = sum(v[1] for v in bp_vals) // len(bp_vals)
            self.avg_bp_7days = f"{avg_sys}/{avg_dia}"

        sugar_vals = [r.blood_sugar for r in readings if r.blood_sugar]
        if sugar_vals:
            self.avg_sugar_7days = round(sum(sugar_vals) / len(sugar_vals), 1)

        self.readings_submitted_7days = len(readings)
        self.high_readings_7days = len([r for r in readings if r.risk_level in ("High", "Critical")])

        # Missed days
        reading_dates = set(str(r.reading_date) for r in readings)
        all_days = set()
        for i in range(7):
            all_days.add(str(add_days(today(), -i)))
        self.missed_days = len(all_days - reading_dates)

        # Medicine adherence (30 days)
        thirty_days_ago = add_days(today(), -30)
        med_readings = frappe.get_all(
            "Daily Reading",
            filters={"patient": self.patient, "reading_date": [">=", thirty_days_ago]},
            fields=["medicine_taken"],
        )
        if med_readings:
            taken = len([r for r in med_readings if r.medicine_taken == "Yes"])
            self.medicine_adherence = round((taken / len(med_readings)) * 100, 1)

    def set_next_review_date(self):
        if self.follow_up_interval and not self.next_review_date:
            interval_map = {
                "1 Week": {"weeks": 1},
                "2 Weeks": {"weeks": 2},
                "1 Month": {"months": 1},
                "3 Months": {"months": 3},
            }
            delta = interval_map.get(self.follow_up_interval)
            if delta:
                self.next_review_date = add_to_date(today(), **delta)
