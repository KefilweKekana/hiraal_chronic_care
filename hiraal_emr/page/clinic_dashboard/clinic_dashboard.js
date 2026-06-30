(function () {
// ─── Calm Clinical dashboard (design handoff 1A) ───
// Full app frame (top bar + sidebar + main) rendered inside the desk page,
// wired to the real hiraal_emr.api.get_dashboard_data. No mock data.

function ensureFonts() {
  if (document.getElementById("hiraal-dash-fonts")) return;
  const l = document.createElement("link");
  l.id = "hiraal-dash-fonts";
  l.rel = "stylesheet";
  l.href =
    "https://fonts.googleapis.com/css2?family=Hanken+Grotesk:wght@400;500;600;700" +
    "&family=Material+Symbols+Rounded:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200&display=swap";
  document.head.appendChild(l);
}

const LOGO = "/assets/hiraal_emr/images/hiraal_logo.png";

// Sidebar nav model — groups, labels, icons, routes (Dashboard is active here).
const NAV = [
  { items: [
    { label: "Dashboard", icon: "dashboard", route: "/app/clinic-dashboard", name: "dashboard" },
    { label: "Alerts", icon: "notifications_active", route: "/app/chronic-care-alert", name: "alerts" },
    { label: "Patients", icon: "groups", route: "/app/patient", name: "patients" },
    { label: "Daily Readings", icon: "vital_signs", route: "/app/daily-reading", name: "daily-readings" },
    { label: "Nurse Tasks", icon: "task_alt", route: "/app/nurse-task", name: "nurse-tasks" },
    { label: "Doctor Review", icon: "stethoscope", route: "/app/doctor-review", name: "doctor-review" },
    { label: "Appointments", icon: "calendar_month", route: "/app/patient-appointment", name: "appointments" },
    { label: "Lab Requests", icon: "science", route: "/app/lab-test", name: "lab-requests" },
    { label: "Medicine Requests", icon: "medication", route: "/app/medicine-request", name: "medicine-requests" },
    { label: "Devices", icon: "devices", route: "/app/patient-device", name: "devices" },
    { label: "Telemedicine", icon: "video_camera_front", route: "/app/telemedicine-waiting-room", name: "telemedicine" },
  ]},
  { label: "BILLING", items: [
    { label: "Subscriptions", icon: "card_membership", route: "/app/care-subscription", name: "subscriptions" },
    { label: "Payments", icon: "payments", route: "/app/subscription-payment", name: "payments" },
  ]},
  { label: "REPORTS", items: [
    { label: "Reports", icon: "description", route: "/app/query-report/Patient Summary", name: "reports" },
    { label: "Analytics", icon: "analytics", route: "/app/analytics-dashboard", name: "analytics" },
  ]},
  { label: "SETTINGS", items: [
    { label: "Settings", icon: "settings", route: "/app/chronic-care-settings", name: "settings" },
    { label: "User Management", icon: "manage_accounts", route: "/app/user", name: "user-management" },
  ]},
];

frappe.pages["clinic-dashboard"].on_page_load = function (wrapper) {
  ensureFonts();
  const page = frappe.ui.make_app_page({
    parent: wrapper,
    title: "Clinic Dashboard",
    single_column: true,
  });
  // Clean canvas — the design provides its own header/frame.
  $(wrapper).find(".page-head").hide();
  page.main.html('<div id="clinic-dashboard-root"></div>');
  new ClinicDashboard(page);
};

class ClinicDashboard {
  constructor(page) {
    this.page = page;
    this.container = page.main.find("#clinic-dashboard-root");
    this.renderShell('<div class="hd-loading">Loading dashboard…</div>');
    this.load_data();
  }

  async load_data() {
    try {
      this.data = await frappe.xcall("hiraal_emr.api.get_dashboard_data");
      this.render_dashboard();
    } catch (e) {
      console.error("Dashboard load error:", e);
      this.renderShell('<div class="hd-loading">Could not load dashboard data.</div>');
    }
  }

  // ── helpers ─────────────────────────────────────────────
  esc(s) {
    return (s == null ? "" : String(s)).replace(/[&<>"']/g, (c) =>
      ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
  }
  n(v) { return v == null ? 0 : v; }
  initials(name) {
    if (!name) return "?";
    return name.trim().split(/\s+/).map((p) => p[0]).join("").toUpperCase().slice(0, 2);
  }
  avatarColor(name) {
    const colors = ["#0c6b62", "#2563EB", "#16A34A", "#D97706", "#9333EA", "#0D9488", "#DB2777", "#c05a3f"];
    let h = 0;
    for (let i = 0; i < (name || "").length; i++) h = name.charCodeAt(i) + ((h << 5) - h);
    return colors[Math.abs(h) % colors.length];
  }
  alertClass(level) {
    return { "Very High": "very-high", High: "high", Medium: "medium", Low: "low" }[level] || "low";
  }
  msr(name) { return '<span class="msr">' + name + "</span>"; }

  // ── shell (topbar + sidebar + main slot) ────────────────
  renderShell(mainHtml) {
    this.container.html(
      '<div class="hiraal-dash"><div class="hiraal-dash-wrap"><div class="hd-frame">' +
        this.topbar() +
        '<div class="hd-body">' + this.sidebar() + '<main class="hd-main">' + mainHtml + "</main></div>" +
      "</div></div></div>"
    );
  }

  topbar() {
    return (
      '<div class="hd-topbar">' +
        '<div class="hd-brand"><img class="hd-brand-img" src="' + LOGO + '" alt="Hiraal Care">' +
          '<span class="hd-brand-name">Hiraal Care</span></div>' +
        '<form class="hd-search" data-search>' + this.msr("search") +
          '<input class="hd-search-input" type="text" autocomplete="off" ' +
          'placeholder="Search patients by name…">' +
          '<span class="hd-search-chip">⌘G</span></form>' +
      "</div>"
    );
  }

  sidebar() {
    let nav = "";
    NAV.forEach((group) => {
      if (group.label) nav += '<div class="hd-nav-label">' + group.label + "</div>";
      group.items.forEach((i) => {
        const active = i.name === "dashboard" ? " active" : "";
        nav += '<a class="hd-nav-item' + active + '" href="' + i.route + '">' +
          this.msr(i.icon) + "<span>" + i.label + "</span></a>";
      });
    });
    return (
      '<aside class="hd-sidebar">' +
        '<div class="hd-side-head"><img class="hd-side-img" src="' + LOGO + '" alt="Hiraal Care">' +
          '<div><div class="hd-side-title">Hiraal Care</div>' +
          '<div class="hd-side-sub">Health Clinic</div></div></div>' +
        '<nav class="hd-nav">' + nav + "</nav>" +
        '<div class="hd-help"><div class="hd-help-card">' +
          '<div class="hd-help-title">' + this.msr("support_agent") + "Need help?</div>" +
          '<div class="hd-help-contact">Contact Support</div>' +
          '<div class="hd-help-email">support@dagaar.so</div></div></div>' +
      "</aside>"
    );
  }

  // ── main content ────────────────────────────────────────
  render_dashboard() {
    const d = this.data || {};
    const today = frappe.datetime.str_to_user(frappe.datetime.get_today());

    const main =
      '<div class="hd-page-head">' +
        '<h1 class="hd-h1">Clinic Dashboard</h1>' +
        '<span class="hd-datechip">' + today + "</span>" +
        '<button class="hd-refresh" data-refresh>' + this.msr("refresh") + "Refresh</button>" +
      "</div>" +
      this.kpiRow(d) +
      '<div class="hd-2col">' + this.alertsPanel(d) + this.trendsPanel(d) + "</div>" +
      this.secondaryRow(d) +
      '<div class="hd-2col-13">' + this.appointmentsPanel(d) + this.activityPanel(d) + "</div>";

    this.renderShell(main);
    this.container.find("[data-refresh]").on("click", () => {
      this.renderShell('<div class="hd-loading">Refreshing…</div>');
      this.load_data();
    });
    this.bindSearch();
    this.renderChart();
  }

  bindSearch() {
    const form = this.container.find("[data-search]");
    const input = form.find(".hd-search-input");
    // Click anywhere on the pill focuses the field.
    form.on("click", () => input.trigger("focus"));
    form.on("submit", (e) => {
      e.preventDefault();
      const q = (input.val() || "").trim();
      if (!q) return;
      // Search patients by name (most common clinic lookup). A PID goes straight
      // to that patient; otherwise open the Patient list filtered by name.
      if (/^PID/i.test(q)) {
        frappe.set_route("Form", "Patient", q.toUpperCase());
      } else {
        frappe.set_route("List", "Patient", { patient_name: ["like", "%" + q + "%"] });
      }
    });
  }

  kpiCard({ value, label, icon, chip, delta, deltaClass, route }) {
    const open = route ? '<a class="hd-kpi" href="' + route + '">' : '<div class="hd-kpi">';
    const close = route ? "</a>" : "</div>";
    return (
      open + '<div class="hd-kpi-icon ' + chip + '">' + this.msr(icon) + "</div>" +
      '<div class="hd-kpi-value">' + this.n(value) + "</div>" +
      '<div class="hd-kpi-label">' + label + "</div>" +
      (delta ? '<div class="hd-kpi-delta ' + (deltaClass || "muted") + '">' + delta + "</div>" : "") +
      close
    );
  }

  kpiRow(d) {
    // Today's submissions delta — honest, from the real submissions_change %.
    const sc = this.n(d.submissions_change);
    let subDelta, subClass;
    if (sc > 0) { subDelta = "↑ " + sc + "% from yesterday"; subClass = "good"; }
    else if (sc < 0) { subDelta = "↓ " + Math.abs(sc) + "% from yesterday"; subClass = "muted"; }
    else { subDelta = "Same as yesterday"; subClass = "muted"; }

    return (
      '<div class="hd-kpi-row">' +
        this.kpiCard({ value: d.active_patients, label: "Active Patients", icon: "groups", chip: "chip-teal",
          delta: "↑ " + this.n(d.new_patients_month) + " this month", deltaClass: "good", route: "/app/patient" }) +
        this.kpiCard({ value: d.todays_submissions, label: "Today's Submissions", icon: "assignment", chip: "chip-neutral",
          delta: subDelta, deltaClass: subClass, route: "/app/daily-reading" }) +
        this.kpiCard({ value: d.high_risk_alerts, label: "High-Risk Alerts", icon: "warning", chip: "chip-danger",
          delta: this.n(d.new_alerts) + " new", deltaClass: "muted", route: "/app/chronic-care-alert?status=Open" }) +
        this.kpiCard({ value: d.missed_submissions, label: "Missed Submissions", icon: "schedule", chip: "chip-amber",
          delta: "of " + this.n(d.active_patients) + " active patients", deltaClass: "amber", route: "/app/patient" }) +
        this.kpiCard({ value: d.unpaid_subscriptions, label: "Unpaid Subscriptions", icon: "credit_card", chip: "chip-neutral",
          delta: "View Details →", deltaClass: "teal", route: "/app/care-subscription?status=Overdue" }) +
      "</div>"
    );
  }

  alertsPanel(d) {
    const alerts = d.priority_alerts || [];
    let body;
    if (!alerts.length) {
      body =
        '<div class="hd-empty"><div class="hd-empty-icon chip-green">' + this.msr("check_circle") + "</div>" +
        '<div class="hd-empty-text">No high priority alerts right now</div></div>';
    } else {
      const cols = "grid-template-columns:1.4fr 1.4fr 1.2fr 0.8fr 1fr";
      let rows = "";
      alerts.forEach((a) => {
        rows +=
          '<div class="hd-trow" style="' + cols + '">' +
            '<span class="hd-pt-cell"><span class="hd-pt-avatar" style="background:' + this.avatarColor(a.patient_name) + '">' +
              this.initials(a.patient_name) + '</span><span><span class="hd-pt-name">' + this.esc(a.patient_name) +
              '</span><br><span class="hd-pt-id">' + this.esc(a.patient) + "</span></span></span>" +
            "<span>" + this.esc(a.latest_reading_display || "—") + "</span>" +
            '<span><span class="hd-reason ' + this.alertClass(a.alert_level) + '"><span class="dot"></span>' +
              this.esc(a.alert_type) + "</span></span>" +
            '<span class="hd-cell-muted">' + frappe.datetime.prettyDate(a.creation) + "</span>" +
            '<span class="hd-cell-muted">' + this.esc(a.assigned_nurse_name || "—") + "</span>" +
          "</div>";
      });
      body =
        '<div class="hd-thead" style="' + cols + '"><span>PATIENT</span><span>LATEST READING</span>' +
        "<span>REASON</span><span>TIME</span><span>ASSIGNED</span></div>" + rows;
    }
    const warn =
      '<div class="hd-warn">' + this.msr("notifications_active") +
      "Patients flagged at-risk need a follow-up review soon.</div>";

    return (
      '<div class="hd-panel">' +
        '<div class="hd-panel-head"><h2 class="hd-panel-title">High Priority Alerts</h2>' +
          '<span class="hd-badge">' + this.n(d.high_risk_alerts) + "</span>" +
          '<a class="hd-link right" href="/app/chronic-care-alert?alert_level=Very%20High&status=Open">View All</a></div>' +
        body + warn +
      "</div>"
    );
  }

  trendsPanel(d) {
    const tw = this.n(d.alerts_this_week), lw = this.n(d.alerts_last_week);
    const pct = Math.round(((tw - lw) / Math.max(lw, 1)) * 100);
    const down = tw <= lw;
    const changeTxt = (pct >= 0 ? "+" : "") + pct + "%";
    return (
      '<div class="hd-panel">' +
        '<div class="hd-panel-head sb"><h2 class="hd-panel-title">Alert Trends</h2>' +
          '<span class="hd-subtle">This week</span></div>' +
        '<div class="hd-legend">' +
          '<span class="item"><span class="ldot" style="background:#c0413f"></span>High</span>' +
          '<span class="item"><span class="ldot" style="background:#d99b2c"></span>Medium</span>' +
          '<span class="item"><span class="ldot" style="background:#0c8a5e"></span>Low</span></div>' +
        '<div class="hd-chart" id="hd-trend-chart"></div>' +
        '<div class="hd-trend-stats">' +
          '<div><div class="hd-trend-stat-val">' + tw + '</div><div class="hd-trend-stat-lbl">This week</div></div>' +
          '<div><div class="hd-trend-stat-val">' + lw + '</div><div class="hd-trend-stat-lbl">Last week</div></div>' +
          '<div><div class="hd-trend-stat-val' + (down ? " good" : "") + '">' + changeTxt + "</div>" +
            '<div class="hd-trend-stat-lbl' + (down ? " good" : "") + '">' + (down ? "↓" : "↑") + " vs last week</div></div>" +
        "</div>" +
      "</div>"
    );
  }

  secondaryRow(d) {
    const card = (value, label, sub, icon, chip, route, subClass) =>
      '<a class="hd-skpi" href="' + route + '"><div class="hd-skpi-icon ' + chip + '">' + this.msr(icon) + "</div>" +
      '<div><div class="hd-skpi-value">' + this.n(value) + "</div>" +
      '<div class="hd-skpi-label">' + label + "</div>" +
      '<div class="hd-skpi-sub ' + (subClass || "") + '">' + sub + "</div></div></a>";
    return (
      '<div class="hd-skpi-row">' +
        card(d.appointments_today, "Appointments Today", this.n(d.appointments_upcoming) + " upcoming", "event", "chip-neutral", "/app/patient-appointment") +
        card(d.lab_requests_total, "Lab Requests", this.n(d.lab_requests_pending) + " pending", "science", "chip-teal", "/app/lab-test", "amber") +
        card(d.medicine_requests_total, "Medicine Requests", this.n(d.medicine_requests_pending) + " pending", "medication", "chip-pink", "/app/medicine-request", "amber") +
        card(d.nurse_tasks_total, "Nurse Tasks", this.n(d.nurse_tasks_pending) + " pending", "task_alt", "chip-green", "/app/nurse-task") +
        card(d.patients_at_risk, "Patients at Risk", this.n(d.patients_high_risk) + " high risk", "monitor_heart", "chip-coral", "/app/chronic-care-alert?status=Open") +
      "</div>"
    );
  }

  appointmentsPanel(d) {
    const appts = d.todays_appointments || [];
    let body;
    if (!appts.length) {
      body =
        '<div class="hd-empty"><div class="hd-empty-icon chip-neutral">' + this.msr("calendar_today") + "</div>" +
        '<div class="hd-empty-text">No appointments today</div></div>';
    } else {
      const cols = "grid-template-columns:0.8fr 1.4fr 1fr 1.2fr 0.9fr";
      let rows = "";
      appts.forEach((a) => {
        const st = (a.status || "").toLowerCase();
        rows +=
          '<div class="hd-trow" style="' + cols + '">' +
            '<span class="hd-time-badge">' + this.esc(a.appointment_time || "—") + "</span>" +
            '<span class="hd-pt-cell"><span class="hd-pt-avatar" style="background:' + this.avatarColor(a.patient_name) + '">' +
              this.initials(a.patient_name) + '</span><span class="hd-pt-name">' + this.esc(a.patient_name) + "</span></span>" +
            "<span>" + this.esc(a.appointment_type || "Visit") + "</span>" +
            '<span class="hd-cell-muted">' + this.esc(a.practitioner_name || "—") + "</span>" +
            '<span><span class="hd-status-pill ' + st + '">' + this.esc(a.status || "—") + "</span></span>" +
          "</div>";
      });
      body =
        '<div class="hd-thead" style="' + cols + '"><span>TIME</span><span>PATIENT</span>' +
        "<span>TYPE</span><span>PROVIDER</span><span>STATUS</span></div>" + rows;
    }
    return (
      '<div class="hd-panel">' +
        '<div class="hd-panel-head sb"><h2 class="hd-panel-title">Today\'s Appointments</h2>' +
          '<a class="hd-link" href="/app/patient-appointment">View Calendar</a></div>' +
        body +
        '<a class="hd-foot-link" href="/app/patient-appointment">View All Appointments →</a>' +
      "</div>"
    );
  }

  activityPanel(d) {
    const acts = d.recent_activity || [];
    let body;
    if (!acts.length) {
      body =
        '<div class="hd-empty"><div class="hd-empty-icon chip-neutral">' + this.msr("history") + "</div>" +
        '<div class="hd-empty-text">No recent activity</div></div>';
    } else {
      body = acts.map((a) => {
        const icon = { success: "check_circle", warning: "warning", info: "info", primary: "person_add" }[a.icon_class] || "info";
        // message contains safe <strong> markup from the server; render as-is.
        return (
          '<div class="hd-activity-item"><div class="hd-activity-avatar">' + this.msr(icon) + "</div>" +
          '<div><div class="hd-activity-text">' + (a.message || "") + "</div>" +
          '<div class="hd-activity-time">' + this.esc(a.time || "") + "</div></div></div>"
        );
      }).join("");
    }
    return (
      '<div class="hd-panel">' +
        '<div class="hd-panel-head sb"><h2 class="hd-panel-title">Recent Activity</h2>' +
          '<a class="hd-link" href="/app/chronic-care-alert">View All</a></div>' +
        body +
      "</div>"
    );
  }

  renderChart() {
    const t = this.data && this.data.alert_trend_data;
    const el = this.container.find("#hd-trend-chart");
    if (!t || !el.length || typeof frappe.Chart === "undefined") return;
    try {
      new frappe.Chart(el[0], {
        data: {
          labels: t.labels || ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
          datasets: [
            { name: "High", values: t.high || [0, 0, 0, 0, 0, 0, 0] },
            { name: "Medium", values: t.medium || [0, 0, 0, 0, 0, 0, 0] },
            { name: "Low", values: t.low || [0, 0, 0, 0, 0, 0, 0] },
          ],
        },
        type: "line",
        height: 200,
        colors: ["#c0413f", "#d99b2c", "#0c8a5e"],
        lineOptions: { regionFill: 1, hideDots: 0, spline: 1 },
        axisOptions: { xAxisMode: "tick", xIsSeries: true },
      });
    } catch (e) {
      console.warn("trend chart failed", e);
    }
  }
}
})();
