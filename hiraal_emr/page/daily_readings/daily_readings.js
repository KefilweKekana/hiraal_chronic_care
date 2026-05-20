frappe.pages["daily-readings"].on_page_load = function (wrapper) {
  const page = frappe.ui.make_app_page({
    parent: wrapper,
    title: "Daily Readings",
    subtitle: "All patient readings from the mobile app, medical devices, and clinic entry — consolidated",
    single_column: true,
  });

  page.main.html('<div id="readings-root"></div>');
  new DailyReadingsDashboard(page);
};

class DailyReadingsDashboard {
  constructor(page) {
    this.page = page;
    this.container = page.main.find("#readings-root");
    this.selected_date = frappe.datetime.get_today();
    this.setup_actions();
    this.load_data();
  }

  setup_actions() {
    this.page.set_secondary_action("Refresh", () => this.load_data(), "refresh");
    // Date picker
    this.date_input = this.page.add_field({
      fieldname: "reading_date",
      label: "Date",
      fieldtype: "Date",
      default: this.selected_date,
      change: () => {
        this.selected_date = this.date_input.get_value();
        this.load_data();
      },
    });
  }

  async load_data() {
    this.container.html('<div class="text-muted p-4">Loading readings...</div>');
    try {
      const data = await frappe.xcall("hiraal_emr.api.get_readings_dashboard_data", {
        date: this.selected_date,
      });
      this.data = data;
      this.render();
    } catch (e) {
      console.error(e);
      this.container.html('<p class="text-danger p-4">Error loading readings.</p>');
    }
  }

  render() {
    const d = this.data;
    this.container.html(`
      <div class="readings-page">
        <!-- KPI Cards -->
        <div class="rd-kpi-row">
          <div class="rd-kpi-card">
            <div class="rd-kpi-icon">📊</div>
            <div class="rd-kpi-value">${d.total_readings}</div>
            <div class="rd-kpi-label">Today's Readings</div>
          </div>
          <div class="rd-kpi-card">
            <div class="rd-kpi-icon">✅</div>
            <div class="rd-kpi-value">${d.synced}</div>
            <div class="rd-kpi-label">Synced</div>
          </div>
          <div class="rd-kpi-card">
            <div class="rd-kpi-icon">⏳</div>
            <div class="rd-kpi-value">${d.pending_sync}</div>
            <div class="rd-kpi-label">Pending Sync</div>
          </div>
          <div class="rd-kpi-card rd-kpi-danger">
            <div class="rd-kpi-icon">⚠</div>
            <div class="rd-kpi-value">${d.high_readings}</div>
            <div class="rd-kpi-label">High Readings</div>
          </div>
        </div>

        <!-- Source Breakdown -->
        <div class="rd-source-row">
          <div class="rd-source-card"><span class="rd-source-icon">📱</span> App <strong>${d.from_app || 0}</strong></div>
          <div class="rd-source-card"><span class="rd-source-icon">🩺</span> BP Device <strong>${d.from_bp_device || 0}</strong></div>
          <div class="rd-source-card"><span class="rd-source-icon">🔬</span> Glucometer <strong>${d.from_glucometer || 0}</strong></div>
          <div class="rd-source-card"><span class="rd-source-icon">🏥</span> Clinic <strong>${d.from_clinic || 0}</strong></div>
          <div class="rd-source-card"><span class="rd-source-icon">📡</span> 5G Hub <strong>${d.from_hub || 0}</strong></div>
        </div>

        <!-- Readings Table -->
        <div class="rd-table-wrapper">
          <table class="table table-hover rd-table">
            <thead>
              <tr>
                <th>Patient</th>
                <th>Time</th>
                <th>BP (mmHg)</th>
                <th>Sugar</th>
                <th>Medicine</th>
                <th>Source</th>
                <th>Risk</th>
                <th>Alert</th>
                <th>Reviewed</th>
              </tr>
            </thead>
            <tbody>
              ${(d.readings || []).map(r => `
                <tr>
                  <td>
                    <a href="/app/patient/${r.patient}"><strong>${r.patient_name}</strong></a>
                    <br><small class="text-muted">${r.patient}</small>
                  </td>
                  <td>${r.reading_time || frappe.datetime.str_to_user(r.creation)}</td>
                  <td>
                    ${r.bp_systolic ? `<strong>${r.bp_systolic}/${r.bp_diastolic}</strong>` : '<span class="text-muted">—</span>'}
                  </td>
                  <td>
                    ${r.blood_sugar ? `<strong>${r.blood_sugar}</strong> <small>${r.blood_sugar_unit || "mg/dL"}</small>` : '<span class="text-muted">—</span>'}
                  </td>
                  <td>${r.medicine_taken ? '✅ Yes' : '<span class="text-muted">No</span>'}</td>
                  <td><span class="rd-source-badge">${this.source_icon(r.source)} ${r.source}</span></td>
                  <td><span class="indicator-pill ${this.risk_color(r.risk_level)}">${r.risk_level || "Normal"}</span></td>
                  <td>${r.alert_generated ? '🚨' : '—'}</td>
                  <td>
                    ${r.reviewed_by_nurse ? '👩‍⚕️' : ''}
                    ${r.reviewed_by_doctor ? '👨‍⚕️' : ''}
                    ${!r.reviewed_by_nurse && !r.reviewed_by_doctor ? '<span class="text-muted">Pending</span>' : ''}
                  </td>
                </tr>
              `).join("")}
            </tbody>
          </table>
          ${!d.readings?.length ? '<p class="text-muted text-center p-4">No readings for this date.</p>' : ""}
        </div>
      </div>
    `);
  }

  source_icon(source) {
    return {"App": "📱", "BP Device": "🩺", "Glucometer": "🔬", "Clinic": "🏥", "5G Hub": "📡"}[source] || "📊";
  }

  risk_color(level) {
    return {"Very High": "red", "High": "orange", "Medium": "yellow", "Low": "blue", "Normal": "green"}[level] || "green";
  }
}
