"""Payment-flow-only screenshot pass (mock mode)."""
import os
import time

from selenium import webdriver
from selenium.webdriver.chrome.options import Options

BASE = "http://localhost:8090"
OUT = os.path.join(os.path.dirname(__file__), "..", "docs", "shots")

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


def main():
    global VW, VH
    driver.get(BASE)
    time.sleep(10)
    VW = driver.execute_script("return window.innerWidth")
    VH = driver.execute_script("return window.innerHeight")

    # login
    tap(0.50, 0.875, 1.5)
    tap(0.62, 0.49, 0.5)
    type_text("612345678")
    tap(0.50, 0.82, 2.5)
    time.sleep(2)
    tap(0.50, 0.66, 5)

    # payment flow
    tap(0.50, 0.145, 2.5)          # Payment pending banner
    scroll(); scroll(); scroll()
    tap(0.5, 0.82, 2)              # Confirm & Pay
    shot("16_pay_form")
    tap(0.5, 0.81, 0.5)            # wallet number field
    type_text("634063505")
    shot("16b_pay_filled")
    tap(0.5, 0.91, 3)              # Pay → waiting
    shot("17_pay_waiting")
    time.sleep(8)                  # mock completes
    shot("18_pay_success")

    driver.quit()


if __name__ == "__main__":
    main()
