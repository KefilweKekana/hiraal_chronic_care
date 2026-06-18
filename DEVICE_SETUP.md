# Connecting BLE Devices (BP Monitor & Glucometer)

How to register a Bluetooth health device so the Hiraal app can connect to it,
read measurements, and file them as Daily Readings.

---

## Step 1 — Register the device protocol (per machine)

In ERPNext: **`/app/ble-device-protocol` → New**. Create **one record per machine**.
This tells the app how to find the device (by Bluetooth name) and decode its data.

### Blood Pressure monitor
| Field | Value |
|-------|-------|
| Protocol Name | e.g. `BP Monitor – <brand>` |
| Device Type | `Blood Pressure` |
| Parser Type | `standard_bp` |
| Delivery Mode | `indicate` |
| Name Keywords | part of the cuff's Bluetooth name (e.g. `BP`, brand, model) |
| Is Active | ✓ |
| **Service UUIDs** (table) | `00001810-0000-1000-8000-00805f9b34fb` |
| **Characteristics** (table) | `00002a35-0000-1000-8000-00805f9b34fb` |

### Glucometer (diabetic)
| Field | Value |
|-------|-------|
| Protocol Name | e.g. `Glucometer – <brand>` |
| Device Type | `Blood Sugar` |
| Parser Type | `standard_glucose` |
| Delivery Mode | `notify` |
| Name Keywords | part of the meter's Bluetooth name |
| Is Active | ✓ |
| **Service UUIDs** (table) | `00001808-0000-1000-8000-00805f9b34fb` |
| **Characteristics** (table) | `00002a18-0000-1000-8000-00805f9b34fb` |

> The UUIDs above are the **standard Bluetooth GATT health profiles** (Blood
> Pressure = 0x1810/0x2A35, Glucose = 0x1808/0x2A18). Many devices use them.
> Some use proprietary UUIDs — see Troubleshooting.

After saving, **reopen/restart the app** so it reloads the protocol list
(the app fetches these on startup via `get_ble_protocols`).

---

## Step 2 — Connect & test from the app

1. Open the app → **Devices → Connect Device**.
2. The app scans Bluetooth and matches your machine by **Name Keywords**.
3. Tap to pair — this auto-creates a **Patient Device** record and links it to
   the patient.
4. Take a reading on the machine; the app receives and submits it.

---

## Step 3 — Where the reading lands

A successful reading creates a **Daily Reading** with:
- **Source** = `BP Device` (or `Glucometer`)
- **Source Device** = the linked Patient Device

View it on the desk at **`/app/daily-reading`**, or in the patient's history in
the app.

---

## Troubleshooting

- **Device won't connect / not found:** the machine probably uses non-standard
  UUIDs. Scan it with a free BLE app (**nRF Connect**) to read its real
  **advertised name**, **service UUID**, and **characteristic UUID**, then put
  those exact values into the protocol record (and make sure **Name Keywords**
  matches the advertised name).
- **Connects but no glucose reading appears:** some meters need a kick-off
  command. Add an **Init Step** in the protocol's **Init Sequence** table:
  Record Access Control Point `00002a52-0000-1000-8000-00805f9b34fb`,
  command *report stored records*.
- **Wrong protocol matches:** make **Name Keywords** specific enough that the BP
  and glucometer don't match each other's keyword.
- **Reading not saved:** confirm the device is paired to the correct patient
  (check the **Patient Device** record's `patient` field) and that the protocol
  is **Is Active**.
