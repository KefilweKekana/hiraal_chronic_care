(() => {
  const root = document.getElementById("hiraal-portal");
  if (!root) return;

  const main = document.getElementById("hp-main");
  const logoutBtn = document.getElementById("hp-logout");
  const state = {
    csrf: root.dataset.csrf || "",
    inviteCode: (root.dataset.code || "").trim().toUpperCase(),
    mobile: "",
    fullName: "",
    session: null,
    view: "boot",
    selected: null,
    bundle: null,
    plans: [],
    methods: [],
    pay: null,
    error: "",
    busy: false,
    tab: "home",
  };

  function escapeHtml(value) {
    return String(value ?? "")
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;");
  }

  function money(amount) {
    const n = Number(amount || 0);
    return `$${n.toFixed(2)}`;
  }

  function initial(name) {
    return ((name || "?").trim()[0] || "?").toUpperCase();
  }

  const ICONS = {
    calendar: '<svg width="20" height="20" viewBox="0 0 24 24" fill="none"><rect x="3" y="5" width="18" height="16" rx="3" stroke="currentColor" stroke-width="1.6"/><path d="M8 3v4M16 3v4M3 10h18" stroke="currentColor" stroke-width="1.6"/></svg>',
    pill: '<svg width="20" height="20" viewBox="0 0 24 24" fill="none"><path d="M8.5 15.5l7-7a3.5 3.5 0 1 1 5 5l-7 7a3.5 3.5 0 1 1-5-5z" stroke="currentColor" stroke-width="1.6"/></svg>',
    card: '<svg width="20" height="20" viewBox="0 0 24 24" fill="none"><rect x="3" y="6" width="18" height="12" rx="3" stroke="currentColor" stroke-width="1.6"/><path d="M3 10h18" stroke="currentColor" stroke-width="1.6"/></svg>',
    phone: '<svg width="22" height="22" viewBox="0 0 24 24" fill="none"><rect x="7" y="2.5" width="10" height="19" rx="2.5" stroke="currentColor" stroke-width="1.6"/><path d="M10 18h4" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/></svg>',
    user: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none"><circle cx="12" cy="8" r="4" stroke="currentColor" stroke-width="1.6"/><path d="M5 20c1.5-4 13.5-4 15 0" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/></svg>',
    lock: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none"><rect x="5" y="10" width="14" height="10" rx="2" stroke="currentColor" stroke-width="1.6"/><path d="M8 10V8a4 4 0 1 1 8 0v2" stroke="currentColor" stroke-width="1.6"/></svg>',
    shield: '<svg width="16" height="16" viewBox="0 0 24 24" fill="none"><path d="M12 3l8 4v6c0 5-3.5 8.5-8 9-4.5-.5-8-4-8-9V7l8-4z" stroke="currentColor" stroke-width="1.6"/></svg>',
  };

  function splash() {
    return `
      <div class="hp-splash">
        <div class="hp-splash-mark">
          <img class="hp-splash-logo" src="/assets/hiraal_emr/images/hiraal-logo.png" alt="Hiraal Life Care">
        </div>
        <div class="hp-splash-copy">
          <strong>Hiraal Life Care Portal</strong>
          <span>${ICONS.shield} Your data is secure.</span>
        </div>
      </div>
    `;
  }

  function authHero(invite = false) {
    const lead = invite
      ? `You were invited to support a loved one. Sign in with your phone and code <strong>${escapeHtml(state.inviteCode)}</strong> will be applied automatically.`
      : "See updates, appointments, medicines, and pay for a loved one's care plan — no app install needed.";
    return `
      <section class="hp-info-card">
        <span class="hp-kicker">Family Care</span>
        <h1>Support care from anywhere.</h1>
        <p class="hp-lead">${lead}</p>
      </section>
    `;
  }

  function authCard(inner) {
    return `<form class="hp-auth-card">${inner}</form>`;
  }

  async function api(method, data = {}) {
    const res = await fetch(`/api/method/hiraal_emr.api.${method}`, {
      method: "POST",
      credentials: "same-origin",
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json",
        "X-Frappe-CSRF-Token": state.csrf,
      },
      body: JSON.stringify(data),
    });
    const json = await res.json().catch(() => ({}));
    if (json._server_messages) {
      try {
        const msgs = JSON.parse(json._server_messages).map((m) => {
          try {
            const parsed = JSON.parse(m);
            return parsed.message || parsed;
          } catch (_) {
            return m;
          }
        });
        throw new Error(msgs.filter(Boolean).join(" "));
      } catch (err) {
        if (err.message && !String(err.message).includes("Unexpected")) throw err;
      }
    }
    if (!res.ok || json.exc_type) {
      const msg = typeof json.message === "string" ? json.message : json.message?.message;
      throw new Error(msg || json.exception || json._error_message || "Something went wrong");
    }
    return json.message ?? json;
  }

  function setError(message) {
    state.error = message || "";
    render();
  }

  function go(view, extra = {}) {
    Object.assign(state, extra, { view, error: "" });
    render();
  }

  async function boot() {
    try {
      const session = await api("portal_bootstrap");
      if (session.csrf_token) state.csrf = session.csrf_token;
      if (session.authenticated) {
        state.session = session;
        logoutBtn.hidden = false;
        if (state.inviteCode) {
          try {
            await api("redeem_invitation_code", { code: state.inviteCode });
            state.session = await api("portal_bootstrap");
          } catch (_) {
            /* keep going; user can redeem later */
          }
        }
        go("home");
        return;
      }
      go(state.inviteCode ? "welcome-invite" : "login");
    } catch (_) {
      go("login");
    }
  }

  async function requestOtp(event) {
    event.preventDefault();
    const form = new FormData(event.target);
    state.fullName = String(form.get("full_name") || "").trim();
    const localMobile = String(form.get("mobile") || "").trim();
    const digits = localMobile.replace(/\D/g, "");
    state.mobile = localMobile.startsWith("+") ? localMobile : (digits.startsWith("252") ? `+${digits}` : `+252${digits.replace(/^0+/, "")}`);
    if (!state.mobile || state.mobile.length < 8) return setError("Enter a valid mobile number.");
    if (!state.fullName) return setError("Enter your full name.");
    state.busy = true;
    render();
    try {
      await api("portal_request_otp", { mobile: state.mobile });
      go("otp");
    } catch (err) {
      setError(err.message);
    } finally {
      state.busy = false;
      render();
    }
  }

  async function verifyOtp(event) {
    event.preventDefault();
    const form = new FormData(event.target);
    const otp = String(form.get("otp") || "").trim();
    const fullName = String(form.get("full_name") || state.fullName || "").trim();
    state.busy = true;
    render();
    try {
      const result = await api("portal_verify_otp", {
        mobile: state.mobile,
        otp,
        full_name: fullName,
        invite_code: state.inviteCode,
      });
      if (result.csrf_token) state.csrf = result.csrf_token;
      state.session = result.session || (await api("portal_bootstrap"));
      logoutBtn.hidden = false;
      go("home");
    } catch (err) {
      setError(err.message);
    } finally {
      state.busy = false;
      render();
    }
  }

  async function openPerson(item) {
    state.busy = true;
    render();
    try {
      const bundle = await api("portal_patient_bundle", { patient: item.patient });
      state.selected = item;
      state.bundle = bundle;
      go("person");
    } catch (err) {
      setError(err.message);
    } finally {
      state.busy = false;
      render();
    }
  }

  async function startPay(item) {
    state.selected = item;
    state.busy = true;
    render();
    try {
      const [plans, methods] = await Promise.all([
        api("portal_plans"),
        api("portal_payment_methods"),
      ]);
      state.plans = plans.plans || [];
      const raw = methods.methods || methods || [];
      state.methods = Array.isArray(raw) ? raw : raw.methods || [];
      go("pay");
    } catch (err) {
      setError(err.message);
    } finally {
      state.busy = false;
      render();
    }
  }

  async function submitPay(event) {
    event.preventDefault();
    const form = new FormData(event.target);
    const plan = String(form.get("plan") || "");
    const methodValue = String(form.get("method") || "");
    const phone = String(form.get("phone") || "").trim();
    const [provider, method] = methodValue.split("|");
    if (!plan || !provider || !method || !phone) {
      return setError("Choose a plan, payment method, and mobile money number.");
    }
    state.busy = true;
    render();
    try {
      const result = await api("sponsor_patient_subscription", {
        patient: state.selected.patient,
        plan,
        provider,
        method,
        phone,
        family_member: state.selected.name,
      });
      state.pay = { txn: result.transaction_log, amount: result.amount, status: "Pending" };
      go("waiting");
      pollPayment();
    } catch (err) {
      setError(err.message);
    } finally {
      state.busy = false;
      render();
    }
  }

  async function pollPayment() {
    if (!state.pay?.txn) return;
    for (let i = 0; i < 40; i += 1) {
      await new Promise((r) => setTimeout(r, 3000));
      if (state.view !== "waiting") return;
      try {
        const result = await api("check_sponsor_payment", { transaction_log: state.pay.txn });
        const status = (result.status || "").toLowerCase();
        if (status === "completed") {
          state.session = await api("portal_bootstrap");
          go("paid");
          return;
        }
        if (status === "failed") {
          setError("The payment was declined or cancelled.");
          go("pay");
          return;
        }
      } catch (_) {
        /* keep polling */
      }
    }
    setError("Payment is still processing. Refresh in a minute if you already approved it.");
  }

  async function redeem(event) {
    event.preventDefault();
    const form = new FormData(event.target);
    const code = String(form.get("code") || "").trim().toUpperCase();
    state.busy = true;
    render();
    try {
      await api("redeem_invitation_code", { code });
      state.session = await api("portal_bootstrap");
      go("home");
    } catch (err) {
      setError(err.message);
    } finally {
      state.busy = false;
      render();
    }
  }

  async function logout() {
    await api("portal_logout");
    state.session = null;
    logoutBtn.hidden = true;
    go("login");
  }

  logoutBtn.addEventListener("click", logout);

  function layout(inner, { title } = {}) {
    const user = state.session?.user?.full_name || "";
    return `
      ${title ? `<div class="hp-kicker">${escapeHtml(title)}</div>` : ""}
      ${user && state.view !== "login" ? "" : ""}
      ${state.error ? `<div class="hp-error">${escapeHtml(state.error)}</div>` : ""}
      ${inner}
    `;
  }

  function peopleCards() {
    const items = state.session?.sponsorships || [];
    if (!items.length) {
      return `<div class="hp-card hp-empty">No one is linked yet. Redeem an invitation code to start supporting a loved one.</div>`;
    }
    return `<div class="hp-people">${items.map((item) => {
      const status = item.status || item.link_status || "Pending";
      const canPay = item.can_pay_for_care;
      return `
        <button class="hp-person" data-open="${escapeHtml(item.patient)}">
          <div class="hp-person-main">
            <div class="hp-avatar">${escapeHtml(initial(item.patient_name))}</div>
            <div>
              <h3>${escapeHtml(item.patient_name || "Patient")}</h3>
              <div class="hp-muted">${escapeHtml(item.relationship || "Family")} · ${escapeHtml(item.plan || "No plan yet")}</div>
              <div class="hp-amount">${money(item.monthly_amount)} / month</div>
            </div>
          </div>
          <div>
            <span class="hp-badge ${String(status).toLowerCase() === "active" ? "active" : ""}">${escapeHtml(status)}</span>
            ${canPay ? `<div class="hp-muted" style="margin-top:8px">Tap to view & pay</div>` : ""}
          </div>
        </button>
      `;
    }).join("")}</div>`;
  }

  function renderLogin(invite = false) {
    main.innerHTML = layout(`
      <div class="hp-login">
        ${splash()}
        <div class="hp-auth">
          ${authHero(invite)}
          ${authCard(`
            <h2>Sign in with your phone</h2>
            <p class="hp-muted">We'll send a one-time code by SMS.</p>
            <label class="hp-field">
              <span>Full name</span>
              <input name="full_name" value="${escapeHtml(state.fullName)}" placeholder="Your name" required autocomplete="name">
            </label>
            <label class="hp-field">
              <span>Mobile number</span>
              <input name="mobile" value="${escapeHtml(state.mobile)}" placeholder="+252 61 0000000" inputmode="tel" required autocomplete="tel">
            </label>
            <button class="hp-btn" ${state.busy ? "disabled" : ""}>${state.busy ? "Sending…" : "Send code"}</button>
          `)}
        </div>
      </div>
    `);
    main.querySelector(".hp-auth-card").addEventListener("submit", requestOtp);
  }

  function renderOtp() {
    main.innerHTML = layout(`
      <div class="hp-login">
        ${splash()}
        <div class="hp-auth">
          ${authHero(false)}
          ${authCard(`
            <h2>Enter your code</h2>
            <p class="hp-muted">We sent a 6-digit code to ${escapeHtml(state.mobile)}.</p>
            ${!state.fullName ? `
              <label class="hp-field">
                <span>Full name</span>
                <input name="full_name" required placeholder="Your name" autocomplete="name">
              </label>` : ""}
            <label class="hp-field">
              <span>Verification code</span>
              <input name="otp" inputmode="numeric" maxlength="6" placeholder="123456" required autocomplete="one-time-code">
            </label>
            <button class="hp-btn" ${state.busy ? "disabled" : ""}>${state.busy ? "Checking…" : "Continue"}</button>
            <p style="margin-top:14px;text-align:center"><button type="button" class="hp-link" id="hp-back">Use a different number</button></p>
          `)}
        </div>
      </div>
    `);
    main.querySelector(".hp-auth-card").addEventListener("submit", verifyOtp);
    main.querySelector("#hp-back").addEventListener("click", () => go("login"));
  }

  function renderHome() {
    const name = state.session?.user?.full_name || "there";
    main.innerHTML = layout(`
      <div class="hp-hero" style="margin-bottom:18px">
        <div class="hp-kicker">My Care</div>
        <h1>Welcome, ${escapeHtml(name.split(" ")[0])}</h1>
        <p>People you support appear here. Open anyone to see updates or pay for their care.</p>
      </div>
      <div class="hp-tabs">
        <button class="hp-chip ${state.tab === "home" ? "on" : ""}" data-tab="home">People</button>
        <button class="hp-chip ${state.tab === "connect" ? "on" : ""}" data-tab="connect">Redeem invite</button>
      </div>
      ${state.tab === "connect" ? `
        <form class="hp-card" id="hp-redeem" style="max-width:520px">
          <h2>Redeem invitation code</h2>
          <label class="hp-field"><span>Code</span><input name="code" value="${escapeHtml(state.inviteCode)}" placeholder="ABC123" required></label>
          <button class="hp-btn" ${state.busy ? "disabled" : ""}>Connect</button>
        </form>
      ` : peopleCards()}
    `);
    main.querySelectorAll("[data-tab]").forEach((btn) => {
      btn.addEventListener("click", () => {
        state.tab = btn.dataset.tab;
        render();
      });
    });
    main.querySelectorAll("[data-open]").forEach((btn) => {
      btn.addEventListener("click", () => {
        const item = (state.session.sponsorships || []).find((row) => row.patient === btn.dataset.open);
        if (item) openPerson(item);
      });
    });
    const redeemForm = main.querySelector("#hp-redeem");
    if (redeemForm) redeemForm.addEventListener("submit", redeem);
  }

  function renderPerson() {
    const dash = state.bundle?.dashboard || {};
    const link = state.bundle?.link || {};
    const readings = state.bundle?.readings || [];
    const appointments = state.bundle?.appointments || [];
    const orders = state.bundle?.orders || [];
    const pending = String(link.link_status || "").toLowerCase() === "pending";
    main.innerHTML = layout(`
      <p><button class="hp-link" id="hp-back-home">← Back to people</button></p>
      <div class="hp-hero" style="margin-bottom:16px">
        <div class="hp-kicker">${escapeHtml(link.relationship || "Family")}</div>
        <h1>${escapeHtml(dash.patient_name || link.patient_name)}</h1>
        <div class="hp-row"><span class="hp-muted">Status</span><strong>${escapeHtml(link.link_status || dash.status || "")}</strong></div>
        <div class="hp-row"><span class="hp-muted">Plan</span><strong>${escapeHtml(dash.plan || "—")}</strong></div>
        <div class="hp-row"><span class="hp-muted">Monthly</span><strong class="hp-amount">${money(dash.monthly_amount)}</strong></div>
        ${link.can_pay_for_care ? `<button class="hp-btn" id="hp-pay" style="margin-top:16px">Pay for care plan</button>` : ""}
        ${pending ? `<p class="hp-muted" style="margin-top:12px">Waiting for this person to accept your connection. You can still redeem access once they approve.</p>` : ""}
      </div>
      <div class="hp-grid two">
        <section class="hp-card">
          <h2>Latest readings</h2>
          ${readings.length ? `
            <table class="hp-table">
              <tr><th>Date</th><th>BP</th><th>Sugar</th><th>Risk</th></tr>
              ${readings.map((r) => `<tr>
                <td>${escapeHtml(r.reading_date || "")}</td>
                <td>${escapeHtml([r.bp_systolic, r.bp_diastolic].filter(Boolean).join("/") || "—")}</td>
                <td>${escapeHtml(r.blood_sugar ?? "—")}</td>
                <td>${escapeHtml(r.risk_level || "—")}</td>
              </tr>`).join("")}
            </table>` : `<p class="hp-muted">${pending ? "Available after the patient accepts." : "No readings yet, or you don’t have permission to view them."}</p>`}
        </section>
        <section class="hp-card">
          <h2>Appointments & medicines</h2>
          ${(appointments[0] || orders[0]) ? `
            ${appointments.slice(0, 4).map((a) => `<div class="hp-row"><span>${escapeHtml(a.appointment_date || "")} ${escapeHtml(a.appointment_time || "")}</span><strong>${escapeHtml(a.practitioner_name || a.status || "")}</strong></div>`).join("")}
            ${orders.slice(0, 4).map((o) => `<div class="hp-row"><span>${escapeHtml(o.name)}</span><strong>${escapeHtml(o.status || "")}</strong></div>`).join("")}
          ` : `<p class="hp-muted">No clinic updates to show yet.</p>`}
        </section>
      </div>
    `);
    main.querySelector("#hp-back-home").addEventListener("click", () => go("home"));
    const pay = main.querySelector("#hp-pay");
    if (pay) pay.addEventListener("click", () => startPay(state.selected));
  }

  function renderPay() {
    const item = state.selected || {};
    main.innerHTML = layout(`
      <p><button class="hp-link" id="hp-back-person">← Back</button></p>
      <form class="hp-card" id="hp-pay-form" style="max-width:560px">
        <h2>Pay for ${escapeHtml(item.patient_name || "care")}</h2>
        <p class="hp-muted">Choose a plan and pay with ZAAD, eDahab, or another available method.</p>
        <label class="hp-field"><span>Care plan</span>
          <select name="plan" required>
            ${state.plans.map((p) => `<option value="${escapeHtml(p.name)}">${escapeHtml(p.plan_name || p.name)} — ${money(p.monthly_fee)}</option>`).join("")}
          </select>
        </label>
        <div class="hp-pay-methods">
          ${state.methods.length ? state.methods.map((m, i) => `
            <label class="hp-method">
              <input type="radio" name="method" value="${escapeHtml(m.provider)}|${escapeHtml(m.method)}" ${i === 0 ? "checked" : ""}>
              <span>${escapeHtml(m.label || m.method)}</span>
            </label>`).join("") : `<div class="hp-error">Payment methods are not available right now.</div>`}
        </div>
        <label class="hp-field"><span>Mobile money number</span><input name="phone" placeholder="+252…" required></label>
        <button class="hp-btn" ${state.busy || !state.methods.length ? "disabled" : ""}>${state.busy ? "Starting…" : "Pay now"}</button>
      </form>
    `);
    main.querySelector("#hp-back-person").addEventListener("click", () => go("person"));
    main.querySelector("#hp-pay-form").addEventListener("submit", submitPay);
  }

  function renderWaiting() {
    main.innerHTML = layout(`
      <div class="hp-card hp-wait" style="max-width:480px;margin:40px auto">
        <div class="hp-pulse"></div>
        <h2>Approve the payment on your phone</h2>
        <p class="hp-muted">Enter your PIN in ZAAD / eDahab. We’ll confirm as soon as it goes through.</p>
        <p class="hp-amount">${money(state.pay?.amount)}</p>
      </div>
    `);
  }

  function renderPaid() {
    main.innerHTML = layout(`
      <div class="hp-card hp-wait" style="max-width:480px;margin:40px auto">
        <div class="hp-ok">Payment received</div>
        <h2>Sponsorship is active</h2>
        <p class="hp-muted">Thank you. This person’s care plan is now covered.</p>
        <button class="hp-btn" id="hp-done">Back to Family Care</button>
      </div>
    `);
    main.querySelector("#hp-done").addEventListener("click", () => go("home"));
  }

  function render() {
    const guest = ["boot", "welcome-invite", "login", "register", "otp"].includes(state.view);
    root.classList.toggle("hp-guest", guest);
    if (state.view === "welcome-invite" || state.view === "login" || state.view === "register") renderLogin(state.view !== "login");
    else if (state.view === "otp") renderOtp();
    else if (state.view === "home") renderHome();
    else if (state.view === "person") renderPerson();
    else if (state.view === "pay") renderPay();
    else if (state.view === "waiting") renderWaiting();
    else if (state.view === "paid") renderPaid();
  }

  boot();
})();
