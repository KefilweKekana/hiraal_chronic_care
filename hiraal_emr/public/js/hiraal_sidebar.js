// Hiraal EMR — shared "Calm Clinical" desk shell.
// Loaded globally via app_include_js. Desk pages render their content inside
// HiraalShell.render(activeName, title, contentHtml) to get a consistent
// top bar + sidebar + frame. CSS lives in hiraal_emr.css (.hiraal-dash / .hd-*).
(function () {
  const LOGO = "/assets/hiraal_emr/images/hiraal_logo.png";

  const NAV = [
    { items: [
      { label: "Dashboard", icon: "dashboard", route: "/app/clinic-dashboard", name: "dashboard" },
      { label: "Alerts", icon: "notifications_active", route: "/app/chronic-care-alert", name: "alerts" },
      { label: "Patients", icon: "groups", route: "/app/patient", name: "patients" },
      { label: "Daily Readings", icon: "vital_signs", route: "/app/daily-reading", name: "daily-readings" },
      { label: "Nurse Tasks", icon: "task_alt", route: "/app/nurse-task", name: "nurse-tasks" },
      { label: "Doctor Review", icon: "stethoscope", route: "/app/doctor-review", name: "doctor-review" },
      { label: "Appointments", icon: "calendar_month", route: "/app/patient-appointment", name: "appointments" },
      { label: "Lab Requests", icon: "science", route: "/app/lab-test", name: "lab-requests" },
      { label: "Medicine Requests", icon: "medication", route: "/app/medicine-request", name: "medicine-requests" },
      { label: "Devices", icon: "devices", route: "/app/patient-device", name: "devices" },
      { label: "Telemedicine", icon: "video_camera_front", route: "/app/telemedicine-waiting-room", name: "telemedicine" },
    ]},
    { label: "BILLING", items: [
      { label: "Subscriptions", icon: "card_membership", route: "/app/care-subscription", name: "subscriptions" },
      { label: "Payments", icon: "payments", route: "/app/subscription-payment", name: "payments" },
    ]},
    { label: "REPORTS", items: [
      { label: "Reports", icon: "description", route: "/app/query-report/Patient Summary", name: "reports" },
      { label: "Analytics", icon: "analytics", route: "/app/analytics-dashboard", name: "analytics" },
    ]},
    { label: "SETTINGS", items: [
      { label: "Settings", icon: "settings", route: "/app/chronic-care-settings", name: "settings" },
      { label: "User Management", icon: "manage_accounts", route: "/app/user", name: "user-management" },
    ]},
  ];

  const Shell = {
    LOGO,
    NAV,

    ensureFonts() {
      if (document.getElementById("hiraal-dash-fonts")) return;
      const l = document.createElement("link");
      l.id = "hiraal-dash-fonts";
      l.rel = "stylesheet";
      l.href =
        "https://fonts.googleapis.com/css2?family=Hanken+Grotesk:wght@400;500;600;700" +
        "&family=Material+Symbols+Rounded:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200&display=swap";
      document.head.appendChild(l);
    },

    // Hide Frappe's default page head so the design owns the canvas.
    mount(page, wrapper) {
      this.ensureFonts();
      try { $(wrapper).find(".page-head").hide(); } catch (e) {}
    },

    msr(name) { return '<span class="msr">' + name + "</span>"; },
    esc(s) {
      return (s == null ? "" : String(s)).replace(/[&<>"']/g, (c) =>
        ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
    },
    initials(name) {
      if (!name) return "?";
      return name.trim().split(/\s+/).map((p) => p[0]).join("").toUpperCase().slice(0, 2);
    },
    avatarColor(name) {
      const colors = ["#0c6b62", "#2563EB", "#16A34A", "#D97706", "#9333EA", "#0D9488", "#DB2777", "#c05a3f"];
      let h = 0;
      for (let i = 0; i < (name || "").length; i++) h = name.charCodeAt(i) + ((h << 5) - h);
      return colors[Math.abs(h) % colors.length];
    },

    topbar() {
      return (
        '<div class="hd-topbar">' +
          '<div class="hd-brand"><img class="hd-brand-img" src="' + LOGO + '" alt="Hiraal Care">' +
            '<span class="hd-brand-name">Hiraal Care</span></div>' +
          '<form class="hd-search" data-search>' + this.msr("search") +
            '<input class="hd-search-input" type="text" autocomplete="off" placeholder="Search patients by name…">' +
            '<span class="hd-search-chip">⌘G</span></form>' +
        "</div>"
      );
    },

    sidebar(activeName) {
      let nav = "";
      NAV.forEach((group) => {
        if (group.label) nav += '<div class="hd-nav-label">' + group.label + "</div>";
        group.items.forEach((i) => {
          const active = i.name === activeName ? " active" : "";
          nav += '<a class="hd-nav-item' + active + '" href="' + i.route + '">' +
            this.msr(i.icon) + "<span>" + i.label + "</span></a>";
        });
      });
      return (
        '<aside class="hd-sidebar">' +
          '<div class="hd-side-head"><img class="hd-side-img" src="' + LOGO + '" alt="Hiraal Care">' +
            '<div><div class="hd-side-title">Hiraal Care</div>' +
            '<div class="hd-side-sub">Health Clinic</div></div></div>' +
          '<nav class="hd-nav">' + nav + "</nav>" +
          '<div class="hd-help"><div class="hd-help-card">' +
            '<div class="hd-help-title">' + this.msr("support_agent") + "Need help?</div>" +
            '<div class="hd-help-contact">Contact Support</div>' +
            '<div class="hd-help-email">support@dagaar.so</div></div></div>' +
        "</aside>"
      );
    },

    pageHeader(title, opts) {
      opts = opts || {};
      const date = opts.date === false ? "" :
        '<span class="hd-datechip">' + frappe.datetime.str_to_user(frappe.datetime.get_today()) + "</span>";
      const refresh = opts.refresh === false ? "" :
        '<button class="hd-refresh" data-hd-refresh>' + this.msr("refresh") + "Refresh</button>";
      return '<div class="hd-page-head"><h1 class="hd-h1">' + this.esc(title) + "</h1>" + date + refresh + "</div>";
    },

    // Full frame: top bar + sidebar + main(page header + content).
    render(activeName, title, contentHtml, opts) {
      return (
        '<div class="hiraal-dash"><div class="hiraal-dash-wrap"><div class="hd-frame">' +
          this.topbar() +
          '<div class="hd-body">' + this.sidebar(activeName) +
          '<main class="hd-main">' + this.pageHeader(title, opts) + (contentHtml || "") + "</main></div>" +
        "</div></div></div>"
      );
    },

    // Wire the search box + a refresh handler. Call after injecting render() html.
    bind($root, onRefresh) {
      const form = $root.find("[data-search]");
      const input = form.find(".hd-search-input");
      form.on("click", () => input.trigger("focus"));
      form.on("submit", (e) => {
        e.preventDefault();
        const q = (input.val() || "").trim();
        if (!q) return;
        if (/^PID/i.test(q)) frappe.set_route("Form", "Patient", q.toUpperCase());
        else frappe.set_route("List", "Patient", { patient_name: ["like", "%" + q + "%"] });
      });
      if (typeof onRefresh === "function") $root.find("[data-hd-refresh]").on("click", onRefresh);
    },

    // ── content helpers ──
    empty(icon, text, chipClass) {
      return '<div class="hd-empty"><div class="hd-empty-icon ' + (chipClass || "chip-neutral") + '">' +
        this.msr(icon) + '</div><div class="hd-empty-text">' + this.esc(text) + "</div></div>";
    },
    panel(title, bodyHtml, opts) {
      opts = opts || {};
      const link = opts.linkHref
        ? '<a class="hd-link" href="' + opts.linkHref + '">' + this.esc(opts.link || "View All") + "</a>"
        : (opts.right || "");
      return '<div class="hd-panel"><div class="hd-panel-head sb"><h2 class="hd-panel-title">' +
        this.esc(title) + "</h2>" + link + "</div>" + bodyHtml + "</div>";
    },
    skpi(value, label, sub, icon, chip, route, subClass) {
      const open = route ? '<a class="hd-skpi" href="' + route + '">' : '<div class="hd-skpi">';
      const close = route ? "</a>" : "</div>";
      return open + '<div class="hd-skpi-icon ' + chip + '">' + this.msr(icon) + "</div>" +
        '<div><div class="hd-skpi-value">' + (value == null ? 0 : value) + "</div>" +
        '<div class="hd-skpi-label">' + label + "</div>" +
        '<div class="hd-skpi-sub ' + (subClass || "") + '">' + sub + "</div></div>" + close;
    },
    statusPill(status) {
      const cls = (status || "").toLowerCase().replace(/\s+/g, "-");
      return '<span class="hd-status-pill ' + cls + '">' + this.esc(status || "—") + "</span>";
    },
  };

  window.HiraalShell = Shell;
  // Backwards-compatible alias for any older references.
  window.HiraalSidebar = Shell;

  // Immersive mode: on the full-screen clinic pages, hide Frappe's global
  // navbar so only the design's own top bar shows (matches the handoff).
  // Toggles a body class on every route change; restored when you leave.
  if (!window.__hiraalImmersiveBound) {
    window.__hiraalImmersiveBound = true;
    const IMMERSIVE = ["clinic-dashboard", "telemedicine-waiting-room", "analytics-dashboard"];
    const toggleImmersive = function () {
      try {
        const r = (frappe.get_route_str() || "").split("/")[0];
        $(document.body).toggleClass("hiraal-immersive", IMMERSIVE.indexOf(r) !== -1);
      } catch (e) {}
    };
    try { frappe.router.on("change", toggleImmersive); } catch (e) {}
    $(document).on("page-change", toggleImmersive);
    toggleImmersive();
  }
})();
