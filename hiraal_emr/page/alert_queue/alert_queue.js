// ─── Hiraal Sidebar (inlined — no external dependency) ───
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

frappe.pages["alert-queue"].on_page_load = function (wrapper) {
  const page = frappe.ui.make_app_page({
    parent: wrapper,
    title: "Alert Queue",
    subtitle: "Patients who need immediate follow-up based on their latest readings or activity",
    single_column: true,
  });

  page.main.html('<div id="alert-queue-root"></div>');
  new AlertQueue(page);
};

class AlertQueue {
  constructor(page) {
    this.page = page;
    this.container = page.main.find("#alert-queue-root");
    this.current_filter = "All";
    this.setup_actions();
    this.load_data();
  }

  setup_actions() {
    this.page.set_secondary_action("Refresh", () => this.load_data(), "refresh");
  }

  async load_data() {
    this.container.html(HiraalMenu.wrap("alerts", '<div class="empty-state">Loading alerts...</div>'));
    try {
      const data = await frappe.xcall("hiraal_emr.api.get_alert_queue_data");
      this.data = data;
      this.render();
    } catch (e) {
      console.error(e);
      this.container.html(HiraalMenu.wrap("alerts", '<div class="empty-state">Error loading alert data.</div>'));
    }
  }

  render() {
    const d = this.data;
    const badges = { alerts: d.total || 0 };
    const content = `
      <div class="alert-queue-page">
        <!-- Level Summary Cards -->
        <div class="level-cards">
          <div class="level-card very-high" data-filter="Very High">
            <div class="level-icon">⚠</div>
            <div class="level-label text-danger">Very High</div>
            <div class="level-count">${d.very_high || 0}</div>
            <div class="level-desc">Need urgent action</div>
          </div>
          <div class="level-card high" data-filter="High">
            <div class="level-icon">△</div>
            <div class="level-label text-warning">High</div>
            <div class="level-count">${d.high || 0}</div>
            <div class="level-desc">Need follow-up</div>
          </div>
          <div class="level-card medium" data-filter="Medium">
            <div class="level-icon">!</div>
            <div class="level-label" style="color:#F39C12">Medium</div>
            <div class="level-count">${d.medium || 0}</div>
            <div class="level-desc">Monitor closely</div>
          </div>
          <div class="level-card low" data-filter="Low">
            <div class="level-icon">○</div>
            <div class="level-label text-info">Low</div>
            <div class="level-count">${d.low || 0}</div>
            <div class="level-desc">All caught up</div>
          </div>
          <div class="level-card all" data-filter="All">
            <div class="level-icon">✓</div>
            <div class="level-label text-primary">Total Alerts</div>
            <div class="level-count">${d.total || 0}</div>
            <div class="level-desc">Active now</div>
          </div>
        </div>

        <!-- Filter Tabs -->
        <div class="filter-tabs">
          ${["All", "Very High", "High", "Medium", "Low"].map(f => `
            <button class="filter-tab ${this.current_filter === f ? "active" : ""}" data-filter="${f}">
              ${f} <span class="tab-count">${f === "All" ? d.total : d[f.toLowerCase().replace(" ", "_")] || 0}</span>
            </button>
          `).join("")}
        </div>

        <!-- Alerts Table -->
        <div class="alerts-table-wrapper">
          <table class="table table-hover alert-table">
            <thead>
              <tr>
                <th><input type="checkbox" class="select-all"></th>
                <th>Patient</th>
                <th>Latest Reading</th>
                <th>Reason</th>
                <th>Risk Level</th>
                <th>Time</th>
                <th>Assigned To</th>
                <th>Action</th>
              </tr>
            </thead>
            <tbody>
              ${(d.alerts || []).map(a => `
                <tr data-name="${a.name}" data-level="${a.alert_level}">
                  <td><input type="checkbox" class="alert-check" data-name="${a.name}"></td>
                  <td>
                    <div class="patient-cell">
                      <span class="patient-avatar">${(a.patient_name || "?").substring(0, 2).toUpperCase()}</span>
                      <div>
                        <a href="/app/patient/${a.patient}"><strong>${a.patient_name}</strong></a>
                        <br><small class="text-muted">${a.patient}</small>
                      </div>
                    </div>
                  </td>
                  <td><strong>${a.latest_reading_display || "No Reading"}</strong></td>
                  <td><span class="indicator-pill ${this.alert_color(a.alert_level)}">${a.alert_type}</span></td>
                  <td><span class="indicator-pill ${this.alert_color(a.alert_level)}">${a.alert_level}</span></td>
                  <td>${frappe.datetime.prettyDate(a.creation)}<br><small>${frappe.datetime.str_to_user(a.creation)}</small></td>
                  <td>${a.assigned_nurse_name || '<span class="text-muted">Unassigned</span>'}</td>
                  <td>
                    <div class="dropdown">
                      <button class="btn btn-xs btn-primary-light dropdown-toggle" data-toggle="dropdown">Take Action</button>
                      <div class="dropdown-menu">
                        <a class="dropdown-item action-btn" data-action="review" data-name="${a.name}">📋 Mark Reviewed</a>
                        <a class="dropdown-item action-btn" data-action="escalate" data-name="${a.name}">⬆ Escalate to Doctor</a>
                        <a class="dropdown-item action-btn" data-action="call" data-name="${a.name}">📞 Call Patient</a>
                        <a class="dropdown-item action-btn" data-action="note" data-name="${a.name}">📝 Add Note</a>
                      </div>
                    </div>
                  </td>
                </tr>
              `).join("")}
            </tbody>
          </table>
          ${!d.alerts?.length ? '<p class="text-muted text-center p-4">No alerts matching current filter.</p>' : ""}
        </div>

        <!-- Quick Actions Bar -->
        <div class="quick-actions-bar">
          <h4>Quick Actions</h4>
          <div class="quick-actions-grid">
            <div class="qa-card">
              <div class="qa-icon">📞</div>
              <div class="qa-title">1. Contact Patient</div>
              <div class="qa-desc">Call the patient immediately to check their condition and symptoms.</div>
            </div>
            <div class="qa-card">
              <div class="qa-icon">📊</div>
              <div class="qa-title">2. Review Readings</div>
              <div class="qa-desc">Check their recent readings and history to understand the trend.</div>
            </div>
            <div class="qa-card">
              <div class="qa-icon">⚡</div>
              <div class="qa-title">3. Take Action</div>
              <div class="qa-desc">Escalate to doctor if needed or provide guidance and follow-up.</div>
            </div>
          </div>
        </div>
      </div>
    `;

    this.container.html(HiraalMenu.wrap("alerts", content, badges));
    this.bind_events();
  }

  bind_events() {
    // Filter tabs
    this.container.on("click", ".filter-tab", (e) => {
      this.current_filter = $(e.currentTarget).data("filter");
      this.container.find(".filter-tab").removeClass("active");
      $(e.currentTarget).addClass("active");
      this.apply_filter();
    });

    // Action buttons
    this.container.on("click", ".action-btn", (e) => {
      const action = $(e.currentTarget).data("action");
      const name = $(e.currentTarget).data("name");
      this.handle_action(action, name);
    });
  }

  apply_filter() {
    const rows = this.container.find(".alert-table tbody tr");
    rows.each(function () {
      const level = $(this).data("level");
      if (this.current_filter === "All" || level === this.current_filter) {
        $(this).show();
      } else {
        $(this).hide();
      }
    }.bind(this));
  }

  handle_action(action, alert_name) {
    if (action === "review") {
      frappe.xcall("hiraal_emr.api.resolve_alert", {alert_name}).then(() => {
        frappe.show_alert({message: "Alert marked as reviewed", indicator: "green"});
        this.load_data();
      });
    } else if (action === "escalate") {
      frappe.xcall("hiraal_emr.api.escalate_alert", {alert_name}).then(() => {
        frappe.show_alert({message: "Alert escalated to doctor", indicator: "orange"});
        this.load_data();
      });
    } else if (action === "note") {
      frappe.prompt("Add Note", (values) => {
        frappe.xcall("hiraal_emr.api.add_alert_note", {alert_name, note: values.value}).then(() => {
          frappe.show_alert({message: "Note added", indicator: "green"});
        });
      });
    }
  }

  alert_color(level) {
    return {"Very High": "red", "High": "orange", "Medium": "yellow", "Low": "blue"}[level] || "grey";
  }
}
