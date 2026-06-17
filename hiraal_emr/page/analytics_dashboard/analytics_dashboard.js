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

frappe.pages["analytics-dashboard"].on_page_load = function (wrapper) {
  const page = frappe.ui.make_app_page({
    parent: wrapper,
    title: "Analytics",
    subtitle: "Deep insights to improve patient outcomes and grow your clinic",
    single_column: true,
  });

  page.main.html('<div id="analytics-root"></div>');
  new AnalyticsDashboard(page);
};

class AnalyticsDashboard {
  constructor(page) {
    this.page = page;
    this.container = page.main.find("#analytics-root");
    this.page.set_secondary_action("Refresh", () => this.load_data(), "refresh");
    this.load_data();
  }

  async load_data() {
    this.container.html(HiraalMenu.wrap("analytics", '<div class="empty-state">Loading analytics...</div>'));
    try {
      const data = await frappe.xcall("hiraal_emr.api.get_analytics_data");
      this.data = data;
      this.render();
    } catch (e) {
      console.error(e);
      this.container.html(HiraalMenu.wrap("analytics", '<div class="empty-state">Error loading analytics.</div>'));
    }
  }

  render() {
    const d = this.data;
    const content = `
      <div class="analytics-page" style="padding:15px">
        <!-- Top KPIs -->
        <div class="kpi-row">
          ${this.kpi("Total Patients", d.total_patients, d.patient_growth + " from last period")}
          ${this.kpi("Active Subscriptions", d.active_subscriptions, d.subscription_growth + " from last period")}
          ${this.kpi("Monthly Revenue", "$" + (d.monthly_revenue || 0).toLocaleString(), d.revenue_growth + " from last period")}
          ${this.kpi("High-Risk Patients", d.high_risk_patients, d.risk_growth + " from last period")}
          ${this.kpi("Avg. Engagement", (d.engagement_score || 0) + "%", d.engagement_growth + " from last period")}
        </div>

        <div class="dashboard-grid">
          <!-- Health Outcomes -->
          <div class="dashboard-card">
            <div class="card-header"><h3>Health Outcomes</h3></div>
            <div class="card-body">
              <div id="health-outcomes-chart" style="height:220px"></div>
              <div class="outcomes-legend" style="display:flex;justify-content:space-around;padding:10px 0;font-size:13px">
                <div><strong style="color:#27AE60">${d.controlled_bp || 0}%</strong><br>Controlled BP</div>
                <div><strong style="color:#3498DB">${d.controlled_sugar || 0}%</strong><br>Controlled Sugar</div>
                <div><strong style="color:#E74C3C">${d.uncontrolled || 0}%</strong><br>Uncontrolled</div>
              </div>
            </div>
          </div>

          <!-- Revenue Trend -->
          <div class="dashboard-card">
            <div class="card-header"><h3>Revenue Trend</h3></div>
            <div class="card-body">
              <div id="revenue-chart" style="height:250px"></div>
            </div>
          </div>
        </div>

        <div class="dashboard-grid">
          <!-- Operations Overview -->
          <div class="dashboard-card">
            <div class="card-header"><h3>Operations Overview</h3></div>
            <div class="card-body">
              <div class="ops-grid" style="display:grid;grid-template-columns:repeat(3,1fr);gap:12px;text-align:center">
                <div><div style="font-size:22px;font-weight:700">${d.nurse_tasks_completed || 0}</div><div class="text-muted" style="font-size:12px">Nurse Tasks Completed</div></div>
                <div><div style="font-size:22px;font-weight:700">${d.doctor_reviews_done || 0}</div><div class="text-muted" style="font-size:12px">Doctor Reviews Done</div></div>
                <div><div style="font-size:22px;font-weight:700">${d.avg_response_hours || 0}h</div><div class="text-muted" style="font-size:12px">Avg Response Time</div></div>
              </div>
            </div>
          </div>

          <!-- Engagement Funnel -->
          <div class="dashboard-card">
            <div class="card-header"><h3>Engagement Funnel</h3></div>
            <div class="card-body">
              ${this.funnel_bar("Submitted Readings", d.funnel_submitted, d.total_patients, "100%")}
              ${this.funnel_bar("Reviewed by Nurse", d.funnel_nurse_reviewed, d.total_patients, d.funnel_nurse_pct + "%")}
              ${this.funnel_bar("Reviewed by Doctor", d.funnel_doctor_reviewed, d.total_patients, d.funnel_doctor_pct + "%")}
              ${this.funnel_bar("Action Taken", d.funnel_action_taken, d.total_patients, d.funnel_action_pct + "%")}
            </div>
          </div>
        </div>

        <div class="dashboard-grid">
          <!-- Patient Risk Distribution -->
          <div class="dashboard-card">
            <div class="card-header"><h3>Patient Risk Distribution</h3></div>
            <div class="card-body">
              <table class="table table-sm">
                <thead><tr><th>Risk Level</th><th>Patients</th><th>%</th><th>Trend</th></tr></thead>
                <tbody>
                  <tr><td><span class="indicator-pill red">High Risk</span></td><td>${d.risk_high || 0}</td><td>${d.risk_high_pct || 0}%</td><td>${d.risk_high_trend || ""}</td></tr>
                  <tr><td><span class="indicator-pill orange">Medium Risk</span></td><td>${d.risk_medium || 0}</td><td>${d.risk_medium_pct || 0}%</td><td>${d.risk_medium_trend || ""}</td></tr>
                  <tr><td><span class="indicator-pill green">Low Risk</span></td><td>${d.risk_low || 0}</td><td>${d.risk_low_pct || 0}%</td><td>${d.risk_low_trend || ""}</td></tr>
                </tbody>
              </table>
            </div>
          </div>

          <!-- Key Insights -->
          <div class="dashboard-card">
            <div class="card-header"><h3>Key Insights</h3></div>
            <div class="card-body">
              ${(d.insights || []).map(i => `
                <div class="insight-item" style="display:flex;gap:10px;padding:8px 0;border-bottom:1px solid var(--border-color)">
                  <div style="font-size:18px">${i.icon || "💡"}</div>
                  <div>
                    <div style="font-size:13px;font-weight:600">${i.title}</div>
                    <div style="font-size:12px;color:var(--text-muted)">${i.description}</div>
                  </div>
                </div>
              `).join("")}
              ${!d.insights?.length ? '<p class="text-muted">No insights available yet.</p>' : ""}
            </div>
          </div>
        </div>
      </div>
    `;

    this.container.html(HiraalMenu.wrap("analytics", content));
    this.render_charts();
  }

  kpi(label, value, subtitle) {
    return `<div class="kpi-card"><div class="kpi-value">${value ?? 0}</div><div class="kpi-label">${label}</div><div class="kpi-subtitle">${subtitle || ""}</div></div>`;
  }

  funnel_bar(label, count, total, pct) {
    const width = total ? Math.max(10, (count / total) * 100) : 10;
    return `<div style="margin-bottom:10px"><div style="display:flex;justify-content:space-between;font-size:13px"><span>${label}</span><span>${count || 0} (${pct})</span></div><div style="background:#E5E7EB;border-radius:4px;height:8px;margin-top:4px"><div style="background:#4A90D9;border-radius:4px;height:8px;width:${width}%"></div></div></div>`;
  }

  render_charts() {
    // Health outcomes donut
    const outcomes_el = this.container.find("#health-outcomes-chart");
    if (outcomes_el.length && this.data.controlled_bp) {
      new frappe.Chart(outcomes_el[0], {
        data: {
          labels: ["Controlled BP", "Controlled Sugar", "Uncontrolled"],
          datasets: [{values: [this.data.controlled_bp, this.data.controlled_sugar, this.data.uncontrolled]}],
        },
        type: "donut",
        height: 200,
        colors: ["#27AE60", "#3498DB", "#E74C3C"],
      });
    }

    // Revenue trend
    const rev_el = this.container.find("#revenue-chart");
    if (rev_el.length && this.data.revenue_trend) {
      new frappe.Chart(rev_el[0], {
        data: {
          labels: this.data.revenue_trend.labels || [],
          datasets: [
            {name: "Collected", values: this.data.revenue_trend.collected || []},
            {name: "Pending", values: this.data.revenue_trend.pending || []},
          ],
        },
        type: "bar",
        height: 220,
        colors: ["#27AE60", "#F39C12"],
        barOptions: {stacked: 1},
      });
    }
  }
}
