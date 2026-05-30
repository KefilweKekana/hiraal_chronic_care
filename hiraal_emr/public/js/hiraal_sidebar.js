// Shared sidebar component for Hiraal EMR pages
// Usage: wrap your page content with HiraalSidebar.render(activeItem, contentHtml)

window.HiraalSidebar = {
  menu_items: [
    {
      section: "CLINICAL",
      items: [
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
      ]
    },
    {
      section: "BILLING",
      items: [
        { label: "Subscriptions", icon: "🔄", route: "/app/care-subscription", name: "subscriptions" },
        { label: "Payments", icon: "💳", route: "/app/subscription-payment", name: "payments" },
      ]
    },
    {
      section: "REPORTS",
      items: [
        { label: "Reports", icon: "📋", route: "/app/query-report/Patient Summary", name: "reports" },
        { label: "Analytics", icon: "📉", route: "/app/analytics-dashboard", name: "analytics" },
      ]
    },
    {
      section: "SETTINGS",
      items: [
        { label: "Settings", icon: "⚙️", route: "/app/chronic-care-settings", name: "settings" },
        { label: "User Management", icon: "👤", route: "/app/user", name: "user-management" },
      ]
    },
  ],

  render(activeItemName, badgeCounts = {}) {
    return `
      <aside class="dashboard-sidebar">
        <div class="sidebar-brand">
          <div class="brand-logo">🏥</div>
          <div class="brand-text">
            <div class="brand-title">DagaarSoft</div>
            <div class="brand-subtitle">Health Clinic</div>
          </div>
        </div>
        <nav class="sidebar-nav">
          ${this.menu_items.map(section => `
            <div class="sidebar-section">
              <div class="sidebar-section-title">${section.section}</div>
              <ul class="sidebar-menu">
                ${section.items.map(item => {
                  const isActive = item.name === activeItemName;
                  const badge = badgeCounts[item.name] || 0;
                  return `
                    <li class="sidebar-menu-item ${isActive ? 'active' : ''}">
                      <a href="${item.route}" class="sidebar-menu-link">
                        <span class="sidebar-icon">${item.icon}</span>
                        <span class="sidebar-label">${item.label}</span>
                        ${badge > 0 ? `<span class="sidebar-badge">${badge}</span>` : ''}
                      </a>
                    </li>
                  `;
                }).join('')}
              </ul>
            </div>
          `).join('')}
        </nav>
        <div class="sidebar-footer">
          <div class="need-help">
            <div class="help-icon">💬</div>
            <div class="help-text">
              <div class="help-title">Need Help?</div>
              <div class="help-link">Contact Support</div>
              <div class="help-email">support@dagaar.so</div>
            </div>
          </div>
        </div>
      </aside>
    `;
  },

  wrapPage(activeItemName, contentHtml, badgeCounts = {}) {
    return `
      <div class="dashboard-with-sidebar">
        ${this.render(activeItemName, badgeCounts)}
        <div class="dashboard-main">
          ${contentHtml}
        </div>
      </div>
    `;
  }
};
