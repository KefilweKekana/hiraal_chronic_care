"""Screenshot the Hiraal EMR desk pages (read-only).

Logs into uat.dagaartech.com with the credentials from env:
  HIRAAL_DESK_USER / HIRAAL_DESK_PASS
and screenshots the staff-facing pages + doctype lists into docs/shots/desk/.
Strictly read-only: it only navigates and screenshots.
"""
import os
import time

from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By

SITE = "https://uat.dagaartech.com"
USER = os.environ.get("HIRAAL_DESK_USER", "Admin")
PASS = os.environ["HIRAAL_DESK_PASS"]

OUT = os.path.join(os.path.dirname(__file__), "..", "docs", "shots", "desk")
os.makedirs(OUT, exist_ok=True)

# (name, path, settle seconds)
PAGES = [
    ("01_desk_home", "/app", 8),
    ("02_clinic_dashboard", "/app/clinic-dashboard", 8),
    ("03_alert_queue", "/app/alert-queue", 6),
    ("04_daily_readings", "/app/daily-readings", 6),
    ("05_patient_management", "/app/patient-management", 6),
    ("06_telemedicine_waiting", "/app/telemedicine-waiting-room", 6),
    ("07_analytics", "/app/analytics-dashboard", 6),
    ("08_daily_reading_list", "/app/daily-reading", 6),
    ("09_alert_list", "/app/chronic-care-alert", 6),
    ("10_medicine_requests", "/app/medicine-request", 6),
    ("11_care_subscriptions", "/app/care-subscription", 6),
    ("12_subscription_payments", "/app/subscription-payment", 6),
    ("13_patient_devices", "/app/patient-device", 6),
    ("14_notification_log", "/app/notification-log", 6),
]

opts = Options()
opts.add_argument("--headless=new")
opts.add_argument("--window-size=1500,950")

driver = webdriver.Chrome(options=opts)


def shot(name):
    driver.save_screenshot(os.path.join(OUT, f"{name}.png"))
    print("shot:", name)


def main():
    driver.get(SITE + "/login")
    time.sleep(4)
    email = driver.find_element(By.ID, "login_email")
    email.send_keys(USER)
    pwd = driver.find_element(By.ID, "login_password")
    pwd.send_keys(PASS)
    pwd.submit()
    time.sleep(10)  # desk boot

    for name, path, settle in PAGES:
        try:
            driver.get(SITE + path)
            time.sleep(settle)
            shot(name)
        except Exception as e:
            print("FAIL", name, e)

    driver.quit()


if __name__ == "__main__":
    main()
