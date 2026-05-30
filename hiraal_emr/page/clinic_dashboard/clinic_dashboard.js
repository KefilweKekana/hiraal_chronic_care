frappe.pages["clinic-dashboard"].on_page_load = function (wrapper) {
  const page = frappe.ui.make_app_page({
    parent: wrapper,
    title: "Clinic Dashboard",
    subtitle: "Overview of patient monitoring and clinic operations",
    single_column: true,
  });

  // Add date display and refresh button to page header
  page.set_indicator(frappe.datetime.str_to_user(frappe.datetime.get_today()), "blue");
  page.set_secondary_action("Refresh", () => this.load_data(), "refresh");

  page.main.html('<div id="clinic-dashboard-root"></div>');
  new ClinicDashboard(page);
};

class ClinicDashboard {
  constructor(page) {
    this.page = page;
    this.container = page.main.find("#clinic-dashboard-root");
    this.render();
    this.load_data();
  }

  async load_data() {
    try {
      const data = await frappe.xcall("hiraal_emr.api.get_dashboard_data");
      this.data = data;
      this.render_dashboard();
    } catch (e) {
      console.error("Dashboard load error:", e);
      this.container.html(HiraalSidebar.wrapPage("dashboard", '<div class="empty-state">Error loading dashboard data.</div>'));
    }
  }

  render() {
    this.container.html(HiraalSidebar.wrapPage("dashboard", `
      <div class="clinic-dashboard">
        <div class="empty-state">${__("Loading dashboard...")}</div>
      </div>
    `));
  }

  render_dashboard() {
    const d = this.data;
    const badges = { alerts: d.high_risk_alerts || 0 };
    const content = `
      <div class="clinic-dashboard">
        <!-- KPI Cards Row -->
        <div class="kpi-row">
          ${this.kpi_card({
            label: "Active Patients",
            value: d.active_patients,
            subtitle: `↑ ${d.new_patients_month} this month`,
            icon: "👥",
            icon_class: "blue",
          })}
          ${this.kpi_card({
            label: "Today's Submissions",
            value: d.todays_submissions,
            subtitle: `↑ ${Math.abs(d.submissions_change)}% from yesterday`,
            icon: "📊",
            icon_class: "green",
          })}
          ${this.kpi_card({
            label: "High-Risk Alerts",
            value: d.high_risk_alerts,
            subtitle: `↑ ${d.new_alerts} new`,
            icon: "⚠️",
            icon_class: "red",
          })}
          ${this.kpi_card({
            label: "Missed Submissions",
            value: d.missed_submissions,
            subtitle: `↑ 5% from yesterday`,
            icon: "⏰",
            icon_class: "amber",
          })}
          ${this.kpi_card({
            label: "Unpaid Subscriptions",
            value: d.unpaid_subscriptions,
            subtitle: "",
            action: '<a href="/app/care-subscription?status=Overdue" class="kpi-action">View Details →</a>',
            icon: "💳",
            icon_class: "purple",
          })}
        </div>

        <!-- Middle Row: Alerts + Chart -->
        <div class="dashboard-grid">
          <!-- High Priority Alerts -->
          <div class="dashboard-card alerts-card">
            <div class="card-header">
              <h3>High Priority Alerts <span class="alert-badge">${d.high_risk_alerts}</span></h3>
              <a href="/app/chronic-care-alert?alert_level=Very+High&status=Open" class="view-all">View All</a>
            </div>
            <div class="card-body">
              <table class="alerts-table">
                <thead>
                  <tr>
                    <th>Patient</th>
                    <th>Latest Reading</th>
                    <th>Reason</th>
                    <th>Time</th>
                    <th>Assigned</th>
                  </tr>
                </thead>
                <tbody>
                  ${(d.priority_alerts || []).map(a => `
                    <tr>
                      <td>
                        <div class="patient-cell">
                          <div class="patient-avatar" style="background: ${this.avatar_color(a.patient_name)}">${this.initials(a.patient_name)}</div>
                          <div class="patient-info">
                            <div class="name">${a.patient_name}</div>
                            <div class="id">${a.patient}</div>
                          </div>
                        </div>
                      </td>
                      <td><span class="reading-value">${a.latest_reading_display || "—"}</span></td>
                      <td>
                        <span class="alert-reason ${this.alert_class(a.alert_level)}">
                          <span class="dot"></span>
                          ${a.alert_type}
                        </span>
                      </td>
                      <td class="time-cell">${frappe.datetime.prettyDate(a.creation)}</td>
                      <td class="assigned-cell">${a.assigned_nurse_name || "—"}</td>
                    </tr>
                  `).join("")}
                </tbody>
              </table>
              ${!d.priority_alerts?.length ? '<div class="empty-state">No high priority alerts right now.</div>' : ""}
              <div class="alert-warning-banner">
                <span>⚠️</span>
                <span>These patients need immediate attention. Please follow up.</span>
              </div>
            </div>
          </div>

          <!-- Alert Trends Chart -->
          <div class="dashboard-card chart-card">
            <div class="card-header">
              <h3>Alert Trends (This Week)</h3>
            </div>
            <div class="card-body">
              <div class="chart-legend">
                <div class="legend-item"><span class="legend-dot" style="background:#DC2626"></span> High Risk</div>
                <div class="legend-item"><span class="legend-dot" style="background:#D97706"></span> Medium Risk</div>
                <div class="legend-item"><span class="legend-dot" style="background:#22C55E"></span> Low Risk</div>
              </div>
              <div id="alert-trends-chart" style="height: 180px;"></div>
              <div class="trend-stats">
                <div class="trend-stat">
                  <div class="stat-value">${d.alerts_this_week || 0}</div>
                  <div class="stat-label">This Week</div>
                  <div class="stat-change">Total Alerts</div>
                </div>
                <div class="trend-stat">
                  <div class="stat-value">${d.alerts_last_week || 0}</div>
                  <div class="stat-label">Last Week</div>
                  <div class="stat-change">Total Alerts</div>
                </div>
                <div class="trend-stat">
                  <div class="stat-value">${this.week_change_pct(d.alerts_this_week, d.alerts_last_week)}</div>
                  <div class="stat-label">Change</div>
                  <div class="stat-change">${(d.alerts_this_week || 0) >= (d.alerts_last_week || 0) ? "↑" : "↓"} From Last Week</div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Quick Access Cards -->
        <div class="quick-access-row">
          ${this.quick_card({
            label: "Appointments Today",
            value: d.appointments_today,
            subtitle: `${d.appointments_upcoming} upcoming`,
            link: "/app/patient-appointment?appointment_date=Today",
            icon: "📅",
            icon_class: "blue",
          })}
          ${this.quick_card({
            label: "Lab Requests",
            value: d.lab_requests_total,
            subtitle: `${d.lab_requests_pending} pending`,
            link: "/app/lab-test",
            icon: "🧪",
            icon_class: "indigo",
          })}
          ${this.quick_card({
            label: "Medicine Requests",
            value: d.medicine_requests_total,
            subtitle: `${d.medicine_requests_pending} pending`,
            link: "/app/medication-request",
            icon: "💊",
            icon_class: "pink",
          })}
          ${this.quick_card({
            label: "Nurse Tasks",
            value: d.nurse_tasks_total,
            subtitle: `${d.nurse_tasks_pending} pending`,
            link: "/app/nurse-task",
            icon: "✅",
            icon_class: "teal",
          })}
          ${this.quick_card({
            label: "Patients at Risk",
            value: d.patients_at_risk,
            subtitle: `${d.patients_high_risk} high risk`,
            link: "/app/chronic-care-alert?alert_level=Very+High",
            icon: "🛡️",
            icon_class: "rose",
          })}
        </div>

        <!-- Bottom Row: Appointments + Activity -->
        <div class="bottom-grid">
          <!-- Today's Appointments -->
          <div class="dashboard-card">
            <div class="card-header">
              <h3>Today's Appointments</h3>
              <a href="/app/patient-appointment?appointment_date=Today" class="view-all">View Calendar</a>
            </div>
            <div class="card-body">
              <table class="appointments-table">
                <thead>
                  <tr>
                    <th>Time</th>
                    <th>Patient</th>
                    <th>Type</th>
                    <th>Provider</th>
                    <th>Status</th>
                  </tr>
                </thead>
                <tbody>
                  ${(d.todays_appointments || []).map(a => `
                    <tr>
                      <td><span class="time-badge">${a.appointment_time || "—"}</span></td>
                      <td>
                        <div class="patient-cell">
                          <div class="patient-avatar" style="background: ${this.avatar_color(a.patient_name)}">${this.initials(a.patient_name)}</div>
                          <div class="patient-info">
                            <div class="name">${a.patient_name}</div>
                            <div class="id">${a.patient}</div>
                          </div>
                        </div>
                      </td>
                      <td>${a.appointment_type || "Visit"}</td>
                      <td>${a.practitioner_name || "—"}</td>
                      <td><span class="status-pill ${a.status?.toLowerCase()}">${a.status}</span></td>
                    </tr>
                  `).join("")}
                </tbody>
              </table>
              ${!d.todays_appointments?.length ? '<div class="empty-state">No appointments today.</div>' : ""}
              <a href="/app/patient-appointment" class="view-all-link">View All Appointments →</a>
            </div>
          </div>

          <!-- Recent Activity Feed -->
          <div class="dashboard-card">
            <div class="card-header">
              <h3>Recent Activity</h3>
              <a href="#" class="view-all">View All</a>
            </div>
            <div class="card-body">
              <div class="activity-feed">
                ${(d.recent_activity || []).map(a => `
                  <div class="activity-item">
                    <div class="activity-icon ${a.icon_class || "info"}">${a.icon || "ℹ️"}</div>
                    <div class="activity-content">
                      <div class="activity-title">${a.message}</div>
                      <div class="activity-meta">${a.time}</div>
                    </div>
                  </div>
                `).join("")}
                ${!d.recent_activity?.length ? '<div class="empty-state">No recent activity.</div>' : ""}
              </div>
            </div>
          </div>
        </div>
      </div>
    `;

    this.container.html(HiraalSidebar.wrapPage("dashboard", content, badges));
    this.render_alert_chart();
  }

  kpi_card({label, value, subtitle, icon, icon_class, action = ""}) {
    return `
      <div class="kpi-card">
        <div class="kpi-icon ${icon_class}">${icon}</div>
        <div class="kpi-body">
          <div class="kpi-value">${value ?? 0}</div>
          <div class="kpi-label">${label}</div>
          ${subtitle ? `<div class="kpi-subtitle">${subtitle}</div>` : ""}
          ${action}
        </div>
      </div>
    `;
  }

  quick_card({label, value, subtitle, link, icon, icon_class}) {
    return `
      <a href="${link}" class="quick-card">
        <div class="quick-icon ${icon_class}">${icon}</div>
        <div class="quick-body">
          <div class="quick-value">${value ?? 0}</div>
          <div class="quick-label">${label}</div>
          <div class="quick-subtitle">${subtitle || ""}</div>
        </div>
      </a>
    `;
  }

  alert_class(level) {
    return {
      "Very High": "very-high",
      "High": "high",
      "Medium": "medium",
      "Low": "low",
    }[level] || "low";
  }

  initials(name) {
    if (!name) return "?";
    return name.split(" ").map(n => n[0]).join("").toUpperCase().slice(0, 2);
  }

  avatar_color(name) {
    const colors = ["#2563EB", "#16A34A", "#DC2626", "#D97706", "#9333EA", "#0D9488", "#DB2777", "#4F46E5"];
    let hash = 0;
    for (let i = 0; i < (name || "").length; i++) hash = name.charCodeAt(i) + ((hash << 5) - hash);
    return colors[Math.abs(hash) % colors.length];
  }

  week_change_pct(this_week, last_week) {
    const tw = this_week || 0;
    const lw = last_week || 1;
    const pct = Math.round(((tw - lw) / lw) * 100);
    return (pct >= 0 ? "+" : "") + pct + "%";
  }

  render_alert_chart() {
    if (!this.data.alert_trend_data) return;
    const chart_el = this.container.find("#alert-trends-chart");
    if (!chart_el.length) return;

    new frappe.Chart(chart_el[0], {
      data: {
        labels: this.data.alert_trend_data.labels || ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
        datasets: [
          {name: "High Risk", values: this.data.alert_trend_data.high || [0, 0, 0, 0, 0, 0, 0]},
          {name: "Medium Risk", values: this.data.alert_trend_data.medium || [0, 0, 0, 0, 0, 0, 0]},
          {name: "Low Risk", values: this.data.alert_trend_data.low || [0, 0, 0, 0, 0, 0, 0]},
        ],
      },
      type: "line",
      height: 180,
      colors: ["#DC2626", "#D97706", "#22C55E"],
      lineOptions: {
        regionFill: 1,
        hideDots: 0,
      },
      axisOptions: {
        xAxisMode: "tick",
        xIsSeries: true,
      },
    });
  }
}
