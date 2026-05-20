/* Hiraal EMR — Global JS
   Loaded via app_include_js in hooks.py */

// Real-time alert notifications
frappe.realtime.on("chronic_care_alert", function (data) {
  frappe.show_alert(
    {
      message: `<strong>🚨 ${data.alert_level} Alert:</strong> ${data.patient_name} — ${data.reading}`,
      indicator: data.alert_level === "Very High" ? "red" : "orange",
    },
    10
  );
});

frappe.realtime.on("nurse_task_assigned", function (data) {
  frappe.show_alert(
    {
      message: `<strong>📋 New Task:</strong> ${data.type} for ${data.patient}`,
      indicator: "blue",
    },
    7
  );
});
