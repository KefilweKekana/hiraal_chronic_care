(function () {
// ─── Daily Readings — rendered inside the shared HiraalShell (same
// top bar + sidebar + frame as Clinic Dashboard). See public/js/hiraal_sidebar.js.
frappe.pages["daily-readings"].on_page_load = function (wrapper) {
  const page = frappe.ui.make_app_page({
    parent: wrapper,
    title: "Daily Readings",
    single_column: true,
  });
  page.main.html('<div id="readings-root"></div>');
  const boot = function () {
    HiraalShell.mount(page, wrapper);
    new DailyReadingsDashboard(page);
  };
  if (window.HiraalShell) boot();
  else frappe.require("/assets/hiraal_emr/js/hiraal_sidebar.js", boot);
};

class DailyReadingsDashboard {
  constructor(page) {
    this.page = page;
    this.container = page.main.find("#readings-root");
    this.selected_date = frappe.datetime.get_today();
    this.load_data();
  }

  shell(content) {
    this.container.html(HiraalShell.render("daily-readings", "Daily Readings", content));
    HiraalShell.bind(this.container, () => this.load_data());
    this.bind_date();
  }

  bind_date() {
    this.container.find(".rd-date-input").on("change", (e) => {
      this.selected_date = e.target.value || this.selected_date;
      this.load_data();
    });
  }

  async load_data() {
    this.shell('<div class="hd-loading">Loading readings…</div>');
    try {
      const data = await frappe.xcall("hiraal_emr.api.get_readings_dashboard_data", {
        date: this.selected_date,
      });
      this.data = data;
      this.render();
    } catch (e) {
      console.error(e);
      this.shell('<div class="hd-loading">Error loading readings.</div>');
    }
  }

  render() {
    const d = this.data;
    const content = `
      <div class="readings-page">
        <!-- Date filter -->
        <div class="rd-filters">
          <input type="date" class="form-control rd-date-input" value="${this.selected_date}">
        </div>

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
                  <td>${r.medicine_taken === 'Yes' ? '✅ Yes' : '<span class="text-muted">No</span>'}</td>
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
    `;

    this.shell(content);
  }

  source_icon(source) {
    return {"App": "📱", "BP Device": "🩺", "Glucometer": "🔬", "Clinic": "🏥", "5G Hub": "📡"}[source] || "📊";
  }

  risk_color(level) {
    return {"Very High": "red", "Critical": "red", "High": "orange", "Medium": "yellow", "Low": "blue", "Normal": "green"}[level] || "green";
  }
}
})();
