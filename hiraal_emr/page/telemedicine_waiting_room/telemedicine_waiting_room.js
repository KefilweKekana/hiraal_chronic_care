// Telemedicine Waiting Room — clinic-side view of patients waiting in a video
// visit, with one-click "Join Call". Reads hiraal_emr.api.get_waiting_telemedicine_sessions.
frappe.pages["telemedicine-waiting-room"].on_page_load = function (wrapper) {
  const page = frappe.ui.make_app_page({
    parent: wrapper,
    title: "Telemedicine Waiting Room",
    subtitle: "Patients waiting now — join their video call in one click",
    single_column: true,
  });
  page.main.html('<div id="telemed-root" style="padding:8px 4px;"></div>');
  new TelemedWaitingRoom(page);
};

class TelemedWaitingRoom {
  constructor(page) {
    this.page = page;
    this.container = page.main.find("#telemed-root");
    this.page.set_primary_action("Refresh", () => this.load(), "refresh");
    this.load();
    // Auto-refresh so a patient joining appears without manual refresh.
    this.timer = setInterval(() => this.load(), 20000);
  }

  _alive() {
    return this.container && this.container.length && document.body.contains(this.container[0]);
  }

  async load() {
    // Self-cleanup: stop polling once the user has navigated away from the page.
    if (!this._alive()) {
      clearInterval(this.timer);
      return;
    }
    try {
      const rows = await frappe.xcall("hiraal_emr.api.get_waiting_telemedicine_sessions");
      this.render(rows || []);
    } catch (e) {
      this.container.html(
        '<div style="padding:24px;color:#b00;">Could not load sessions. ' +
          frappe.utils.escape_html((e && e.message) || "") +
          "</div>"
      );
    }
  }

  render(rows) {
    if (!rows.length) {
      this.container.html(
        '<div style="padding:48px;text-align:center;color:#6b7280;">No patients are waiting right now.</div>'
      );
      return;
    }
    const esc = frappe.utils.escape_html;
    let h = '<div style="display:flex;flex-direction:column;gap:12px;max-width:760px;">';
    rows.forEach((r) => {
      const waiting = r.session_status === "In Progress";
      const badge = waiting
        ? '<span style="background:#e0f5f7;color:#03A9B5;padding:3px 10px;border-radius:20px;font-size:12px;font-weight:600;">Waiting now</span>'
        : '<span style="background:#f0f2f5;color:#6b7280;padding:3px 10px;border-radius:20px;font-size:12px;">Scheduled</span>';
      const when = r.start_time ? frappe.datetime.str_to_user(r.start_time) : "";
      const url = r.meeting_url || "";
      const join = url
        ? '<button class="btn btn-primary btn-sm telemed-join" data-url="' + esc(url) + '">Join Call</button>'
        : '<span style="color:#9ca3af;font-size:12px;">No link</span>';
      h += '<div style="display:flex;align-items:center;justify-content:space-between;gap:12px;border:1px solid #E5E9F0;border-radius:12px;padding:14px 16px;background:#fff;">';
      h += "<div><div style=\"font-weight:600;font-size:15px;\">" + esc(r.patient_name || r.patient || "Patient") + "</div>";
      h += '<div style="color:#6b7280;font-size:13px;margin-top:2px;">' +
        esc(r.practitioner_name || r.practitioner || "Unassigned") +
        (when ? " &bull; " + esc(when) : "") +
        "</div></div>";
      h += '<div style="display:flex;align-items:center;gap:12px;">' + badge + join + "</div>";
      h += "</div>";
    });
    h += "</div>";
    this.container.html(h);
    this.container.find("button.telemed-join").on("click", function () {
      const u = $(this).attr("data-url");
      if (u) window.open(u, "_blank", "noopener");
    });
  }
}
