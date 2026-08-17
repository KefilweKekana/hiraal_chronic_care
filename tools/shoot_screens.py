"""Final screenshot walk — Flutter web mock build via CDP taps.
Prereq: mock web build served on http://localhost:8090 (hcc_src harness).
"""
import os
import time

from selenium import webdriver
from selenium.webdriver.chrome.options import Options

BASE = "http://localhost:8090"
OUT = os.path.join(os.path.dirname(__file__), "..", "docs", "shots")
os.makedirs(OUT, exist_ok=True)

opts = Options()
opts.add_argument("--headless=new")
opts.add_argument("--window-size=430,930")
opts.add_argument("--force-device-scale-factor=2")

driver = webdriver.Chrome(options=opts)
VW = VH = 0


def tap(fx, fy, settle=1.0):
    x, y = int(VW * fx), int(VH * fy)
    for t in ("mousePressed", "mouseReleased"):
        driver.execute_cdp_cmd("Input.dispatchMouseEvent", {
            "type": t, "x": x, "y": y, "button": "left", "clickCount": 1,
        })
    time.sleep(settle)


def scroll(dy=700, settle=0.8):
    driver.execute_cdp_cmd("Input.dispatchMouseEvent", {
        "type": "mouseWheel", "x": int(VW * 0.5), "y": int(VH * 0.5),
        "deltaX": 0, "deltaY": dy,
    })
    time.sleep(settle)


def type_text(text):
    driver.switch_to.active_element.send_keys(text)
    time.sleep(0.4)


def shot(name):
    driver.save_screenshot(os.path.join(OUT, f"{name}.png"))
    print("shot:", name)


BACK = (0.06, 0.05)


def main():
    global VW, VH
    driver.get(BASE)
    time.sleep(10)
    VW = driver.execute_script("return window.innerWidth")
    VH = driver.execute_script("return window.innerHeight")

    # ── Auth ──
    shot("01_welcome")
    tap(0.50, 0.875, 1.5)
    shot("02_register")
    tap(0.62, 0.49, 0.5)
    type_text("612345678")
    tap(0.50, 0.82, 2.5)
    shot("03_otp")
    time.sleep(2)
    tap(0.50, 0.66, 5)
    shot("04_home")

    # ── Notifications ──
    tap(0.925, 0.05, 2)
    shot("05_notifications")
    tap(*BACK, settle=1.5)

    # ── Appointments ──
    tap(0.50, 0.255, 2)
    shot("06_appointments")
    tap(*BACK, settle=1.5)

    # ── Services + category-filtered booking ──
    tap(0.375, 0.955, 2)
    shot("07_services")
    scroll(); scroll()
    shot("07b_categories")
    tap(0.14, 0.82, 2.5)           # Heart Care chip
    shot("08_book_doctor_filtered")
    tap(*BACK, settle=1.5)

    # ── History ──
    tap(0.625, 0.955, 2)
    shot("09_history")

    # ── Profile + Payments + Settings + Lab Tests + Orders ──
    tap(0.875, 0.955, 2)
    shot("10_profile")
    scroll(); scroll()
    shot("10b_profile_bottom")
    tap(0.5, 0.555, 2)             # Payments row
    shot("11_payments")
    tap(0.5, 0.30, 1.5)            # first payment → receipt sheet
    shot("11b_receipt")
    tap(0.5, 0.96, 1)              # close sheet (tap scrim)
    tap(*BACK, settle=1.5)
    tap(0.5, 0.30, 2)              # Lab Tests activity card
    shot("12_my_lab_tests")
    tap(0.5, 0.22, 1.5)            # first test → details sheet
    shot("12b_lab_detail")
    tap(0.5, 0.96, 1)              # close sheet
    tap(*BACK, settle=1.5)
    tap(0.5, 0.735, 2)             # Settings row
    shot("13_settings")
    tap(*BACK, settle=1.5)
    tap(0.82, 0.30, 2)             # Orders activity card
    shot("14_my_orders")
    tap(*BACK, settle=1.5)

    # ── Payment flow ──
    tap(0.125, 0.955, 1.5)         # Home tab
    tap(0.50, 0.145, 2.5)          # Payment pending banner
    shot("15_track_order")
    scroll(); scroll(); scroll()
    shot("15b_track_bottom")
    tap(0.5, 0.82, 2)              # Confirm & Pay
    shot("16_pay_form")
    tap(0.5, 0.68, 0.5)            # wallet field
    type_text("634063505")
    shot("16b_pay_filled")
    tap(0.5, 0.86, 3)              # Pay → waiting
    shot("17_pay_waiting")
    time.sleep(8)                  # mock completes
    shot("18_pay_success")

    driver.quit()


if __name__ == "__main__":
    main()
