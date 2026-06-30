(function () {
frappe.pages["telemedicine-waiting-room"].on_page_load = function (wrapper) {
  const page = frappe.ui.make_app_page({
    parent: wrapper,
    title: "Telemedicine Waiting Room",
    single_column: true,
  });
  page.main.html('<div id="telemed-root"></div>');
  const boot = function () {
    HiraalShell.mount(page, wrapper);
    new TelemedWaitingRoom(page);
  };
  if (window.HiraalShell) boot();
  else frappe.require("/assets/hiraal_emr/js/hiraal_sidebar.js", boot);
};

class TelemedWaitingRoom {
  constructor(page) {
    this.page = page;
    this.container = page.main.find("#telemed-root");
    this.load();
    // Auto-refresh so a patient joining appears without manual refresh.
    this.timer = setInterval(() => this.load(), 20000);
  }

  _alive() {
    return this.container && this.container.length && document.body.contains(this.container[0]);
  }

  shell(content) {
    this.container.html(HiraalShell.render("telemedicine", "Telemedicine Waiting Room", content));
    HiraalShell.bind(this.container, () => this.load());
  }

  async load() {
    if (!this._alive()) {
      clearInterval(this.timer);
      return;
    }
    if (!this.data_loaded) {
      this.shell('<div class="hd-loading">Loading…</div>');
    }
    try {
      const rows = await frappe.xcall("hiraal_emr.api.get_waiting_telemedicine_sessions");
      this.data_loaded = true;
      this.render(rows || []);
    } catch (e) {
      this.shell('<div class="hd-loading">Could not load sessions.</div>');
    }
  }

  render(rows) {
    const S = HiraalShell;
    const waiting = rows.filter((r) => r.session_status === "In Progress").length;
    const scheduled = rows.length - waiting;

    const kpis =
      '<div style="display:grid;grid-template-columns:repeat(2,minmax(220px,320px));gap:16px">' +
        S.skpi(waiting, "Waiting Now", "live in the queue", "video_camera_front", "chip-danger") +
        S.skpi(scheduled, "Scheduled Today", "upcoming visits", "event", "chip-neutral") +
      "</div>";

    let body;
    if (!rows.length) {
      body = S.empty("video_camera_front", "No patients are waiting right now.", "chip-teal");
    } else {
      const cols = "grid-template-columns:1.5fr 1.2fr 1fr 0.9fr 1.2fr";
      let trows = "";
      rows.forEach((r) => {
        const isWaiting = r.session_status === "In Progress";
        const name = r.patient_name || r.patient || "Patient";
        const when = r.start_time ? frappe.datetime.str_to_user(r.start_time) : "—";
        const url = r.meeting_url || "";
        const pill = isWaiting
          ? '<span class="hd-status-pill in-progress">Waiting now</span>'
          : '<span class="hd-status-pill">Scheduled</span>';
        const join = url
          ? '<button class="telemed-join" data-url="' + S.esc(url) + '" style="background:#0c6b62;color:#fff;border:none;border-radius:8px;padding:6px 12px;font:inherit;font-size:12.5px;font-weight:600;cursor:pointer">Join Call</button>'
          : '<span style="color:#9aa7a7;font-size:12px">No link</span>';
        const done = isWaiting
          ? ' <button class="telemed-done" data-name="' + S.esc(r.name) + '" style="background:#fff;border:1px solid #dfe6e6;border-radius:8px;padding:6px 12px;font:inherit;font-size:12.5px;font-weight:600;color:#3a4754;cursor:pointer;margin-left:6px">Mark Done</button>'
          : "";
        trows +=
          '<div class="hd-trow" style="' + cols + '">' +
            '<span class="hd-pt-cell"><span class="hd-pt-avatar" style="background:' + S.avatarColor(name) + '">' +
              S.initials(name) + '</span><span><span class="hd-pt-name">' + S.esc(name) +
              '</span><br><span class="hd-pt-id">' + S.esc(r.patient || "") + "</span></span></span>" +
            '<span class="hd-cell-muted">' + S.esc(r.practitioner_name || r.practitioner || "Unassigned") + "</span>" +
            '<span class="hd-cell-muted">' + S.esc(when) + "</span>" +
            "<span>" + pill + "</span>" +
            "<span>" + join + done + "</span>" +
          "</div>";
      });
      body =
        '<div class="hd-thead" style="' + cols + '"><span>PATIENT</span><span>DOCTOR</span>' +
        "<span>TIME</span><span>STATUS</span><span>ACTION</span></div>" + trows;
    }

    const content = kpis + '<div style="margin-top:16px">' +
      S.panel("Patients Waiting", body, { link: "All Sessions", linkHref: "/app/telemedicine-session" }) + "</div>";

    this.shell(content);

    this.container.find("button.telemed-join").on("click", function () {
      const u = $(this).attr("data-url");
      if (u) window.open(u, "_blank", "noopener");
    });
    const self = this;
    this.container.find("button.telemed-done").on("click", function () {
      const n = $(this).attr("data-name");
      if (!n) return;
      frappe.confirm("End this video visit and mark it completed?", function () {
        frappe.xcall("hiraal_emr.api.complete_telemedicine_session", { name: n }).then(function (r) {
          frappe.show_alert({
            message: "Visit completed" + (r && r.duration_minutes != null ? " (" + r.duration_minutes + " min)" : ""),
            indicator: "green",
          });
          self.load();
        });
      });
    });
  }
}
})();
