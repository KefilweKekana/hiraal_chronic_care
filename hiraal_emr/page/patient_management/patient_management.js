(function () {
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

frappe.pages["patient-management"].on_page_load = function (wrapper) {
  const page = frappe.ui.make_app_page({
    parent: wrapper,
    title: "Patient Management",
    subtitle: "Comprehensive patient registry with risk stratification and subscription tracking",
    single_column: true,
  });

  page.main.html('<div id="patient-mgmt-root"></div>');
  new PatientManagement(page);
};

class PatientManagement {
  constructor(page) {
    this.page = page;
    this.container = page.main.find("#patient-mgmt-root");
    this.filters = { risk: "All", subscription: "All", search: "" };
    this.selected_patient = null;
    this.setup_actions();
    this.load_data();
  }

  setup_actions() {
    this.page.set_secondary_action("Refresh", () => this.load_data(), "refresh");
  }

  async load_data() {
    this.container.html(HiraalMenu.wrap("patients", '<div class="empty-state">Loading patients...</div>'));
    try {
      const data = await frappe.xcall("hiraal_emr.api.get_patient_registry_data", {
        risk_filter: this.filters.risk,
        subscription_filter: this.filters.subscription,
        search: this.filters.search,
      });
      this.data = data;
      this.render();
    } catch (e) {
      console.error(e);
      this.container.html(HiraalMenu.wrap("patients", '<div class="empty-state">Error loading patient data.</div>'));
    }
  }

  render() {
    const d = this.data;
    const rd = d.risk_distribution || {};
    const sb = d.subscription_breakdown || {};

    const content = `
      <div class="patient-mgmt-page">
        <!-- Summary Row -->
        <div class="pm-summary-row">
          <div class="pm-summary-card">
            <div class="pm-summary-value">${d.total || 0}</div>
            <div class="pm-summary-label">Total Active Patients</div>
          </div>
          <div class="pm-summary-card risk-high">
            <div class="pm-summary-value">${(rd["Very High"] || 0) + (rd["High"] || 0)}</div>
            <div class="pm-summary-label">High Risk</div>
          </div>
          <div class="pm-summary-card risk-medium">
            <div class="pm-summary-value">${rd["Medium"] || 0}</div>
            <div class="pm-summary-label">Medium Risk</div>
          </div>
          <div class="pm-summary-card risk-normal">
            <div class="pm-summary-value">${(rd["Low"] || 0) + (rd["Normal"] || 0)}</div>
            <div class="pm-summary-label">Low / Normal</div>
          </div>
        </div>

        <!-- Charts Row -->
        <div class="pm-charts-row">
          <div class="pm-chart-card">
            <h4>Patient Risk Distribution</h4>
            <div id="risk-pie-chart" style="height:220px"></div>
          </div>
          <div class="pm-chart-card">
            <h4>Subscription Status</h4>
            <div id="sub-pie-chart" style="height:220px"></div>
          </div>
        </div>

        <!-- Filters -->
        <div class="pm-filters">
          <div class="pm-search">
            <input type="text" class="form-control pm-search-input" placeholder="Search patients by name or ID..." value="${this.filters.search}">
          </div>
          <div class="pm-filter-group">
            <select class="form-control pm-risk-filter">
              ${["All", "Very High", "High", "Medium", "Low", "Normal"].map(r =>
                `<option value="${r}" ${this.filters.risk === r ? "selected" : ""}>${r}</option>`
              ).join("")}
            </select>
            <select class="form-control pm-sub-filter">
              ${["All", "Active", "Overdue", "Past Due", "None"].map(s =>
                `<option value="${s}" ${this.filters.subscription === s ? "selected" : ""}>${s}</option>`
              ).join("")}
            </select>
          </div>
        </div>

        <!-- Patient Table -->
        <div class="pm-table-wrapper">
          <table class="table table-hover pm-table">
            <thead>
              <tr>
                <th>Patient</th>
                <th>Risk Level</th>
                <th>Last Reading</th>
                <th>Last BP</th>
                <th>Last Sugar</th>
                <th>Subscription</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              ${(d.patients || []).map(p => `
                <tr class="patient-row" data-patient="${p.name}">
                  <td>
                    <div class="pm-patient-cell">
                      <span class="pm-avatar ${this.risk_class(p.risk_level)}">${(p.patient_name || "?").substring(0, 2).toUpperCase()}</span>
                      <div>
                        <a href="/app/patient/${p.name}"><strong>${p.patient_name}</strong></a>
                        <br><small class="text-muted">${p.name} · ${p.sex || ""} · ${p.mobile || ""}</small>
                      </div>
                    </div>
                  </td>
                  <td><span class="indicator-pill ${this.risk_indicator(p.risk_level)}">${p.risk_level}</span></td>
                  <td>${p.last_reading_date ? frappe.datetime.str_to_user(p.last_reading_date) : '<span class="text-muted">Never</span>'}</td>
                  <td>${p.last_bp || '<span class="text-muted">—</span>'}</td>
                  <td>${p.last_sugar != null ? p.last_sugar : '<span class="text-muted">—</span>'}</td>
                  <td>
                    <span class="indicator-pill ${p.subscription_status === "Active" ? "green" : p.subscription_status === "Overdue" ? "orange" : "grey"}">
                      ${p.subscription_plan}${p.subscription_plan !== "None" ? " · " + p.subscription_status : ""}
                    </span>
                  </td>
                  <td>
                    <button class="btn btn-xs btn-default view-profile-btn" data-patient="${p.name}">View Profile</button>
                  </td>
                </tr>
              `).join("")}
            </tbody>
          </table>
          ${!d.patients?.length ? '<p class="text-muted text-center p-4">No patients found.</p>' : ""}
        </div>

        <!-- Patient Profile Drawer -->
        <div class="pm-profile-drawer" id="profile-drawer" style="display:none">
          <div class="pm-profile-content" id="profile-content"></div>
        </div>
      </div>
    `;

    this.container.html(HiraalMenu.wrap("patients", content));
    this.bind_events();
    this.render_charts(rd, sb);
  }

  bind_events() {
    this.container.on("input", ".pm-search-input", frappe.utils.debounce((e) => {
      this.filters.search = $(e.target).val();
      this.load_data();
    }, 400));

    this.container.on("change", ".pm-risk-filter", (e) => {
      this.filters.risk = $(e.target).val();
      this.load_data();
    });

    this.container.on("change", ".pm-sub-filter", (e) => {
      this.filters.subscription = $(e.target).val();
      this.load_data();
    });

    this.container.on("click", ".view-profile-btn", async (e) => {
      const patient = $(e.currentTarget).data("patient");
      await this.show_profile(patient);
    });

    this.container.on("click", ".pm-profile-close", () => {
      this.container.find("#profile-drawer").hide();
    });
  }

  async show_profile(patient) {
    const drawer = this.container.find("#profile-drawer");
    const content = this.container.find("#profile-content");
    drawer.show();
    content.html('<div class="text-muted p-4">Loading profile...</div>');

    try {
      const p = await frappe.xcall("hiraal_emr.api.get_patient_profile", { patient });
      content.html(`
        <div class="pm-profile-header">
          <button class="btn btn-xs btn-default pm-profile-close" style="float:right">✕ Close</button>
          <h3>${p.patient.patient_name}</h3>
          <div class="text-muted">${p.patient.name} · ${p.patient.sex || ""} · ${p.patient.mobile || ""} · Blood Group: ${p.patient.blood_group || "N/A"}</div>
        </div>

        <!-- Key Metrics -->
        <div class="pm-profile-metrics">
          <div class="pm-metric"><div class="pm-metric-val">${p.readings_7d}</div><div class="pm-metric-lbl">Readings (7d)</div></div>
          <div class="pm-metric"><div class="pm-metric-val">${p.medication_adherence}%</div><div class="pm-metric-lbl">Med Adherence</div></div>
          <div class="pm-metric"><div class="pm-metric-val">${p.alerts.length}</div><div class="pm-metric-lbl">Active Alerts</div></div>
          <div class="pm-metric"><div class="pm-metric-val">${p.devices.length}</div><div class="pm-metric-lbl">Devices</div></div>
        </div>

        <!-- Subscription -->
        ${p.subscription ? `
          <div class="pm-profile-section">
            <h4>Subscription</h4>
            <p><strong>${p.subscription.plan}</strong> — $${p.subscription.monthly_fee}/mo — Status: <span class="indicator-pill ${p.subscription.status === "Active" ? "green" : "orange"}">${p.subscription.status}</span></p>
            <p class="text-muted">Next billing: ${p.subscription.next_billing_date ? frappe.datetime.str_to_user(p.subscription.next_billing_date) : "N/A"}</p>
          </div>
        ` : '<div class="pm-profile-section"><h4>Subscription</h4><p class="text-muted">No active subscription</p></div>'}

        <!-- Vital Sign Trends (last 30 days) -->
        <div class="pm-profile-section">
          <h4>Vital Sign Trends (30 days)</h4>
          <div id="profile-vitals-chart" style="height:200px"></div>
        </div>

        <!-- Active Alerts -->
        <div class="pm-profile-section">
          <h4>Active Alerts</h4>
          ${p.alerts.length ? p.alerts.map(a => `
            <div class="pm-alert-item">
              <span class="indicator-pill ${this.risk_indicator(a.alert_level)}">${a.alert_level}</span>
              <strong>${a.alert_type}</strong>
              <span class="text-muted"> — ${frappe.datetime.prettyDate(a.creation)}</span>
            </div>
          `).join("") : '<p class="text-muted">No active alerts</p>'}
        </div>

        <!-- Doctor Plans -->
        <div class="pm-profile-section">
          <h4>Doctor Reviews</h4>
          ${p.reviews.length ? p.reviews.map(r => `
            <div class="pm-review-item">
              <span class="indicator-pill ${r.review_status === "Reviewed" ? "green" : "orange"}">${r.review_status}</span>
              ${r.assessment ? `<strong>${r.assessment}</strong> — ` : ""}
              ${r.plan_notes || "No notes"}
              <span class="text-muted"> — ${frappe.datetime.prettyDate(r.creation)}</span>
            </div>
          `).join("") : '<p class="text-muted">No reviews yet</p>'}
        </div>

        <!-- Nurse Notes -->
        <div class="pm-profile-section">
          <h4>Nurse Notes</h4>
          ${p.nurse_notes.length ? p.nurse_notes.map(n => `
            <div class="pm-note-item">
              <strong>${n.task_type}</strong>: ${n.completion_note || "Completed"}
              <span class="text-muted"> — ${frappe.datetime.prettyDate(n.completed_at)}</span>
            </div>
          `).join("") : '<p class="text-muted">No notes yet</p>'}
        </div>

        <!-- Devices -->
        <div class="pm-profile-section">
          <h4>Connected Devices</h4>
          ${p.devices.length ? p.devices.map(d => `
            <div class="pm-device-item">
              <strong>${d.device_name}</strong> (${d.device_type})
              — <span class="indicator-pill ${d.status === "Online" ? "green" : "red"}">${d.status}</span>
              ${d.battery_level ? ` · Battery: ${d.battery_level}%` : ""}
              ${d.last_sync ? ` · Last sync: ${frappe.datetime.prettyDate(d.last_sync)}` : ""}
            </div>
          `).join("") : '<p class="text-muted">No devices connected</p>'}
        </div>
      `);

      // Render vitals chart
      if (p.readings.length) {
        new frappe.Chart(content.find("#profile-vitals-chart")[0], {
          data: {
            labels: p.readings.map(r => r.reading_date),
            datasets: [
              { name: "Systolic", values: p.readings.map(r => r.bp_systolic || 0) },
              { name: "Diastolic", values: p.readings.map(r => r.bp_diastolic || 0) },
              { name: "Sugar", values: p.readings.map(r => r.blood_sugar || 0) },
            ],
          },
          type: "line",
          height: 180,
          colors: ["#E74C3C", "#3498DB", "#F39C12"],
          lineOptions: { regionFill: 1 },
        });
      }
    } catch (e) {
      console.error(e);
      content.html('<p class="text-danger p-4">Error loading profile.</p>');
    }
  }

  render_charts(rd, sb) {
    const risk_el = this.container.find("#risk-pie-chart");
    if (risk_el.length) {
      const labels = Object.keys(rd).filter(k => rd[k] > 0);
      const values = labels.map(k => rd[k]);
      if (labels.length) {
        new frappe.Chart(risk_el[0], {
          data: { labels, datasets: [{ values }] },
          type: "donut",
          height: 200,
          colors: labels.map(l => ({"Very High": "#E74C3C", "High": "#E67E22", "Medium": "#F39C12", "Low": "#3498DB", "Normal": "#27AE60"}[l])),
        });
      }
    }

    const sub_el = this.container.find("#sub-pie-chart");
    if (sub_el.length) {
      const labels = Object.keys(sb).filter(k => sb[k] > 0);
      const values = labels.map(k => sb[k]);
      if (labels.length) {
        new frappe.Chart(sub_el[0], {
          data: { labels, datasets: [{ values }] },
          type: "donut",
          height: 200,
          colors: labels.map(l => ({"Active": "#27AE60", "Overdue": "#E67E22", "Past Due": "#E74C3C", "None": "#95A5A6"}[l] || "#BDC3C7")),
        });
      }
    }
  }

  risk_class(level) {
    return { "Very High": "avatar-danger", "High": "avatar-warning", "Medium": "avatar-caution", "Low": "avatar-info", "Normal": "avatar-success" }[level] || "avatar-default";
  }

  risk_indicator(level) {
    return { "Very High": "red", "High": "orange", "Medium": "yellow", "Low": "blue", "Normal": "green" }[level] || "grey";
  }
}
})();
