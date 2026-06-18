// ─── Hiraal Sidebar (inlined — kept identical to the other desk pages) ───
const HiraalMenu = {
  sections: [
    { title: "CLINICAL", items: [
      { label: "Dashboard", icon: "📊", route: "/app/clinic-dashboard", name: "dashboard" },
      { label: "Alerts", icon: "🚨", route: "/app/chronic-care-alert", name: "alerts" },
      { label: "Patients", icon: "👥", route: "/app/patient", name: "patients" },
      { label: "Daily Readings", icon: "📈", route: "/app/daily-reading", name: "daily-readings" },
      { label: "Nurse Tasks", icon: "✅", route: "/app/nurse-task", name: "nurse-tasks" },
      { label: "Doctor Review", icon: "🩺", route: "/app/doctor-review", name: "doctor-review" },
      { label: "Appointments", icon: "📅", route: "/app/patient-appointment", name: "appointments" },
      { label: "Lab Requests", icon: "🧪", route: "/app/lab-test", name: "lab-requests" },
      { label: "Medicine Requests", icon: "💊", route: "/app/medicine-request", name: "medicine-requests" },
      { label: "Devices", icon: "📱", route: "/app/patient-device", name: "devices" },
      { label: "Telemedicine", icon: "📹", route: "/app/telemedicine-waiting-room", name: "telemedicine" },
    ]},
    { title: "BILLING", items: [
      { label: "Subscriptions", icon: "🔄", route: "/app/care-subscription", name: "subscriptions" },
      { label: "Payments", icon: "💳", route: "/app/subscription-payment", name: "payments" },
    ]},
    { title: "REPORTS", items: [
      { label: "Reports", icon: "📋", route: "/app/query-report/Patient Summary", name: "reports" },
      { label: "Analytics", icon: "📉", route: "/app/analytics-dashboard", name: "analytics" },
    ]},
    { title: "SETTINGS", items: [
      { label: "Settings", icon: "⚙️", route: "/app/chronic-care-settings", name: "settings" },
      { label: "User Management", icon: "👤", route: "/app/user", name: "user-management" },
    ]},
  ],
  renderSidebar(activeName, badges) {
    badges = badges || {};
    let h = '<aside class="dashboard-sidebar">';
    h += '<div class="sidebar-brand"><div class="brand-logo">🏥</div><div class="brand-text"><div class="brand-title">DagaarSoft</div><div class="brand-subtitle">Health Clinic</div></div></div>';
    h += '<nav class="sidebar-nav">';
    this.sections.forEach(s => {
      h += '<div class="sidebar-section"><div class="sidebar-section-title">' + s.title + '</div><ul class="sidebar-menu">';
      s.items.forEach(i => {
        const a = i.name === activeName, b = badges[i.name] || 0;
        h += '<li class="sidebar-menu-item ' + (a ? 'active' : '') + '"><a href="' + i.route + '" class="sidebar-menu-link"><span class="sidebar-icon">' + i.icon + '</span><span class="sidebar-label">' + i.label + '</span>' + (b ? '<span class="sidebar-badge">' + b + '</span>' : '') + '</a></li>';
      });
      h += '</ul></div>';
    });
    h += '</nav><div class="sidebar-footer"><div class="need-help"><div class="help-icon">💬</div><div class="help-text"><div class="help-title">Need Help?</div><div class="help-link">Contact Support</div><div class="help-email">support@dagaar.so</div></div></div></div></aside>';
    return h;
  },
  wrap(activeName, content, badges) {
    return '<div class="dashboard-with-sidebar">' + this.renderSidebar(activeName, badges) + '<div class="dashboard-main">' + content + '</div></div>';
  }
};

frappe.pages["telemedicine-waiting-room"].on_page_load = function (wrapper) {
  const page = frappe.ui.make_app_page({
    parent: wrapper,
    title: "Telemedicine Waiting Room",
    single_column: true,
  });
  page.main.html('<div id="telemed-root"></div>');
  new TelemedWaitingRoom(page);
};

class TelemedWaitingRoom {
  constructor(page) {
    this.page = page;
    this.container = page.main.find("#telemed-root");
    this.page.set_primary_action("Refresh", () => this.load(), "refresh");
    this.load();
    // Auto-refresh so a patient joining appears without manual refresh.
    this.timer = setInterval(() => this.load(), 20000);
  }

  _alive() {
    return this.container && this.container.length && document.body.contains(this.container[0]);
  }

  async load() {
    if (!this._alive()) {
      clearInterval(this.timer);
      return;
    }
    if (!this.data_loaded) {
      this.container.html(HiraalMenu.wrap("telemedicine", '<div class="clinic-dashboard"><div class="empty-state">Loading…</div></div>'));
    }
    try {
      const rows = await frappe.xcall("hiraal_emr.api.get_waiting_telemedicine_sessions");
      this.data_loaded = true;
      this.render(rows || []);
    } catch (e) {
      this.container.html(
        HiraalMenu.wrap("telemedicine", '<div class="clinic-dashboard"><div class="empty-state">Could not load sessions.</div></div>')
      );
    }
  }

  render(rows) {
    const esc = frappe.utils.escape_html;
    const waiting = rows.filter((r) => r.session_status === "In Progress").length;
    const scheduled = rows.length - waiting;

    let table;
    if (!rows.length) {
      table = '<div class="empty-state">No patients are waiting right now.</div>';
    } else {
      table =
        '<table class="alerts-table"><thead><tr><th>Patient</th><th>Doctor</th><th>Time</th><th>Status</th><th>Action</th></tr></thead><tbody>';
      rows.forEach((r) => {
        const isWaiting = r.session_status === "In Progress";
        const name = r.patient_name || r.patient || "Patient";
        const when = r.start_time ? frappe.datetime.str_to_user(r.start_time) : "—";
        const url = r.meeting_url || "";
        const pill = isWaiting
          ? '<span class="status-pill" style="background:#EFF6FF;color:#2563EB;">Waiting now</span>'
          : '<span class="status-pill" style="background:#F1F5F9;color:#64748B;">Scheduled</span>';
        const join = url
          ? '<button class="btn btn-primary btn-sm telemed-join" data-url="' + esc(url) + '">Join Call</button>'
          : '<span style="color:#94A3B8;font-size:12px;">No link</span>';
        const done = isWaiting
          ? ' <button class="btn btn-default btn-sm telemed-done" data-name="' + esc(r.name) + '">Mark Done</button>'
          : "";
        table +=
          '<tr><td><div class="patient-cell"><div class="patient-avatar" style="background:' +
          this.avatar_color(name) + '">' + this.initials(name) +
          '</div><div class="patient-info"><div class="name">' + esc(name) +
          '</div><div class="id">' + esc(r.patient || "") + "</div></div></div></td><td>" +
          esc(r.practitioner_name || r.practitioner || "Unassigned") +
          '</td><td class="time-cell">' + esc(when) + "</td><td>" + pill + "</td><td>" + join + done + "</td></tr>";
      });
      table += "</tbody></table>";
    }

    const content =
      '<div class="clinic-dashboard">' +
        '<div class="kpi-row">' +
          this.kpi_card({ label: "Waiting Now", value: waiting, icon: "📹", icon_class: "red" }) +
          this.kpi_card({ label: "Scheduled Today", value: scheduled, icon: "📅", icon_class: "blue" }) +
        "</div>" +
        '<div class="dashboard-grid">' +
          '<div class="dashboard-card alerts-card">' +
            '<div class="card-header"><h3>Patients Waiting</h3><a href="/app/telemedicine-session" class="view-all">All Sessions</a></div>' +
            '<div class="card-body">' + table + "</div>" +
          "</div>" +
        "</div>" +
      "</div>";

    this.container.html(HiraalMenu.wrap("telemedicine", content, { telemedicine: waiting || 0 }));
    this.container.find("button.telemed-join").on("click", function () {
      const u = $(this).attr("data-url");
      if (u) window.open(u, "_blank", "noopener");
    });
    const self = this;
    this.container.find("button.telemed-done").on("click", function () {
      const n = $(this).attr("data-name");
      if (!n) return;
      frappe.confirm("End this video visit and mark it completed?", function () {
        frappe
          .xcall("hiraal_emr.api.complete_telemedicine_session", { name: n })
          .then(function (r) {
            frappe.show_alert({
              message: "Visit completed" + (r && r.duration_minutes != null ? " (" + r.duration_minutes + " min)" : ""),
              indicator: "green",
            });
            self.load();
          });
      });
    });
  }

  kpi_card({ label, value, icon, icon_class }) {
    return (
      '<div class="kpi-card"><div class="kpi-icon ' + icon_class + '">' + icon +
      '</div><div class="kpi-body"><div class="kpi-value">' + (value ?? 0) +
      '</div><div class="kpi-label">' + label + "</div></div></div>"
    );
  }
  initials(name) {
    if (!name) return "?";
    return name.split(" ").map((n) => n[0]).join("").toUpperCase().slice(0, 2);
  }
  avatar_color(name) {
    const colors = ["#2563EB", "#16A34A", "#DC2626", "#D97706", "#9333EA", "#0D9488", "#DB2777", "#4F46E5"];
    let hash = 0;
    for (let i = 0; i < (name || "").length; i++) hash = name.charCodeAt(i) + ((hash << 5) - hash);
    return colors[Math.abs(hash) % colors.length];
  }
}
