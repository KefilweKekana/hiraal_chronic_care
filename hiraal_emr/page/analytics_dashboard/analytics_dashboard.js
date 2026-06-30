(function () {
frappe.pages["analytics-dashboard"].on_page_load = function (wrapper) {
  const page = frappe.ui.make_app_page({
    parent: wrapper,
    title: "Analytics",
    single_column: true,
  });
  page.main.html('<div id="analytics-root"></div>');
  const boot = function () {
    HiraalShell.mount(page, wrapper);
    new AnalyticsDashboard(page);
  };
  if (window.HiraalShell) boot();
  else frappe.require("/assets/hiraal_emr/js/hiraal_sidebar.js", boot);
};

class AnalyticsDashboard {
  constructor(page) {
    this.page = page;
    this.container = page.main.find("#analytics-root");
    this.load_data();
  }

  shell(content) {
    this.container.html(HiraalShell.render("analytics", "Analytics", content));
    HiraalShell.bind(this.container, () => this.load_data());
  }

  async load_data() {
    this.shell('<div class="hd-loading">Loading analytics…</div>');
    try {
      this.data = await frappe.xcall("hiraal_emr.api.get_analytics_data");
      this.render();
    } catch (e) {
      console.error(e);
      this.shell('<div class="hd-loading">Could not load analytics.</div>');
    }
  }

  kpi(value, label, delta, icon, chip) {
    return '<div class="hd-kpi"><div class="hd-kpi-icon ' + chip + '">' + HiraalShell.msr(icon) + "</div>" +
      '<div class="hd-kpi-value">' + (value == null ? 0 : value) + "</div>" +
      '<div class="hd-kpi-label">' + label + "</div>" +
      (delta ? '<div class="hd-kpi-delta muted">' + HiraalShell.esc(delta) + "</div>" : "") + "</div>";
  }

  funnel(label, count, total, pct) {
    const w = total ? Math.max(6, Math.round((count / total) * 100)) : 6;
    return '<div class="hd-funnel"><div class="hd-funnel-head"><span>' + label + "</span><span>" +
      (count || 0) + " (" + pct + ")</span></div>" +
      '<div class="hd-funnel-track"><div class="hd-funnel-fill" style="width:' + w + '%"></div></div></div>';
  }

  render() {
    const d = this.data || {};
    const S = HiraalShell;

    const kpis =
      '<div class="hd-kpi-row">' +
        this.kpi(d.total_patients, "Total Patients", (d.patient_growth || "") + " from last period", "groups", "chip-teal") +
        this.kpi(d.active_subscriptions, "Active Subscriptions", (d.subscription_growth || "") + " from last period", "card_membership", "chip-neutral") +
        this.kpi("$" + (d.monthly_revenue || 0).toLocaleString(), "Monthly Revenue", (d.revenue_growth || "") + " from last period", "payments", "chip-green") +
        this.kpi(d.high_risk_patients, "High-Risk Patients", (d.risk_growth || "") + " from last period", "warning", "chip-danger") +
        this.kpi((d.engagement_score || 0) + "%", "Avg. Engagement", (d.engagement_growth || "") + " from last period", "monitor_heart", "chip-amber") +
      "</div>";

    const outcomes =
      '<div id="health-outcomes-chart" class="hd-chart" style="min-height:200px"></div>' +
      '<div class="hd-outcomes">' +
        '<div><b style="color:#0c8a5e">' + (d.controlled_bp || 0) + "%</b>Controlled BP</div>" +
        '<div><b style="color:#0c6b62">' + (d.controlled_sugar || 0) + "%</b>Controlled Sugar</div>" +
        '<div><b style="color:#c0413f">' + (d.uncontrolled || 0) + "%</b>Uncontrolled</div>" +
      "</div>";

    const revenue = '<div id="revenue-chart" class="hd-chart" style="min-height:230px"></div>';

    const ops =
      '<div class="hd-ops">' +
        '<div><div class="hd-ops-val">' + (d.nurse_tasks_completed || 0) + '</div><div class="hd-ops-lbl">Nurse Tasks Completed</div></div>' +
        '<div><div class="hd-ops-val">' + (d.doctor_reviews_done || 0) + '</div><div class="hd-ops-lbl">Doctor Reviews Done</div></div>' +
        '<div><div class="hd-ops-val">' + (d.avg_response_hours || 0) + 'h</div><div class="hd-ops-lbl">Avg Response Time</div></div>' +
      "</div>";

    const funnel =
      this.funnel("Submitted Readings", d.funnel_submitted, d.total_patients, "100%") +
      this.funnel("Reviewed by Nurse", d.funnel_nurse_reviewed, d.total_patients, (d.funnel_nurse_pct || 0) + "%") +
      this.funnel("Reviewed by Doctor", d.funnel_doctor_reviewed, d.total_patients, (d.funnel_doctor_pct || 0) + "%") +
      this.funnel("Action Taken", d.funnel_action_taken, d.total_patients, (d.funnel_action_pct || 0) + "%");

    const riskCols = "grid-template-columns:1.3fr 0.8fr 0.6fr 0.9fr";
    const riskRow = (cls, label, count, pct, trend) =>
      '<div class="hd-trow" style="' + riskCols + '">' +
        '<span><span class="hd-reason ' + cls + '"><span class="dot"></span>' + label + "</span></span>" +
        "<span>" + (count || 0) + "</span><span>" + (pct || 0) + '%</span>' +
        '<span class="hd-cell-muted">' + S.esc(trend || "—") + "</span></div>";
    const riskTable =
      '<div class="hd-thead" style="' + riskCols + '"><span>RISK LEVEL</span><span>PATIENTS</span><span>%</span><span>TREND</span></div>' +
      riskRow("high", "High Risk", d.risk_high, d.risk_high_pct, d.risk_high_trend) +
      riskRow("medium", "Medium Risk", d.risk_medium, d.risk_medium_pct, d.risk_medium_trend) +
      riskRow("low", "Low Risk", d.risk_low, d.risk_low_pct, d.risk_low_trend);

    const insights = (d.insights || []).length
      ? (d.insights || []).map((i) =>
          '<div class="hd-insight">' + S.msr("tips_and_updates") +
          '<div><div class="hd-insight-title">' + S.esc(i.title) + "</div>" +
          '<div class="hd-insight-desc">' + S.esc(i.description) + "</div></div></div>").join("")
      : S.empty("tips_and_updates", "No insights available yet.", "chip-teal");

    const content =
      kpis +
      '<div class="hd-2col">' + S.panel("Health Outcomes", outcomes) + S.panel("Revenue Trend", revenue) + "</div>" +
      '<div class="hd-2col">' + S.panel("Operations Overview", ops) + S.panel("Engagement Funnel", funnel) + "</div>" +
      '<div class="hd-2col">' + S.panel("Patient Risk Distribution", riskTable) + S.panel("Key Insights", insights) + "</div>";

    this.shell(content);
    this.render_charts();
  }

  render_charts() {
    const d = this.data || {};
    const outcomes_el = this.container.find("#health-outcomes-chart");
    if (outcomes_el.length && d.controlled_bp != null && typeof frappe.Chart !== "undefined") {
      new frappe.Chart(outcomes_el[0], {
        data: {
          labels: ["Controlled BP", "Controlled Sugar", "Uncontrolled"],
          datasets: [{ values: [d.controlled_bp || 0, d.controlled_sugar || 0, d.uncontrolled || 0] }],
        },
        type: "donut",
        height: 200,
        colors: ["#0c8a5e", "#0c6b62", "#c0413f"],
      });
    }
    const rev_el = this.container.find("#revenue-chart");
    if (rev_el.length && d.revenue_trend && typeof frappe.Chart !== "undefined") {
      new frappe.Chart(rev_el[0], {
        data: {
          labels: d.revenue_trend.labels || [],
          datasets: [
            { name: "Collected", values: d.revenue_trend.collected || [] },
            { name: "Pending", values: d.revenue_trend.pending || [] },
          ],
        },
        type: "bar",
        height: 230,
        colors: ["#0c8a5e", "#d99b2c"],
        barOptions: { stacked: 1 },
      });
    }
  }
}
})();
