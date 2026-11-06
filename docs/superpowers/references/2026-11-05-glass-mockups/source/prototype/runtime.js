// Borj prototype runtime: navigation between the approved boards + the motion spec
// (docs/superpowers/specs/2026-11-06-motion-and-today-customization-design.md).
// Boards are rendered unchanged inside shadow roots; this file only adds behaviour over time.
"use strict";

const EASE_OUT = "cubic-bezier(.23,1,.32,1)";      // critically damped feel
const SOFT = "cubic-bezier(.3,1.15,.5,1)";          // slight bounce, only after a gesture/momentum
const FIRST_DELAYS = [0, 50, 95, 135, 170, 200, 225, 240];
const $ = id => document.getElementById(id);

const state = { device: "phone", theme: "light", reduced: matchMedia("(prefers-reduced-motion: reduce)").matches, stack: [], seen: new Set(), timer: null };

const GROUPS = {
  phone: [
    ["امروز", ["Main", "PhoneEmptyToday", "PhoneDashboardCards", "PhoneOnboarding"]],
    ["کارها", ["PhoneTasks", "PhoneKanban", "PhoneCalendar", "PhoneDay", "PhoneTimer", "PhoneTaskDetail", "PhoneReminderEdit", "PhoneQuickEntry", "PhoneTemplates", "PhoneTemplateEdit"]],
    ["مالی", ["PhoneMoney", "PhoneAddTxn", "PhoneDebts", "PhoneReports", "PhoneBudgets", "PhoneAccounts"]],
    ["زندگی", ["PhoneHabits", "PhoneGoals"]],
    ["دیگر", ["PhoneSearch", "PhoneSettings", "PhoneNotifications", "PhoneBackup", "PhoneImportV1", "PhoneTrash"]],
  ],
  mac: [
    ["برنامه", ["MacToday", "MacTasks", "MacCalendar"]],
    ["پول", ["MacMoney", "MacFinance", "MacDebts", "MacReports"]],
    ["زندگی", ["MacHabits", "MacGoals"]],
    ["دیگر", ["MacSearch", "MacSettings"]],
  ],
};
const SHEETS = new Set(["PhoneTaskDetail", "PhoneReminderEdit", "PhoneQuickEntry", "PhoneTemplateEdit", "PhoneAddTxn"]);
const KIND_LABEL = { push: "ورود صفحه از چپ، صفحهٔ قبل کمی کنار می‌رود", back: "برگشت در همان مسیر، کوتاه‌تر", sheet: "برگه از همان دکمه بیرون می‌آید", close: "برگه به همان دکمه برمی‌گردد", tab: "محتوا بی‌درنگ؛ فقط نشانگر زبانه می‌لغزد", seg: "محو شدن کوتاه بین نماها", fade: "محو شدن", jump: "پرش از فهرست", section: "بخش بی‌درنگ؛ نشانگر کناری می‌لغزد", theme: "تغییر پوسته با محو شدن", demo: "" };

// ---------- routing tables ----------
const TABS = { "امروز": "Main", "کارها": "PhoneTasks", "مالی": "PhoneMoney", "عادت‌ها": "PhoneHabits" };
const MAC_SIDEBAR = [["امروز", "MacToday"], ["همهٔ کارها", "MacTasks"], ["تقویم", "MacCalendar"], ["تراکنش‌ها", "MacMoney"], ["بودجه", "MacFinance"], ["قسط و بدهی", "MacDebts"], ["عادت‌ها", "MacHabits"], ["هدف‌ها", "MacGoals"]];
const SEG = { "فهرست": "PhoneTasks", "کانبان": "PhoneKanban", "تقویم": "PhoneCalendar" };

// returns {to, kind} or {demo: fn} or null
function route(screen, label, el, root) {
  const has = s => label.includes(s), starts = s => label.startsWith(s);
  const inNav = !!el.closest("nav");
  if (state.device === "phone") {
    if (inNav && TABS[label]) return { to: TABS[label], kind: "tab" };
    if (label === "جست‌وجو") return { to: "PhoneSearch", kind: "fade" };
    if (starts("بازگشت") || label === "انصراف" || label === "تمام") return { kind: "back" };
    if (["بستن", "ذخیره", "ثبت", "ثبت تراکنش"].includes(label)) return { kind: SHEETS.has(screen) ? "close" : "back", bump: screen === "PhoneAddTxn" || screen === "PhoneQuickEntry" };
    switch (screen) {
      case "Main": case "PhoneEmptyToday":
        if (label === "تقویم") return { to: "PhoneCalendar", kind: "push" };
        if (label === "ورود سریع" || has("افزودن کار")) return { to: "PhoneQuickEntry", kind: "sheet" };
        if (has("افزودن حساب")) return { to: "PhoneAccounts", kind: "push" };
        if (has("شروع عادت")) return { to: "PhoneHabits", kind: "push" };
        break;
      case "PhoneTasks": case "PhoneKanban":
        if (SEG[label] && el.closest('[role="group"],[role="tablist"]')) return { to: SEG[label], kind: "seg" };
        if (label === "کار جدید") return { to: "PhoneQuickEntry", kind: "sheet" };
        if (label === "گزینه‌ها") return { to: "PhoneTemplates", kind: "push" };
        if (label === "تکمیل" || label === "حذف") return { demo: () => removeRow(el, label === "تکمیل" ? "کار انجام شد" : "کار به سطل رفت") };
        break;
      case "PhoneCalendar":
        if (SEG[label] && el.closest('[role="group"],[role="tablist"]')) return { to: SEG[label], kind: "seg" };
        if (label === "نمای روز" || / آبان$/.test(label)) return { to: "PhoneDay", kind: "push" };
        if (label === "افزودن") return { to: "PhoneQuickEntry", kind: "sheet" };
        if (label === "ماه قبل" || label === "ماه بعد") return { demo: () => slidePanel(el, label === "ماه بعد" ? 1 : -1) };
        if (/^[۰-۹]{2}:[۰-۹]{2}|همه‌روز/.test(label)) return { to: "PhoneTaskDetail", kind: "sheet" };
        break;
      case "PhoneDay":
        if (label === "روز قبل" || label === "روز بعد") return { demo: () => slidePanel(el, label === "روز بعد" ? 1 : -1) };
        if (label === "افزودن") return { to: "PhoneQuickEntry", kind: "sheet" };
        break;
      case "PhoneTaskDetail":
        if (has("یادآور") || has("تکرار")) return { to: "PhoneReminderEdit", kind: "sheet" };
        if (label === "توقف" || label === "شروع") return { to: "PhoneTimer", kind: "push" };
        break;
      case "PhoneQuickEntry":
        if (has("ویرایش جزئیات")) return { to: "PhoneTaskDetail", kind: "sheet" };
        break;
      case "PhoneTemplates":
        if (starts("ویرایش") || starts("کپی برای ویرایش") || label === "قالب جدید") return { to: "PhoneTemplateEdit", kind: "sheet" };
        if (starts("استفاده")) return { to: "PhoneQuickEntry", kind: "sheet" };
        break;
      case "PhoneTemplateEdit":
        if (has("پیش‌نمایش")) return { to: "PhoneQuickEntry", kind: "sheet" };
        break;
      case "PhoneTimer":
        if (label === "شروع" || label === "توقف") return { demo: () => toggleTimer(root) };
        break;
      case "PhoneMoney":
        if (starts("گزارش‌ها")) return { to: "PhoneReports", kind: "push" };
        if (starts("قسط و بدهی")) return { to: "PhoneDebts", kind: "push" };
        if (label === "تراکنش جدید") return { to: "PhoneAddTxn", kind: "sheet" };
        break;
      case "PhoneDebts":
        if (starts("ثبت")) return { demo: () => { bumpData(el.closest(".lg") || root, 0.9); toast("پرداخت ثبت شد", () => bumpData(el.closest(".lg") || root, 1 / 0.9)); } };
        break;
      case "PhoneReports": case "PhoneHabits":
        if (["ماه", "فصل", "سال", "هفته"].includes(label)) return { demo: () => morphCharts(root) };
        if (label === "هدف‌ها") return { to: "PhoneGoals", kind: "seg" };
        if (starts("ثبت ")) return { demo: () => { pop(el); bumpData(el.closest(".lg") || root, 1.15); } };
        if (label === "ماه قبل" || label === "ماه بعد") return { demo: () => slidePanel(el, label === "ماه بعد" ? 1 : -1) };
        break;
      case "PhoneGoals":
        if (label === "عادت‌ها") return { to: "PhoneHabits", kind: "seg" };
        break;
      case "PhoneBudgets":
        if (has("انتقال مانده")) return { demo: () => { bumpData(root, 0.95); toast("مانده به ماه بعد رفت"); } };
        break;
      case "PhoneAccounts":
        if (label === "انتقال" || label === "حساب جدید") return { to: "PhoneAddTxn", kind: "sheet" };
        break;
      case "PhoneSearch":
        if (el.closest("li") || /[۰-۹]/.test(label)) return { to: "PhoneTaskDetail", kind: "sheet" };
        break;
      case "PhoneSettings":
        if (label === "روشن") return { demo: () => setTheme("light") };
        if (label === "تیره") return { demo: () => setTheme("dark") };
        if (label === "خودکار") return { demo: () => setTheme(matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light") };
        if (has("انتقال از نسخهٔ ۱")) return { to: "PhoneImportV1", kind: "push" };
        if (has("اعلان") || has("یادآور")) return { to: "PhoneNotifications", kind: "push" };
        if (has("پشتیبان")) return { to: "PhoneBackup", kind: "push" };
        if (has("کارت")) return { to: "PhoneDashboardCards", kind: "push" };
        if (has("سطل") || has("حذف‌شده")) return { to: "PhoneTrash", kind: "push" };
        if (has("قالب")) return { to: "PhoneTemplates", kind: "push" };
        break;
      case "PhoneTrash":
        if (starts("بازیابی") || starts("حذف دائمی")) return { demo: () => removeRow(el, starts("بازیابی") ? "بازیابی شد" : "برای همیشه حذف شد") };
        break;
      case "PhoneImportV1":
        if (starts("وارد کردن")) return { demo: () => { toast("۱٬۰۲۶ مورد وارد شد"); goBack(); } };
        break;
      case "PhoneOnboarding":
        if (label === "شروع") return { to: "Main", kind: "fade", reset: true };
        if (has("انتقال از نسخهٔ ۱")) return { to: "PhoneImportV1", kind: "push" };
        break;
    }
  } else {
    for (const [l, to] of MAC_SIDEBAR) if (label.startsWith(l) && el.closest("nav, aside")) return { to, kind: "section" };
    if (label === "فهرست" || label === "کانبان") return { to: "MacTasks", kind: "seg" };
    if (label === "تقویم") return { to: "MacCalendar", kind: "seg" };
    if (label === "جزئیات") return { to: "MacTasks", kind: "section", inspector: true };
    if (label === "بستن بازرس" || label === "بستن") return { demo: () => toggleInspector(el, false) };
    if (["ماه", "فصل", "سال", "هفته"].includes(label)) return { demo: () => morphCharts(root) };
    if (/قبل$|بعد$/.test(label)) return { demo: () => slidePanel(el, /بعد$/.test(label) ? 1 : -1) };
    if (has("تکمیل کار")) return { demo: () => pop(el) };
    if (screen === "MacTasks" && el.closest("li")) return { demo: () => toggleInspector(el, true) };
  }
  // a row-level fallback for settings-like lists (labels sit in plain text, not buttons)
  return null;
}

// ---------- mounting ----------
function mount(name, theme = state.theme) {
  const d = DOCS[name];
  const host = document.createElement("div");
  host.className = "layer";
  host.dataset.screen = name;
  const sr = host.attachShadow({ mode: "open" });
  sr.innerHTML = `<style>${d.css}</style><style>:host{display:block} a{-webkit-tap-highlight-color:transparent}</style>${theme === "dark" ? d.d : d.l}`;
  sr.addEventListener("click", e => onClick(e, name, sr), true);
  sr.addEventListener("pointerdown", onPress, true);
  sr.addEventListener("change", e => { if (e.target.matches(".chk, input[type=checkbox]")) onCheck(e.target, name); }, true);
  return host;
}

// Boards are fixed-height pictures; in the prototype the content scrolls while chrome stays pinned.
// Direct children positioned absolutely (tab bar, background light, decorative underlay) become fixed,
// which inside the transformed device means "pinned to the screen", exactly like the app.
function makeScrollable(host, name) {
  const d = DOCS[name], sr = host.shadowRoot;
  const root = [...sr.children].find(e => e.tagName === "DIV");
  if (!root) return;
  host.style.overflowY = "auto";
  host.style.overscrollBehavior = "contain";
  if (SHEETS.has(name)) { const dlg = findDialog(sr); if (dlg) { dlg.style.overflowY = "auto"; dlg.style.overscrollBehavior = "contain"; } return; }
  if (d.k !== "phone") return;
  [...root.children].forEach(c => { if (getComputedStyle(c).position === "absolute") c.style.position = "fixed"; });
  root.style.height = "auto";
  root.style.minHeight = d.h + "px";
  root.style.paddingBottom = "120px";
  root.style.boxSizing = "border-box";
}

function sizeDevice() {
  const first = Object.keys(DOCS).find(n => DOCS[n].k === state.device);
  const top = state.stack.length ? DOCS[state.stack[state.stack.length - 1].name] : DOCS[first];
  const dev = $("device"), wrap = $("stagewrap");
  const W = top.w, H = top.h;
  dev.style.width = W + "px"; dev.style.height = H + "px";
  const s = Math.min((wrap.clientWidth - 48) / W, (wrap.clientHeight - 48) / H, 1);
  dev.style.transform = `scale(${s})`;
  $("sizer").style.width = W * s + "px"; $("sizer").style.height = H * s + "px";
  dev.className = "device " + state.device;
  state.scale = s;
}
addEventListener("resize", sizeDevice);

const topLayer = () => state.stack[state.stack.length - 1];

function stageRect(el) { // element rect in unscaled device coordinates
  const d = $("device").getBoundingClientRect(), r = el.getBoundingClientRect(), s = state.scale;
  return { x: (r.left - d.left) / s, y: (r.top - d.top) / s, w: r.width / s, h: r.height / s };
}

// ---------- navigation ----------
function go(name, kind, opts = {}) {
  const prev = topLayer();
  const host = mount(name);
  const entry = { name, kind, host, trig: opts.trig || null };
  if (opts.reset) { state.stack.forEach(l => l.host.remove()); state.stack = []; }
  $("device").appendChild(host);
  makeScrollable(host, name);
  state.stack.push(entry);
  if (state.stack.length > 8) { const old = state.stack.splice(0, 1)[0]; old.host.remove(); }
  sizeDevice();
  const R = state.reduced;
  const fade = (el, ms) => el.animate([{ opacity: 0 }, { opacity: 1 }], { duration: ms, easing: EASE_OUT });
  if (!prev || kind === "jump" || kind === "fade" || kind === "seg" || R) {
    if (prev) fade(host, kind === "seg" ? 150 : 200).onfinish = () => hideUnder(entry);
    else hideUnder(entry);
  } else if (kind === "push") {
    host.animate([{ transform: "translateX(-100%)" }, { transform: "none" }], { duration: 380, easing: EASE_OUT });
    prev.host.animate([{ transform: "none", filter: "brightness(1)" }, { transform: "translateX(30%)", filter: "brightness(.85)" }], { duration: 380, easing: EASE_OUT }).onfinish = () => hideUnder(entry);
  } else if (kind === "sheet") {
    prev.host.style.visibility = "visible";
    fade(host, 200);
    const dlg = findDialog(host.shadowRoot);
    if (dlg && opts.trig) {
      const r = stageRect(dlg), t = opts.trig;
      const dx = (t.x + t.w / 2) - (r.x + r.w / 2), dy = (t.y + t.h / 2) - (r.y + r.h / 2), sc = Math.max(t.w / r.w, 0.25);
      dlg.animate([{ transform: `translate(${dx}px, ${dy}px) scale(${sc})`, opacity: 0.4 }, { transform: "none", opacity: 1 }], { duration: 380, easing: SOFT });
    }
  } else if (kind === "tab" || kind === "section") {
    hideUnder(entry);
    slideLens(prev.host.shadowRoot, host.shadowRoot);
  }
  // siblings replace each other: tabs/sections reset the history, a view switch replaces the top
  if (prev && (kind === "tab" || kind === "section" || kind === "seg")) {
    const drop = kind === "seg" ? [prev] : state.stack.slice(0, -1);
    const finish = () => { drop.forEach(l => l.host.remove()); state.stack = state.stack.filter(l => !drop.includes(l)); renderIndex(); };
    setTimeout(finish, kind === "seg" ? 200 : 320);
  }
  if (opts.inspector) setTimeout(() => toggleInspector(host.shadowRoot.querySelector('[aria-label="بستن بازرس"]'), true), 0);
  revealIfFirst(host.shadowRoot, name);
  renderIndex();
  caption(name, kind);
}

function hideUnder(entry) { // only the top layer (and a sheet's backdrop screen) needs painting
  state.stack.forEach((l, i) => {
    const isTop = i === state.stack.length - 1;
    const isUnderSheet = i === state.stack.length - 2 && topLayer().kind === "sheet";
    l.host.style.visibility = isTop || isUnderSheet ? "visible" : "hidden";
    if (!isTop) l.host.getAnimations().forEach(a => a.cancel());
  });
}

function goBack(opts = {}) {
  if (state.stack.length < 2) return;
  const cur = state.stack.pop(), prev = topLayer();
  cur.host.style.pointerEvents = "none"; // a leaving layer never eats taps
  prev.host.style.visibility = "visible";
  const done = () => { cur.host.remove(); hideUnder(prev); if (opts.bump) bumpData(prev.host.shadowRoot, 0.96); };
  const R = state.reduced;
  if (R || cur.kind === "fade" || cur.kind === "seg" || cur.kind === "jump" || cur.kind === "tab" || cur.kind === "section") {
    cur.host.animate([{ opacity: 1 }, { opacity: 0 }], { duration: 160, easing: EASE_OUT }).onfinish = done;
  } else if (cur.kind === "push") {
    cur.host.animate([{ transform: "none" }, { transform: "translateX(-100%)" }], { duration: 270, easing: EASE_OUT, fill: "forwards" }).onfinish = done;
    prev.host.animate([{ transform: "translateX(30%)", filter: "brightness(.85)" }, { transform: "none", filter: "brightness(1)" }], { duration: 270, easing: EASE_OUT });
  } else if (cur.kind === "sheet") {
    const dlg = findDialog(cur.host.shadowRoot);
    cur.host.animate([{ opacity: 1 }, { opacity: 0 }], { duration: 240, easing: EASE_OUT, fill: "forwards" }).onfinish = done;
    if (dlg && cur.trig) {
      const r = stageRect(dlg), t = cur.trig;
      const dx = (t.x + t.w / 2) - (r.x + r.w / 2), dy = (t.y + t.h / 2) - (r.y + r.h / 2), sc = Math.max(t.w / r.w, 0.25);
      dlg.animate([{ transform: "none" }, { transform: `translate(${dx}px, ${dy}px) scale(${sc})` }], { duration: 240, easing: EASE_OUT, fill: "forwards" });
    }
  } else done();
  renderIndex();
  caption(prev.name, cur.kind === "sheet" ? "close" : "back");
}

function findDialog(sr) {
  const c = [...sr.querySelectorAll('[role="dialog"], .lg.lg-l[aria-label]')].filter(e => getComputedStyle(e).position === "absolute");
  return c.sort((a, b) => b.offsetWidth * b.offsetHeight - a.offsetWidth * a.offsetHeight)[0] || null;
}

// glass selection lens slides from the old tab/sidebar item to the new one; content itself does not move
function slideLens(oldSr, newSr) {
  if (state.reduced) return;
  const sel = sr => sr.querySelector("nav .lg-in, aside .lg-in, nav [aria-current], aside [aria-current]");
  const a = sel(oldSr), b = sel(newSr);
  if (!a || !b) return;
  const ra = stageRect(a), rb = stageRect(b);
  if (Math.abs(ra.x - rb.x) + Math.abs(ra.y - rb.y) < 2) return;
  const pill = document.createElement("div");
  pill.className = b.className;
  Object.assign(pill.style, { position: "absolute", left: rb.x + "px", top: rb.y + "px", width: rb.w + "px", height: rb.h + "px", borderRadius: getComputedStyle(b).borderRadius, pointerEvents: "none", zIndex: 50 });
  const host = newSr.host; const holder = document.createElement("div");
  holder.style.cssText = "position:absolute;inset:0;pointer-events:none";
  newSr.appendChild(holder); holder.appendChild(pill);
  const dx = ra.x - rb.x, dy = ra.y - rb.y;
  const keep = b.style.background, keepS = b.style.boxShadow;
  b.style.background = "transparent"; b.style.boxShadow = "none";
  const horiz = Math.abs(dx) > Math.abs(dy);
  pill.animate([
    { transform: `translate(${dx}px, ${dy}px)` },
    { transform: `translate(${dx * 0.45}px, ${dy * 0.45}px) ${horiz ? "scaleX(1.12)" : "scaleY(1.12)"}`, offset: 0.5 },
    { transform: "none" },
  ], { duration: 300, easing: EASE_OUT }).onfinish = () => { holder.remove(); b.style.background = keep; b.style.boxShadow = keepS; };
  void host;
}

// ---------- in-screen motion ----------
function revealIfFirst(sr, name) {
  const key = state.device + ":" + name;
  if (state.seen.has(key)) return;
  state.seen.add(key);
  const R = state.reduced;
  const rootR = sr.host.getBoundingClientRect();
  // cards/sections (not chrome): glass panels taller than 48px, outermost only, not pinned to the bottom bar
  const panels = [...sr.querySelectorAll(".lg")].filter(e => {
    const r = e.getBoundingClientRect();
    if (r.height < 48 || r.width < 120) return false;
    if (e.closest("nav") || e.matches("nav")) return false;
    if (e.parentElement && e.parentElement.closest(".lg")) return false;
    const pos = getComputedStyle(e).position;
    if (pos === "fixed" || (pos === "absolute" && rootR.bottom - r.bottom < 140)) return false;
    if (r.top > rootR.bottom + 400) return false; // far below the fold: no entrance needed
    return true;
  }).sort((a, b) => a.getBoundingClientRect().top - b.getBoundingClientRect().top || b.getBoundingClientRect().left - a.getBoundingClientRect().left).slice(0, 8);
  panels.forEach((p, i) => {
    p.animate(R ? [{ opacity: 0 }, { opacity: 1 }] : [{ opacity: 0, transform: "translateY(8px)" }, { opacity: 1, transform: "none" }],
      { duration: R ? 200 : 300, delay: R ? 0 : FIRST_DELAYS[i], easing: EASE_OUT, fill: "backwards" });
  });
  if (R) return;
  // data: bars grow, tracks fill, rings sweep, big numbers roll (once per session per screen)
  const bars = [...sr.querySelectorAll("[style*='height']")].filter(e => {
    const st = e.getAttribute("style") || "";
    if (!/background/.test(st) || e.children.length > 1) return false;
    const pr = e.parentElement && getComputedStyle(e.parentElement);
    return pr && pr.display.includes("flex") && pr.alignItems === "flex-end" && e.getBoundingClientRect().height > 6;
  });
  bars.sort((a, b) => b.getBoundingClientRect().height - a.getBoundingClientRect().height)
    .forEach((e, i) => e.animate([{ transform: "scaleY(0)", transformOrigin: "50% 100%" }, { transform: "none", transformOrigin: "50% 100%" }], { duration: 450, delay: 120 + Math.min(i, 8) * 30, easing: EASE_OUT, fill: "backwards" }));
  tracks(sr).forEach(e => e.animate([{ transform: "scaleX(0)", transformOrigin: originX(e) }, { transform: "none", transformOrigin: originX(e) }], { duration: 450, delay: 150, easing: EASE_OUT, fill: "backwards" }));
  sr.querySelectorAll("circle[stroke-dasharray]").forEach(c => {
    const len = parseFloat(c.getAttribute("stroke-dasharray")) || 0, off = parseFloat(c.getAttribute("stroke-dashoffset") || getComputedStyle(c).strokeDashoffset) || 0;
    if (len) c.animate([{ strokeDashoffset: len }, { strokeDashoffset: off }], { duration: 500, delay: 150, easing: EASE_OUT, fill: "backwards" });
  });
  bigNumbers(sr).slice(0, 4).forEach(e => roll(e, 0, 1, 450, 120));
}

function tracks(sr) {
  return [...sr.querySelectorAll("[style*='width']")].filter(e => {
    const st = e.getAttribute("style") || "";
    if (!/width:\s*\d+(\.\d+)?%/.test(st) || !/background/.test(st)) return false;
    const r = e.getBoundingClientRect();
    return r.height > 2 && r.height <= 16 && e.children.length === 0;
  });
}
const originX = e => (getComputedStyle(e.parentElement).direction === "rtl" ? "100% 50%" : "0% 50%");

const FA = "۰۱۲۳۴۵۶۷۸۹";
const toLatin = s => s.replace(/[۰-۹]/g, d => FA.indexOf(d));
const toFa = s => String(s).replace(/\d/g, d => FA[d]);
function bigNumbers(sr) {
  return [...sr.querySelectorAll("*")].filter(e => {
    if (e.children.length || !/[۰-۹]/.test(e.textContent) || e.textContent.length > 24) return false;
    const cs = getComputedStyle(e);
    return parseFloat(cs.fontSize) >= 20 && parseInt(cs.fontWeight) >= 700 && !/:/.test(e.textContent);
  });
}
// animate the digits inside an element from from*value to to*value, keeping all other text
function roll(e, fromK, toK, ms, delay = 0) {
  if (state.reduced) return;
  const tpl = e.dataset.tpl || e.textContent;
  e.dataset.tpl = tpl;
  const m = tpl.match(/[۰-۹][۰-۹٬,]*/);
  if (!m) return;
  const val = parseInt(toLatin(m[0]).replace(/[٬,]/g, ""), 10);
  if (!isFinite(val)) return;
  const sep = m[0].includes("٬") ? "٬" : m[0].includes(",") ? "," : "";
  const fmt = n => { let s = String(Math.round(n)); if (sep) s = s.replace(/\B(?=(\d{3})+(?!\d))/g, sep); return tpl.replace(m[0], toFa(s)); };
  const t0 = performance.now() + delay;
  const step = t => {
    const p = Math.max(0, Math.min(1, (t - t0) / ms)), k = fromK + (toK - fromK) * (1 - Math.pow(1 - p, 3));
    e.textContent = fmt(val * k);
    if (p < 1) requestAnimationFrame(step); else { e.textContent = fmt(val * toK); }
  };
  requestAnimationFrame(step);
}

// a data change: numbers roll to their new value, tracks move from the old value (not from zero)
function bumpData(scope, k) {
  const sr = scope.querySelectorAll ? scope : scope.shadowRoot;
  bigNumbers(sr).slice(0, 3).forEach(e => {
    const cur = e.dataset.k ? parseFloat(e.dataset.k) : 1;
    const next = cur * k; e.dataset.k = next;
    if (state.reduced) { roll(e, next, next, 1); return; }
    roll(e, cur, next, 350);
  });
  tracks(sr).slice(0, 4).forEach(e => {
    const cur = e.dataset.s ? parseFloat(e.dataset.s) : 1, next = Math.max(0.05, Math.min(1.6, cur * (k > 1 ? 1.12 : 0.9)));
    e.dataset.s = next;
    e.animate([{ transform: `scaleX(${cur})`, transformOrigin: originX(e) }, { transform: `scaleX(${next})`, transformOrigin: originX(e) }], { duration: state.reduced ? 0 : 350, easing: EASE_OUT, fill: "forwards" });
  });
}

// period switch: bars morph from current to new values; axes do not move
function morphCharts(sr) {
  const bars = [...sr.querySelectorAll("[style*='height']")].filter(e => /background/.test(e.getAttribute("style") || "") && getComputedStyle(e.parentElement).alignItems === "flex-end");
  bars.forEach(e => {
    const cur = e.dataset.s ? parseFloat(e.dataset.s) : 1, next = 0.45 + Math.random() * 0.75;
    e.dataset.s = next;
    e.animate([{ transform: `scaleY(${cur})`, transformOrigin: "50% 100%" }, { transform: `scaleY(${next})`, transformOrigin: "50% 100%" }], { duration: state.reduced ? 0 : 350, easing: EASE_OUT, fill: "forwards" });
  });
  bumpData(sr, 0.8 + Math.random() * 0.4);
}

function slidePanel(el, dir) {
  const host = el.getRootNode();
  const panel = el.closest(".lg") && el.closest(".lg").parentElement ? [...host.querySelectorAll(".lg")].sort((a, b) => b.offsetWidth * b.offsetHeight - a.offsetWidth * a.offsetHeight)[0] : null;
  if (!panel) return;
  if (state.reduced) { panel.animate([{ opacity: 0.4 }, { opacity: 1 }], { duration: 200 }); return; }
  // RTL: "next" moves content toward the left
  panel.animate([{ transform: `translateX(${dir * -24}px)`, opacity: 0.2 }, { transform: "none", opacity: 1 }], { duration: 300, easing: EASE_OUT });
}

function pop(el) {
  if (state.reduced) return;
  el.animate([{ transform: "scale(.85)" }, { transform: "scale(1.06)", offset: 0.6 }, { transform: "none" }], { duration: 380, easing: SOFT });
}

function onCheck(chk, name) {
  pop(chk);
  if (!chk.checked) return;
  const row = chk.closest("li") || chk.closest("label") || chk.parentElement;
  if ((name === "PhoneTasks" || name === "Main") && row) setTimeout(() => removeRow(row, "کار انجام شد", () => { chk.checked = false; }), 600);
}

// a row leaves layout at once (siblings close the gap while it fades); undo restores it
function removeRow(el, msg, onUndo) {
  const row = el.closest("li") || el.closest("[role='listitem']") || el.closest(".lg-in") || el;
  const h = row.offsetHeight;
  const R = state.reduced;
  const anim = row.animate(R ? [{ opacity: 1 }, { opacity: 0 }] : [{ height: h + "px", opacity: 1, transform: "none" }, { height: "0px", opacity: 0, transform: "scale(.96)", marginTop: "0px", marginBottom: "0px", paddingTop: "0px", paddingBottom: "0px" }],
    { duration: R ? 200 : 260, easing: EASE_OUT, fill: "forwards" });
  row.style.overflow = "hidden";
  toast(msg, () => { anim.cancel(); row.style.overflow = ""; if (onUndo) onUndo(); if (!R) row.animate([{ opacity: 0, transform: "scale(.96)" }, { opacity: 1, transform: "none" }], { duration: 250, easing: EASE_OUT }); });
}

function toggleInspector(btn, show) {
  if (!btn) return;
  const sr = btn.getRootNode();
  const insp = sr.querySelector('[aria-label="بستن بازرس"]')?.closest(".lg") || btn.closest(".lg");
  if (!insp) return;
  const R = state.reduced;
  if (show) {
    insp.style.visibility = "visible";
    insp.animate(R ? [{ opacity: 0 }, { opacity: 1 }] : [{ transform: "translateX(-48px)", opacity: 0 }, { transform: "none", opacity: 1 }], { duration: R ? 200 : 380, easing: EASE_OUT });
  } else {
    insp.animate(R ? [{ opacity: 1 }, { opacity: 0 }] : [{ transform: "none", opacity: 1 }, { transform: "translateX(-48px)", opacity: 0 }], { duration: R ? 200 : 260, easing: EASE_OUT }).onfinish = () => { insp.style.visibility = "hidden"; };
  }
  caption(topLayer().name, "demo", show ? "بازرس از لبهٔ چپ می‌آید؛ محتوایش از قبل سر جایش است" : "بازرس به همان لبه برمی‌گردد");
}

function toggleTimer(sr) {
  if (state.timer) { clearInterval(state.timer); state.timer = null; caption("PhoneTimer", "demo", "زمان‌سنج متوقف شد"); return; }
  const el = [...sr.querySelectorAll("*")].filter(e => !e.children.length && /[۰-۹]{1,2}:[۰-۹]{2}/.test(e.textContent)).sort((a, b) => parseFloat(getComputedStyle(b).fontSize) - parseFloat(getComputedStyle(a).fontSize))[0];
  if (!el) return;
  state.timer = setInterval(() => {
    if (!el.isConnected) { clearInterval(state.timer); state.timer = null; return; }
    const parts = toLatin(el.textContent).match(/(\d+):(\d+)(?::(\d+))?/);
    if (!parts) return;
    let nums = parts.slice(1).filter(x => x !== undefined).map(Number);
    nums[nums.length - 1]++;
    for (let i = nums.length - 1; i > 0; i--) if (nums[i] >= 60) { nums[i] = 0; nums[i - 1]++; }
    el.textContent = el.textContent.replace(/[۰-۹]{1,2}:[۰-۹]{2}(:[۰-۹]{2})?/, toFa(nums.map((n, i) => (i ? String(n).padStart(2, "0") : n)).join(":")));
  }, 1000);
  caption("PhoneTimer", "demo", "زمان‌سنج روشن: فقط رقم‌ها عوض می‌شوند، بدون تپش و حلقهٔ حرکتی");
}

// ---------- input ----------
function onPress(e) {
  const el = e.target.closest("button, a, [role='button']");
  if (!el || state.reduced) return;
  const a = el.animate([{ transform: "none" }, { transform: "scale(.97)" }], { duration: 120, easing: EASE_OUT, fill: "forwards" });
  const up = () => { a.cancel(); el.animate([{ transform: "scale(.97)" }, { transform: "none" }], { duration: 120, easing: EASE_OUT }); removeEventListener("pointerup", up, true); removeEventListener("pointercancel", up, true); };
  addEventListener("pointerup", up, true); addEventListener("pointercancel", up, true);
}

function labelOf(el) {
  const al = el.getAttribute("aria-label");
  const txt = (el.textContent || "").replace(/\s+/g, " ").trim();
  return (al || txt).trim();
}

function onClick(e, name, sr) {
  const a = e.target.closest("a"); if (a) e.preventDefault();
  if (topLayer()?.name !== name) return;
  if (SHEETS.has(name)) { const dlg = findDialog(sr); if (dlg && !dlg.contains(e.target)) { goBack(); return; } } // tap outside a sheet closes it
  let el = e.target.closest("button, a, [role='button'], li, label");
  if (!el) {
    // plain rows (settings lists): look upward for a short labelled block
    let n = e.target; for (let i = 0; i < 4 && n && n !== sr; i++, n = n.parentElement) { if (n.textContent && n.textContent.trim().length < 70) el = n; }
  }
  if (!el) return;
  if (el.matches("label") && e.target.matches("input")) return;
  const label = labelOf(el);
  const r = route(name, label, el, sr);
  if (!r) return;
  if (r.demo) { r.demo(); return; }
  if (r.kind === "back" || r.kind === "close") { goBack({ bump: r.bump }); return; }
  if (r.to === name) return;
  go(r.to, r.kind, { trig: stageRect(el), reset: r.reset, inspector: r.inspector });
}

addEventListener("keydown", e => {
  if (e.key === "Escape") goBack();
  if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === "k" && state.device === "mac") { e.preventDefault(); go("MacSearch", "jump"); caption("MacSearch", "demo", "Ctrl+K بدون حرکت: کاری که روزی صدها بار تکرار می‌شود نباید منتظرت بگذارد"); }
});

// ---------- chrome ----------
let toastTimer;
const toastEl = document.createElement("div");
toastEl.className = "toast";
function toast(msg, undo) {
  toastEl.innerHTML = "";
  const s = document.createElement("span"); s.textContent = msg; toastEl.appendChild(s);
  if (undo) { const b = document.createElement("button"); b.textContent = "برگرداندن"; b.onclick = () => { toastEl.classList.remove("show"); undo(); }; toastEl.appendChild(b); }
  $("device").appendChild(toastEl);
  requestAnimationFrame(() => toastEl.classList.add("show"));
  clearTimeout(toastTimer); toastTimer = setTimeout(() => toastEl.classList.remove("show"), 5000);
}

function caption(name, kind, text) {
  const k = text || KIND_LABEL[kind] || "";
  $("caption").innerHTML = `<b>${DOCS[name].n}</b>${k ? " · " + k : ""}`;
}

function renderIndex() {
  const cur = topLayer()?.name;
  const nav = $("index");
  nav.innerHTML = GROUPS[state.device].map(([g, list]) => `<h2>${g}</h2>` + list.map(n => `<button data-go="${n}" aria-current="${n === cur}">${DOCS[n].n}${SHEETS.has(n) ? "<span>برگه</span>" : ""}</button>`).join("")).join("") +
    `<p class="note">روی دکمه‌ها و ردیف‌های خود صفحه بزنید تا جابه‌جایی‌ها و حرکت‌ها را ببینید. هر صفحه بار اول با ورود داده‌ها باز می‌شود و دفعه‌های بعد بی‌درنگ. Esc یعنی بازگشت.</p>
     <p class="note">چیدمان و تغییر اندازهٔ کارت‌های امروز: <a href="https://claude.ai/artifact/9EMLdeoU2PEjJfur64Nv1W" target="_blank" rel="noopener">نمونهٔ جدا</a></p>`;
}
$("index").addEventListener("click", e => {
  const b = e.target.closest("[data-go]"); if (!b) return;
  const n = b.dataset.go;
  if (n === topLayer()?.name) return;
  go(n, SHEETS.has(n) ? "fade" : "jump");
});

function setDevice(d) {
  state.device = d;
  $("devPhone").setAttribute("aria-pressed", d === "phone"); $("devMac").setAttribute("aria-pressed", d === "mac");
  state.stack.forEach(l => l.host.remove()); state.stack = [];
  go(d === "phone" ? "Main" : "MacToday", "jump");
}
function setTheme(t) {
  if (t === state.theme) return;
  state.theme = t;
  $("thLight").setAttribute("aria-pressed", t === "light"); $("thDark").setAttribute("aria-pressed", t === "dark");
  document.documentElement.setAttribute("data-theme", t);
  // re-render the visible layers in the new theme and cross-fade (300ms), no flashing
  state.stack.forEach((l, i) => {
    const fresh = mount(l.name, t);
    fresh.style.visibility = l.host.style.visibility;
    const top = l.host.scrollTop;
    l.host.replaceWith(fresh);
    makeScrollable(fresh, l.name);
    fresh.scrollTop = top;
    const old = l.host; l.host = fresh;
    if (i === state.stack.length - 1 && !state.reduced) {
      $("device").appendChild(old); old.style.zIndex = 5;
      old.animate([{ opacity: 1 }, { opacity: 0 }], { duration: 300, easing: "ease-out" }).onfinish = () => old.remove();
    }
  });
  caption(topLayer().name, "theme");
}
function setReduced(r) {
  state.reduced = r;
  $("mvFull").setAttribute("aria-pressed", !r); $("mvReduced").setAttribute("aria-pressed", r);
  caption(topLayer().name, "demo", r ? "کاهش حرکت: فقط محو شدن کوتاه، بدون جابه‌جایی و فنر" : "حرکت کامل");
}
$("devPhone").onclick = () => setDevice("phone");
$("devMac").onclick = () => setDevice("mac");
$("thLight").onclick = () => setTheme("light");
$("thDark").onclick = () => setTheme("dark");
$("mvFull").onclick = () => setReduced(false);
$("mvReduced").onclick = () => setReduced(true);
$("backBtn").onclick = () => goBack();
if (state.reduced) setReduced(true);
setDevice("phone");
