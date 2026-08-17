# Hiraal Lifecare — Testing Guide

**Build:** `hiraal_chronic_care_LIVE.apk` (release-signed, v1+v2, installs on Android 6–15)
**Backend:** https://uat.dagaartech.com (live UAT server)
**Last updated:** 2026-07-02

This guide is for two testers working together:
- **App tester** — uses the phone (takes readings, places orders, pays).
- **ERPNext verifier** — logs into https://uat.dagaartech.com and confirms the data actually arrived.

For every test, the App tester does the steps and the ERPNext verifier checks the "Verify in ERPNext" column. Both must pass.

---

## 0. Before you start (do this once)

| # | Step | Why |
|---|------|-----|
| 0.1 | **Uninstall any older Hiraal app already on the phone**, then install `hiraal_chronic_care_LIVE.apk`. | This build is release-signed. Android blocks upgrading over the old debug-signed app — you must uninstall first or install will fail. |
| 0.2 | Allow all permissions the app asks for: **Bluetooth, Location, Notifications**. | Bluetooth + Location are required to find and connect the BP/glucose device. Notifications are required for alerts and payment reminders. |
| 0.3 | Turn the phone's **Bluetooth ON** and keep the BP monitor charged and nearby. | The measuring/sync tests need a real device. |
| 0.4 | ERPNext verifier: log in at https://uat.dagaartech.com and confirm you can open **Daily Reading**, **Chronic Care Alert**, **Medicine Request**, **Care Subscription** lists. | You'll check these during the tests. |

**Supported measuring devices (Bluetooth):** Andesfit B180, Omron blood pressure, A&D Medical blood pressure, Accu-Chek glucose, Contour glucose, and any standard Bluetooth SIG blood-pressure / glucose / weight device.

**Test patient account:** use a real registered patient's mobile number (the one used to sign in). If you need a fresh test patient, ask the admin to register one first.

---

## 1. Signing up (new patient self-registration)

> **How it works now:** anyone can create their own account in the app. After verifying
> their phone by SMS code, the account is created and they are taken straight to
> **Choose a plan** — they cannot use any features until they subscribe and pay
> (see 1d). Existing clinic-registered patients simply sign in (1c).

### 1a. Create a new account
| # | Step | Expected result | Verify in ERPNext |
|---|------|-----------------|-------------------|
| 1.1 | Open the app. Tap **Get Started**, then on the sign-in screen tap **"New to Hiraal? Create an account."** | The Sign Up form opens. | — |
| 1.2 | Fill in **Full name**, **Gender** (Male/Female), **Date of birth** (date picker), **Mobile number** (country selector defaults to Somaliland +252), optionally **Email**. Tap **Create Account**. | A verification code is sent by SMS to the number; the code-entry screen appears. | — |
| 1.3 | Enter the SMS code. | The account is created and the app goes straight to the **Choose your plan** (paywall) screen. | A new **Patient** (`/app/patient`) with status **Active**, the entered name, gender, DOB, mobile. |
| 1.4 | (Duplicate guard) Try creating another account with the **same phone number**. | The app signs you into the existing account instead of creating a second one. | Still only **one** Patient with that mobile. |

### 1b. Feature gate — no plan, no features
| # | Step | Expected result |
|---|------|-----------------|
| 1.5 | On **Choose your plan**, note there is no way into the app except subscribing or **Sign out**. | You cannot reach Home, readings, orders, etc. until you subscribe. |
| 1.6 | Force-close the app and reopen it (still unsubscribed). | It returns to the **Choose your plan** paywall — the account stays gated until paid. |

### 1c. Existing patient sign-in
| # | Step | Expected result |
|---|------|-----------------|
| 1.7 | Sign in with a phone number that already has an account (Get Started → enter number → SMS/Email code). | If that patient **has an active subscription** → **"You're all set!"** / Home. If they have **no active subscription** → they also land on the **Choose your plan** paywall. |
| 1.8 | Sign in with a number that was never registered or signed up. | After the code, the app shows **"No patient record found"** — steer them to **Create an account** instead. |

### 1d. Subscribe to unlock (from the paywall)
| # | Step | Expected result | Verify in ERPNext |
|---|------|-----------------|-------------------|
| 1.9 | On **Choose your plan**, pick **Standard Care ($5/mo)** or **Premium Care ($10/mo)** and tap **Subscribe & Pay**. | The mobile-money payment screen opens for the chosen amount. | A **Care Subscription** is created (status *Overdue* = awaiting payment). |
| 1.10 | Complete the mobile-money payment (small **real** amount — payments are live). | On approval the app unlocks and goes to **Home**. | Care Subscription = **Active**, with a **Subscription Payment** record. |
| 1.11 | Close and reopen the app. | Biometric unlock → **Home** directly (no paywall now the plan is active). | — |

> ✅ Pass = a new user can self-register, is blocked until they subscribe, and is let straight into the app after a successful payment.

### 1e. Returning sign-in (biometrics)
| # | Step | Expected result |
|---|------|-----------------|
| 1.12 | With an active subscription, close the app fully and reopen. | The app asks for **fingerprint/face unlock** — not the SMS code again. |
| 1.13 | Unlock with biometrics. | Home appears immediately. |

> ⚠️ If the phone has no fingerprint/face set up, the app stays signed in without asking — expected on those devices.

---

## 2. Bluetooth device sync — THE priority test

This is the feature that was broken before. Test it carefully.

### 2a. Live measuring screen
| # | Step | Expected result |
|---|------|-----------------|
| 2.1 | Home → **Devices** (or "Measure"). Tap **Scan**. | The app lists nearby devices. Your BP monitor appears. |
| 2.2 | Tap your device to connect. | Status shows **Connected**. No error banner. |
| 2.3 | Tap **Start Measurement** and let the cuff inflate. | The on-screen gauge shows the pressure **rising in real time** while the cuff inflates (live "Measuring…" screen). |
| 2.4 | Wait for the cuff to finish. | The screen shows the final **SYS / DIA / Pulse** result, then **"Saved to your records."** |

### 2b. The reading actually reaches ERPNext (the real fix)
| # | Step | Expected result | Verify in ERPNext |
|---|------|-----------------|-------------------|
| 2.5 | After 2.4 completes. | Reading appears in the app's history with the correct numbers. | Open **Daily Reading** list (`/app/daily-reading`). Filter by the patient. **Exactly ONE new row** with matching SYS/DIA and Source = *Device* / *Bluetooth*. |
| 2.6 | **Disconnect the device, reconnect, and measure again.** | New result shows and saves. | **Exactly ONE more** Daily Reading row (two total). No duplicates from the reconnect. |
| 2.7 | Take a third reading, then immediately pull-to-refresh the app history. | The three readings all show, newest first. | Three Daily Reading rows total, no repeats. |

> ✅ Pass = each measurement creates **exactly one** Daily Reading in ERPNext, even after disconnect/reconnect.
> ❌ Fail = zero rows appear (sync broken), or the same reading appears 2+ times (duplication).

### 2c. Glucose meter (if testing a glucometer)
| # | Step | Expected result | Verify in ERPNext |
|---|------|-----------------|-------------------|
| 2.8 | Connect an Accu-Chek or Contour glucose meter that already has stored readings. | Stored readings transfer to the app. | Daily Reading rows appear with Blood Sugar values, one per stored reading. |

---

## 3. Manual reading entry

| # | Step | Expected result | Verify in ERPNext |
|---|------|-----------------|-------------------|
| 3.1 | Home → enter a BP reading by hand (e.g. 128/82), optionally blood sugar / weight / "medicine taken", tap Submit. | "Saved" confirmation; reading shows in history. | One new Daily Reading with the values, Source = *App*. **"Medicine Taken" = Yes/No** matches what you chose. |
| 3.2 | Submit the same screen twice quickly (double-tap Submit). | Only one reading is recorded. | Only ONE Daily Reading row, not two. |

---

## 4. Critical reading → alert + nurse task

Tests that a dangerous reading reaches the care team.

| # | Step | Expected result | Verify in ERPNext |
|---|------|-----------------|-------------------|
| 4.1 | Submit a **critical** BP reading (e.g. 186/126) — manually or from the device. | Reading saves normally. | **Daily Reading** row created with Risk Level = *Critical*. |
| 4.2 | Check the care-team side. | — | A **Chronic Care Alert** (`/app/chronic-care-alert`) is created for this patient (Alert Level High/Very High, Status Open), AND a **Nurse Task** (`/app/nurse-task`) linked to that alert. |

> ✅ Pass = critical reading saves **and** raises an alert + nurse task. (Both were previously failing silently.)

---

## 5. Notifications

| # | Step | Expected result |
|---|------|-----------------|
| 5.1 | Have the care team (or admin) send the patient a message/notification from ERPNext. | The phone receives **one** push notification — not two. |
| 5.2 | Open the app → Profile. Look at the bell icon badge. | The badge shows the number of **unread** notifications (not the total count). |
| 5.3 | Open Notifications, read one, go back. | The unread badge count goes down by one. |
| 5.4 | Check the timestamp on a just-received notification. | It says "just now" / "1 min ago" — the correct local time, not hours off. |

> ✅ Pass = single push per event, unread badge is accurate, timestamps correct.

---

## 6. Medicine orders + prescription + payment

| # | Step | Expected result | Verify in ERPNext |
|---|------|-----------------|-------------------|
| 6.1 | Home/Pharmacy → create a medicine order (add items), submit. | Order created, shows in "My Orders" as Pending/Received. | New **Medicine Request** (`/app/medicine-request`) for the patient. |
| 6.2 | Attach a prescription photo to the order. | Upload succeeds; order shows the attachment. | The Medicine Request has the prescription file attached. |
| 6.3 | Admin moves the order to **Awaiting Payment** in ERPNext. | Patient gets a push notification. **Tapping it opens the order's payment screen.** Home screen shows an **amber "Payment pending" banner**. | Order status = Awaiting Payment. |
| 6.4 | Tap **Confirm & Pay**, choose a mobile-money method, enter the wallet number, pay. | USSD/mobile-money prompt; on approval the order flips to Paid. Use a **small real amount** — payments are live. | Order status = Paid, payment reference recorded. |
| 6.5 | When delivered, tap **Confirm Received**. | Order marked received. | Status = Delivered/Received. |

---

## 7. Subscription + payment

| # | Step | Expected result | Verify in ERPNext |
|---|------|-----------------|-------------------|
| 7.1 | Profile → **Subscription**. | Shows current status and the two plans: **Standard Care $5/mo** and **Premium Care $10/mo** (different prices). | — |
| 7.2 | Subscribe to a plan, then pay it with mobile money (small real amount). | Payment prompt; on approval the subscription becomes **Active**. | **Care Subscription** (`/app/care-subscription`) for the patient = Active, with a **Subscription Payment** record. |
| 7.3 | View payment history in the app. | The payment just made is listed. | Matches the Subscription Payment records. |

---

## 8. Offline behaviour (sync resilience)

| # | Step | Expected result | Verify in ERPNext |
|---|------|-----------------|-------------------|
| 8.1 | Put the phone in **Airplane mode**. Take a device reading OR enter one manually. | Reading saves locally and shows in history (may show a "pending" state). | Nothing yet (offline). |
| 8.2 | Turn Airplane mode **off**, wait a moment, then reopen the app / pull to refresh. | The pending reading uploads automatically. | The reading now appears as **one** Daily Reading (not duplicated). |

> ✅ Pass = readings taken offline reach ERPNext once connectivity returns, with no duplicates.

---

## 9. Security check (ERPNext verifier / admin)

Confirms a patient can't see clinic-wide data. Best done by someone who understands ERPNext roles.

| # | Step | Expected result |
|---|------|-----------------|
| 9.1 | While logged into ERPNext **as a patient account** (Website User), try to open the Clinic Dashboard or another patient's profile via a direct link. | Access is **denied** (permission error). Patients can only see their own data. |
| 9.2 | Log in as clinic staff (nurse/doctor/admin). | Clinic Dashboard, Alert Queue, Analytics, and all patient profiles open normally. |

---

## 10. Sign out / device handover

| # | Step | Expected result |
|---|------|-----------------|
| 10.1 | Profile → Sign out. | Returns to sign-in. |
| 10.2 | After signing out, have the care team send that patient a notification. | The signed-out phone should **NOT** receive it (push tokens are disabled on logout — important if a phone is shared or handed over). |

---

## Known limitations in this build (not bugs)

- **Appointment booking** may fail with "Please Configure OP Consulting Charge" for a practitioner who has no consulting fee set. Admin must set a consulting charge on each practitioner before appointments work for them.
- **Auto-renewal does not silently charge.** When a subscription is due, the patient gets a reminder to pay in the app — mobile money can't be auto-debited. This is intended.
- Payments are **live** — use small real amounts for testing.

---

## How to report a problem

For each failed test, capture:
1. **Test number** (e.g. 2.6) and what you did.
2. **What you expected** vs **what actually happened**.
3. A **screenshot** or short screen recording (especially for the measuring screen and any error message).
4. The **exact reading numbers / order / amount** involved and the **time** (so we can find it on the server).
5. Phone model + Android version.

Send these together — the timestamp + patient + numbers let us trace the exact record on the server.
