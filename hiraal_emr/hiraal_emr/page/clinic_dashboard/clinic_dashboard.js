frappe.pages["clinic-dashboard"].on_page_load = function (wrapper) {
  const page = frappe.ui.make_app_page({
    parent: wrapper,
    title: "Clinic Dashboard",
    subtitle: "Overview of patient monitoring and clinic operations",
    single_column: true,
  });

  page.main.html('<div id="clinic-dashboard-root"></div>');
  new ClinicDashboard(page);
};

class ClinicDashboard {
  constructor(page) {
    this.page = page;
    this.container = page.main.find("#clinic-dashboard-root");
    this.setup_actions();
    this.render();
    this.load_data();
  }

  setup_actions() {
    this.page.set_secondary_action("Refresh", () => this.load_data(), "refresh");
    this.page.add_inner_button("View All Alerts", () =>
      frappe.set_route("List", "Chronic Care Alert")
    );
  }

  async load_data() {
    try {
      const data = await frappe.xcall("hiraal_emr.api.get_dashboard_data");
      this.data = data;
      this.render_dashboard();
    } catch (e) {
      console.error("Dashboard load error:", e);
      this.container.html('<p class="text-muted">Error loading dashboard data.</p>');
    }
  }

  render() {
    this.container.html(`
      <div class="clinic-dashboard">
        <div class="dashboard-loading">
          <div class="text-muted">${__("Loading dashboard...")}</div>
        </div>
      </div>
    `);
  }

  render_dashboard() {
    const d = this.data;
    this.container.html(`
      <div class="clinic-dashboard">
        <!-- KPI Cards Row -->
        <div class="kpi-row">
          ${this.kpi_card("Active Patients", d.active_patients, d.new_patients_month + " this month", "users", "#4A90D9")}
          ${this.kpi_card("Today's Submissions", d.todays_submissions, (d.submissions_change > 0 ? "↑ " : "↓ ") + Math.abs(d.submissions_change) + "% from yesterday", "file-text", "#27AE60")}
          ${this.kpi_card("High-Risk Alerts", d.high_risk_alerts, d.new_alerts + " new", "alert-triangle", "#E74C3C")}
          ${this.kpi_card("Missed Submissions", d.missed_submissions, (d.missed_change > 0 ? "↑ " : "↓ ") + Math.abs(d.missed_change) + "% from yesterday", "clock", "#F39C12")}
          ${this.kpi_card("Unpaid Subscriptions", d.unpaid_subscriptions, '<a href="/app/care-subscription?status=Overdue">View Details →</a>', "credit-card", "#8E44AD")}
        </div>

        <div class="dashboard-grid">
          <!-- High Priority Alerts -->
          <div class="dashboard-card alerts-card">
            <div class="card-header">
              <h3>High Priority Alerts</h3>
              <span class="badge badge-danger">${d.high_risk_alerts}</span>
              <a href="/app/chronic-care-alert?alert_level=Very+High&status=Open" class="btn btn-xs btn-default float-right">View All</a>
            </div>
            <div class="card-body">
              <table class="table table-sm">
                <thead>
                  <tr><th>Patient</th><th>Latest Reading</th><th>Reason</th><th>Time</th><th>Assigned</th></tr>
                </thead>
                <tbody>
                  ${(d.priority_alerts || []).map(a => `
                    <tr>
                      <td><a href="/app/patient/${a.patient}"><strong>${a.patient_name}</strong></a><br><small class="text-muted">${a.patient}</small></td>
                      <td><strong>${a.latest_reading_display || "—"}</strong></td>
                      <td><span class="indicator-pill ${this.alert_color(a.alert_level)}">${a.alert_type}</span></td>
                      <td>${frappe.datetime.prettyDate(a.creation)}</td>
                      <td>${a.assigned_nurse_name || "Unassigned"}</td>
                    </tr>
                  `).join("")}
                </tbody>
              </table>
              ${!d.priority_alerts?.length ? '<p class="text-muted text-center">No high priority alerts right now.</p>' : ""}
            </div>
          </div>

          <!-- Alert Trends Chart -->
          <div class="dashboard-card chart-card">
            <div class="card-header">
              <h3>Alert Trends (This Week)</h3>
            </div>
            <div class="card-body">
              <div id="alert-trends-chart" style="height: 200px;"></div>
              <div class="trend-summary">
                <div><strong>This Week:</strong> ${d.alerts_this_week || 0} Total Alerts</div>
                <div><strong>Last Week:</strong> ${d.alerts_last_week || 0} Total Alerts</div>
              </div>
            </div>
          </div>
        </div>

        <!-- Quick Access Cards -->
        <div class="quick-access-row">
          ${this.quick_card("Appointments Today", d.appointments_today, d.appointments_upcoming + " upcoming", "/app/patient-appointment?appointment_date=Today", "calendar")}
          ${this.quick_card("Lab Requests", d.lab_requests_total, d.lab_requests_pending + " pending", "/app/lab-test", "activity")}
          ${this.quick_card("Medicine Requests", d.medicine_requests_total, d.medicine_requests_pending + " pending", "/app/medication-request", "package")}
          ${this.quick_card("Nurse Tasks", d.nurse_tasks_total, d.nurse_tasks_pending + " pending", "/app/nurse-task", "check-square")}
          ${this.quick_card("Patients at Risk", d.patients_at_risk, d.patients_high_risk + " high risk", "/app/chronic-care-alert?alert_level=Very+High", "shield")}
        </div>

        <div class="dashboard-grid">
          <!-- Today's Appointments -->
          <div class="dashboard-card">
            <div class="card-header">
              <h3>Today's Appointments</h3>
              <a href="/app/patient-appointment?appointment_date=Today" class="btn btn-xs btn-default float-right">View Calendar</a>
            </div>
            <div class="card-body">
              <table class="table table-sm">
                <thead>
                  <tr><th>Time</th><th>Patient</th><th>Type</th><th>Provider</th><th>Status</th></tr>
                </thead>
                <tbody>
                  ${(d.todays_appointments || []).map(a => `
                    <tr>
                      <td>${a.appointment_time || "—"}</td>
                      <td><a href="/app/patient/${a.patient}">${a.patient_name}</a></td>
                      <td>${a.appointment_type || "Visit"}</td>
                      <td>${a.practitioner_name || "—"}</td>
                      <td><span class="indicator-pill ${a.status === "Confirmed" ? "green" : "orange"}">${a.status}</span></td>
                    </tr>
                  `).join("")}
                </tbody>
              </table>
              ${!d.todays_appointments?.length ? '<p class="text-muted text-center">No appointments today.</p>' : ""}
              <div class="text-center mt-2">
                <a href="/app/patient-appointment">View All Appointments →</a>
              </div>
            </div>
          </div>

          <!-- Recent Activity Feed -->
          <div class="dashboard-card">
            <div class="card-header">
              <h3>Recent Activity</h3>
              <a href="#" class="btn btn-xs btn-default float-right">View All</a>
            </div>
            <div class="card-body activity-feed">
              ${(d.recent_activity || []).map(a => `
                <div class="activity-item">
                  <div class="activity-icon ${a.icon_class || ""}">
                    ${a.icon || "✓"}
                  </div>
                  <div class="activity-content">
                    <div>${a.message}</div>
                    <small class="text-muted">${a.time}</small>
                  </div>
                </div>
              `).join("")}
              ${!d.recent_activity?.length ? '<p class="text-muted text-center">No recent activity.</p>' : ""}
            </div>
          </div>
        </div>
      </div>
    `);

    this.render_alert_chart();
  }

  kpi_card(label, value, subtitle, icon, color) {
    return `
      <div class="kpi-card" style="border-top: 3px solid ${color}">
        <div class="kpi-value">${value ?? 0}</div>
        <div class="kpi-label">${label}</div>
        <div class="kpi-subtitle">${subtitle || ""}</div>
      </div>
    `;
  }

  quick_card(label, value, subtitle, link, icon) {
    return `
      <a href="${link}" class="quick-card">
        <div class="quick-value">${value ?? 0}</div>
        <div class="quick-label">${label}</div>
        <div class="quick-subtitle text-muted">${subtitle || ""}</div>
      </a>
    `;
  }

  alert_color(level) {
    return {"Very High": "red", "High": "orange", "Medium": "yellow", "Low": "blue"}[level] || "grey";
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
        ],
      },
      type: "bar",
      height: 180,
      colors: ["#E74C3C", "#F39C12"],
      barOptions: {stacked: 1},
    });
  }
}
