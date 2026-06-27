/* Aziza Food — Admin SPA (vanilla JS, no build step).
 * Talks to the FastAPI backend. Admin endpoints are ungated. */
(function () {
  "use strict";

  /* ---------------- API base ---------------- */
  // Allow ?api=<url> to override + persist for local testing against live API.
  const params = new URLSearchParams(location.search);
  const apiOverride = params.get("api");
  if (apiOverride) {
    try { localStorage.setItem("aziza_api", apiOverride); } catch (e) {}
  }
  const API_BASE = (window.API_BASE || localStorage.getItem("aziza_api") || "/api/v1").replace(/\/+$/, "");

  // Origin used to resolve relative /static/... image URLs.
  // If API_BASE is absolute, use its origin; else use the page origin.
  let API_ORIGIN = location.origin;
  try {
    if (/^https?:\/\//i.test(API_BASE)) API_ORIGIN = new URL(API_BASE).origin;
  } catch (e) {}

  function mediaUrl(u) {
    if (!u) return "";
    if (/^https?:\/\//i.test(u) || u.startsWith("data:") || u.startsWith("blob:")) return u;
    if (u.startsWith("/")) return API_ORIGIN + u;
    return u;
  }

  /* ---------------- HTTP ---------------- */
  async function api(path, opts) {
    opts = opts || {};
    const init = { method: opts.method || "GET", headers: {} };
    if (opts.body !== undefined) {
      init.headers["Content-Type"] = "application/json";
      init.body = JSON.stringify(opts.body);
    }
    if (opts.form) { init.body = opts.form; } // FormData; let browser set boundary
    let res;
    try {
      res = await fetch(API_BASE + path, init);
    } catch (e) {
      throw new Error("Нет связи с сервером");
    }
    if (res.status === 204) return null;
    let data = null;
    const ct = res.headers.get("content-type") || "";
    if (ct.indexOf("application/json") !== -1) {
      try { data = await res.json(); } catch (e) {}
    }
    if (!res.ok) {
      let msg = (data && (data.detail || data.message)) || ("Ошибка " + res.status);
      if (Array.isArray(msg)) msg = msg.map(function (m) { return m.msg || JSON.stringify(m); }).join("; ");
      throw new Error(typeof msg === "string" ? msg : "Ошибка запроса");
    }
    return data;
  }

  /* ---------------- Helpers ---------------- */
  function escapeHtml(s) {
    if (s === null || s === undefined) return "";
    return String(s)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#39;");
  }
  function tg(money) { // minor -> "4 800 ₸"
    const v = Math.round((money || 0) / 100);
    return v.toLocaleString("ru-RU") + " ₸";
  }
  function el(html) {
    const t = document.createElement("template");
    t.innerHTML = html.trim();
    return t.content.firstChild;
  }
  function name_ru(i18n) {
    if (!i18n) return "";
    return i18n.ru || i18n.kk || i18n.en || (Object.values(i18n)[0] || "");
  }
  function fmtTime(iso) {
    if (!iso) return "";
    const d = new Date(iso);
    if (isNaN(d)) return "";
    const now = new Date();
    const sameDay = d.toDateString() === now.toDateString();
    const hm = d.toLocaleTimeString("ru-RU", { hour: "2-digit", minute: "2-digit" });
    if (sameDay) return hm;
    return d.toLocaleDateString("ru-RU", { day: "2-digit", month: "2-digit" }) + " " + hm;
  }
  function isToday(iso) {
    if (!iso) return false;
    const d = new Date(iso);
    return !isNaN(d) && d.toDateString() === new Date().toDateString();
  }
  function initials(name) {
    const s = (name || "?").trim();
    return s ? s[0].toUpperCase() : "?";
  }

  /* ---------------- Toast ---------------- */
  const toastRoot = document.getElementById("toast-root");
  function toast(msg, kind) {
    const t = el('<div class="toast ' + (kind || "") + '"></div>');
    t.textContent = msg;
    toastRoot.appendChild(t);
    setTimeout(function () {
      t.style.transition = "opacity .25s, transform .25s";
      t.style.opacity = "0";
      t.style.transform = "translateY(8px)";
      setTimeout(function () { t.remove(); }, 260);
    }, kind === "err" ? 4200 : 2400);
  }
  function ok(m) { toast(m, "ok"); }
  function err(e) { toast((e && e.message) || String(e), "err"); }

  /* ---------------- Domain constants ---------------- */
  const STATUS_ORDER = ["pending", "confirmed", "preparing", "courier_assigned", "in_transit", "delivered", "cancelled"];
  const STATUS_RU = {
    pending: "Новый",
    confirmed: "Подтверждён",
    preparing: "Готовится",
    courier_assigned: "Назначен курьер",
    in_transit: "В пути",
    delivered: "Доставлен",
    cancelled: "Отменён",
  };
  const ACTIVE_STATUSES = ["pending", "confirmed", "preparing", "courier_assigned", "in_transit"];
  const PAY_RU = {
    cash: "Наличные",
    card_online: "Карта онлайн",
    kaspi: "Kaspi",
    halyk: "Halyk",
    apple_pay: "Apple Pay",
    google_pay: "Google Pay",
  };
  function statusBadge(s) {
    return '<span class="badge badge--' + escapeHtml(s) + '">' + escapeHtml(STATUS_RU[s] || s) + "</span>";
  }

  /* ---------------- Cache ---------------- */
  const cache = {
    categories: null,
    productNameById: null, // id -> ru name (for order items)
    couriers: null,
  };
  async function getCategories(force) {
    if (cache.categories && !force) return cache.categories;
    cache.categories = await api("/categories");
    return cache.categories;
  }
  async function getProductNameMap(force) {
    if (cache.productNameById && !force) return cache.productNameById;
    const items = await api("/admin/products");
    const m = {};
    (items || []).forEach(function (p) { m[p.id] = name_ru(p.name_i18n); });
    cache.productNameById = m;
    return m;
  }
  async function getCouriers(force) {
    if (cache.couriers && !force) return cache.couriers;
    cache.couriers = await api("/admin/couriers");
    return cache.couriers;
  }

  /* ---------------- Router / nav ---------------- */
  const view = document.getElementById("view");
  const NAV = [
    { id: "home", label: "Главная", ic: "🏠" },
    { id: "products", label: "Товары", ic: "🍽️" },
    { id: "orders", label: "Заказы", ic: "🧾" },
    { id: "couriers", label: "Курьеры", ic: "🛵" },
  ];
  let current = null;
  let pollTimer = null;

  function setNav(id) {
    document.querySelectorAll("#topnav button, #bottomnav button").forEach(function (b) {
      b.classList.toggle("active", b.dataset.id === id);
    });
  }
  function buildNav() {
    const top = document.getElementById("topnav");
    const bot = document.getElementById("bottomnav");
    top.innerHTML = "";
    bot.innerHTML = "";
    NAV.forEach(function (n) {
      const tb = el('<button data-id="' + n.id + '">' + escapeHtml(n.label) + "</button>");
      tb.onclick = function () { go(n.id); };
      top.appendChild(tb);
      const bb = el('<button data-id="' + n.id + '"><span class="ic">' + n.ic + '</span><span>' + escapeHtml(n.label) + "</span></button>");
      bb.onclick = function () { go(n.id); };
      bot.appendChild(bb);
    });
  }
  function go(id) {
    if (pollTimer) { clearInterval(pollTimer); pollTimer = null; }
    current = id;
    setNav(id);
    location.hash = id;
    const fn = ROUTES[id] || ROUTES.home;
    fn();
  }

  function loadingGrid(n) {
    let h = '<div class="skeleton-grid">';
    for (let i = 0; i < (n || 4); i++) h += '<div class="skel"></div>';
    return h + "</div>";
  }
  function emptyState(ico, text) {
    return '<div class="empty"><div class="ico">' + ico + "</div><p>" + escapeHtml(text) + "</p></div>";
  }

  /* ================= HOME / DASHBOARD ================= */
  async function renderHome() {
    view.innerHTML =
      '<div class="page-head"><h1>Главная</h1><div class="spacer"></div>' + apiTagHtml() + "</div>" +
      '<div class="stats" id="stats">' +
        statCard("Заказов сегодня", "—") +
        statCard("Выручка сегодня", "—") +
        statCard("Товаров", "—") +
        statCard("Курьеров", "—") +
      "</div>" +
      '<div class="section-title"><span class="live-dot"></span> Активные заказы</div>' +
      '<div id="home-active">' + loadingGrid(3) + "</div>";
    wireApiTag();
    await refreshHome();
    pollTimer = setInterval(function () {
      if (current === "home") refreshHome().catch(function () {});
    }, 15000);
  }
  function statCard(label, value) {
    return '<div class="stat"><div class="stat__label">' + escapeHtml(label) +
      '</div><div class="stat__value">' + value + "</div></div>";
  }
  async function refreshHome() {
    let orders = [], products = { total: 0 }, couriers = [];
    try {
      const r = await Promise.all([
        api("/admin/orders"),
        api("/products?limit=1"),
        getCouriers(true),
      ]);
      orders = r[0] || [];
      products = r[1] || { total: 0 };
      couriers = r[2] || [];
    } catch (e) { err(e); }

    const todays = orders.filter(function (o) { return isToday(o.created_at); });
    const ordersToday = todays.length;
    const revenueToday = todays
      .filter(function (o) { return o.status !== "cancelled"; })
      .reduce(function (s, o) { return s + (o.total_minor || 0); }, 0);
    const productsTotal = (typeof products.total === "number") ? products.total : (products.items ? products.items.length : 0);
    const activeCouriers = couriers.filter(function (c) { return c.is_active; }).length;

    const stats = document.getElementById("stats");
    if (stats) {
      stats.children[0].querySelector(".stat__value").textContent = String(ordersToday);
      stats.children[1].querySelector(".stat__value").innerHTML =
        (Math.round(revenueToday / 100)).toLocaleString("ru-RU") + ' <small>₸</small>';
      stats.children[2].querySelector(".stat__value").textContent = String(productsTotal);
      stats.children[3].querySelector(".stat__value").innerHTML =
        activeCouriers + ' <small>/ ' + couriers.length + "</small>";
    }

    const active = orders.filter(function (o) { return ACTIVE_STATUSES.indexOf(o.status) !== -1; });
    const wrap = document.getElementById("home-active");
    if (!wrap) return;
    if (!active.length) { wrap.innerHTML = emptyState("✅", "Нет активных заказов"); return; }
    wrap.className = "orders-list";
    wrap.innerHTML = active.map(function (o) { return homeOrderCard(o); }).join("");
  }
  function homeOrderCard(o) {
    const courier = o.courier ? (o.courier.name || o.courier.phone || "курьер") : "не назначен";
    const client = o.client ? (o.client.name || o.client.phone || "клиент") : "—";
    return '<div class="order">' +
      '<div class="order__top">' +
        '<span class="order__code">#' + escapeHtml(o.code) + "</span>" +
        statusBadge(o.status) +
        '<span class="order__time">' + escapeHtml(fmtTime(o.created_at)) + "</span>" +
      "</div>" +
      '<div class="order__client"><span class="name">' + escapeHtml(client) + "</span></div>" +
      '<div class="order__foot">' +
        '<span class="order__total">' + tg(o.total_minor) + "</span>" +
        '<span class="order__pay">🛵 ' + escapeHtml(courier) + "</span>" +
      "</div>" +
    "</div>";
  }

  /* ================= PRODUCTS ================= */
  let _products = [];
  let _categories = [];
  async function renderProducts() {
    view.innerHTML =
      '<div class="page-head"><h1>Товары</h1><div class="spacer"></div>' +
      '<button class="btn btn--primary" id="add-product">+ Товар</button></div>' +
      '<div id="products-wrap">' + loadingGrid(6) + "</div>";
    document.getElementById("add-product").onclick = function () { openProductModal(null); };
    try {
      const r = await Promise.all([api("/admin/products"), getCategories()]);
      _products = r[0] || [];
      _categories = r[1] || [];
      // refresh name map cache used by orders
      const m = {}; _products.forEach(function (p) { m[p.id] = name_ru(p.name_i18n); });
      cache.productNameById = m;
    } catch (e) { err(e); document.getElementById("products-wrap").innerHTML = emptyState("⚠️", e.message); return; }
    paintProducts();
  }
  function catName(id) {
    const c = _categories.filter(function (x) { return x.id === id; })[0];
    return c ? name_ru(c.name_i18n) : "";
  }
  function paintProducts() {
    const wrap = document.getElementById("products-wrap");
    if (!_products.length) { wrap.className = ""; wrap.innerHTML = emptyState("🍽️", "Пока нет товаров"); return; }
    wrap.className = "products-grid";
    wrap.innerHTML = _products.map(function (p) {
      const img = mediaUrl(p.main_image_url);
      const price = (p.variants && p.variants.length) ? tg(p.variants[0].price_minor) : "—";
      const imgHtml = img
        ? '<div class="product__img" style="background-image:url(\'' + escapeHtml(img) + '\')">'
        : '<div class="product__img"><div class="ph">🍽️</div>';
      const off = p.is_active ? "" : '<span class="product__off">скрыт</span>';
      return '<div class="product" data-id="' + escapeHtml(p.id) + '">' +
        imgHtml + off + "</div>" +
        '<div class="product__body">' +
          '<div class="product__name">' + escapeHtml(name_ru(p.name_i18n)) + "</div>" +
          '<div class="product__price">' + price + "</div>" +
          '<div class="product__cat">' + escapeHtml(catName(p.category_id)) + "</div>" +
        "</div></div>";
    }).join("");
    wrap.querySelectorAll(".product").forEach(function (node) {
      node.onclick = function () {
        const p = _products.filter(function (x) { return x.id === node.dataset.id; })[0];
        if (p) openProductModal(p);
      };
    });
  }

  function openProductModal(p) {
    const isNew = !p;
    p = p || { name_i18n: {}, description_i18n: {}, variants: [], is_active: true, sort: 0 };
    const nm = p.name_i18n || {}, ds = p.description_i18n || {};
    const catOpts = _categories.map(function (c) {
      const sel = c.id === p.category_id ? " selected" : "";
      return '<option value="' + escapeHtml(c.id) + '"' + sel + ">" + escapeHtml(name_ru(c.name_i18n)) + "</option>";
    }).join("");

    const body =
      '<div class="img-uploader">' +
        '<div class="img-preview" id="img-prev"' +
          (p.main_image_url ? ' style="background-image:url(\'' + escapeHtml(mediaUrl(p.main_image_url)) + '\')"' : "") +
          ">" + (p.main_image_url ? "" : "🍽️") + "</div>" +
        '<div><input type="file" id="img-file" accept="image/*" style="display:none">' +
        '<button type="button" class="btn btn--sm" id="img-btn">Загрузить фото</button>' +
        '<input type="hidden" id="f-image" value="' + escapeHtml(p.main_image_url || "") + '"></div>' +
      "</div>" +
      '<label class="field"><span>Название (RU)</span><input type="text" id="f-ru" value="' + escapeHtml(nm.ru || "") + '"></label>' +
      '<div class="row"><label class="field"><span>Название (KK)</span><input type="text" id="f-kk" value="' + escapeHtml(nm.kk || "") + '"></label>' +
      '<label class="field"><span>Название (EN)</span><input type="text" id="f-en" value="' + escapeHtml(nm.en || "") + '"></label></div>' +
      '<label class="field"><span>Описание (RU)</span><textarea id="f-desc">' + escapeHtml(ds.ru || "") + "</textarea></label>" +
      '<div class="row"><label class="field"><span>Категория</span><select id="f-cat"><option value="">— выбрать —</option>' + catOpts + "</select></label>" +
      '<label class="field"><span>Сортировка</span><input type="number" id="f-sort" value="' + escapeHtml(String(p.sort || 0)) + '"></label></div>' +
      (isNew ? '<label class="field"><span>Slug (уникальный, латиницей)</span><input type="text" id="f-slug" value="' + escapeHtml(p.slug || "") + '" placeholder="manty-beef"></label>' : "") +
      '<label class="field"><span>Варианты (название + цена ₸)</span><div class="variants" id="variants"></div>' +
      '<button type="button" class="btn btn--sm" id="add-variant" style="margin-top:8px">+ Вариант</button></label>' +
      '<label class="switch" style="margin-top:6px"><input type="checkbox" id="f-active"' + (p.is_active ? " checked" : "") + '><span class="track"></span><span class="lbl">Активен (виден в меню)</span></label>';

    const m = modal(isNew ? "Новый товар" : "Редактировать товар", body, [
      isNew ? null : { label: "Удалить", cls: "btn--danger", onClick: function () { confirmDelete(p, m.close); } },
      { spacer: true },
      { label: "Отмена", cls: "btn--ghost", onClick: m.close },
      { label: "Сохранить", cls: "btn--primary", id: "save-btn", onClick: function () { saveProduct(p, isNew, m); } },
    ]);

    // variants editor
    const vWrap = m.root.querySelector("#variants");
    function addVariantRow(v) {
      v = v || { label: "", price_minor: 0, weight_g: 0 };
      const row = el(
        '<div class="variant-row">' +
          '<input type="text" class="v-label" placeholder="Порция" value="' + escapeHtml(v.label || "") + '">' +
          '<div class="price-wrap"><input type="number" class="v-price" min="0" step="1" placeholder="0" value="' + escapeHtml(String(Math.round((v.price_minor || 0) / 100))) + '"><span class="cur">₸</span></div>' +
          '<button type="button" class="rm" title="Удалить">×</button>' +
        "</div>");
      row.dataset.weight = String(v.weight_g || 0);
      row.querySelector(".rm").onclick = function () { row.remove(); };
      vWrap.appendChild(row);
    }
    (p.variants && p.variants.length ? p.variants : [{ label: "Стандарт", price_minor: 0 }]).forEach(addVariantRow);
    m.root.querySelector("#add-variant").onclick = function () { addVariantRow(); };

    // image upload
    const fileInput = m.root.querySelector("#img-file");
    m.root.querySelector("#img-btn").onclick = function () { fileInput.click(); };
    fileInput.onchange = async function () {
      const f = fileInput.files[0];
      if (!f) return;
      const btn = m.root.querySelector("#img-btn");
      btn.disabled = true; btn.textContent = "Загрузка…";
      try {
        const fd = new FormData(); fd.append("file", f);
        const res = await api("/admin/upload", { method: "POST", form: fd });
        m.root.querySelector("#f-image").value = res.url;
        const prev = m.root.querySelector("#img-prev");
        prev.style.backgroundImage = "url('" + mediaUrl(res.url) + "')";
        prev.textContent = "";
        ok("Фото загружено");
      } catch (e) { err(e); }
      btn.disabled = false; btn.textContent = "Загрузить фото";
    };
  }

  function collectVariants(root) {
    const out = [];
    root.querySelectorAll(".variant-row").forEach(function (row) {
      const label = row.querySelector(".v-label").value.trim();
      const priceTg = parseInt(row.querySelector(".v-price").value, 10) || 0;
      if (!label) return;
      out.push({ label: label, price_minor: priceTg * 100, weight_g: parseInt(row.dataset.weight, 10) || 0 });
    });
    return out;
  }

  async function saveProduct(p, isNew, m) {
    const root = m.root;
    const ru = root.querySelector("#f-ru").value.trim();
    const kk = root.querySelector("#f-kk").value.trim();
    const en = root.querySelector("#f-en").value.trim();
    const desc = root.querySelector("#f-desc").value.trim();
    const catId = root.querySelector("#f-cat").value;
    const sort = parseInt(root.querySelector("#f-sort").value, 10) || 0;
    const active = root.querySelector("#f-active").checked;
    const image = root.querySelector("#f-image").value || null;
    const variants = collectVariants(root);

    const name_i18n = {};
    if (ru) name_i18n.ru = ru;
    if (kk) name_i18n.kk = kk;
    if (en) name_i18n.en = en;

    if (!ru) { err({ message: "Укажите название (RU)" }); return; }
    if (!catId) { err({ message: "Выберите категорию" }); return; }

    const payload = {
      name_i18n: name_i18n,
      description_i18n: { ru: desc },
      category_id: catId,
      variants: variants,
      main_image_url: image,
      sort: sort,
      is_active: active,
    };

    if (isNew) {
      const slug = (root.querySelector("#f-slug").value || "").trim();
      if (!slug) { err({ message: "Укажите slug" }); return; }
      payload.slug = slug;
    }

    const btn = root.querySelector("#save-btn");
    btn.disabled = true; btn.textContent = "Сохранение…";
    try {
      if (isNew) await api("/admin/products", { method: "POST", body: payload });
      else await api("/admin/products/" + p.id, { method: "PATCH", body: payload });
      ok(isNew ? "Товар создан" : "Сохранено");
      m.close();
      cache.productNameById = null;
      renderProducts();
    } catch (e) {
      err(e);
      btn.disabled = false; btn.textContent = "Сохранить";
    }
  }

  function confirmDelete(p, after) {
    if (!confirm('Удалить товар "' + name_ru(p.name_i18n) + '"?')) return;
    api("/admin/products/" + p.id, { method: "DELETE" })
      .then(function () { ok("Товар удалён"); if (after) after(); cache.productNameById = null; renderProducts(); })
      .catch(err);
  }

  /* ================= ORDERS ================= */
  const ORDER_FILTERS = [
    { id: "active", label: "Активные" },
    { id: "all", label: "Все" },
    { id: "delivered", label: "Доставленные" },
    { id: "cancelled", label: "Отменённые" },
  ];
  let orderFilter = "active";

  async function renderOrders() {
    view.innerHTML =
      '<div class="page-head"><h1>Заказы</h1></div>' +
      '<div class="chips" id="order-chips">' +
        ORDER_FILTERS.map(function (f) {
          return '<button class="chip' + (f.id === orderFilter ? " active" : "") + '" data-id="' + f.id + '">' + escapeHtml(f.label) + "</button>";
        }).join("") +
      "</div>" +
      '<div id="orders-wrap">' + loadingGrid(4) + "</div>";
    document.querySelectorAll("#order-chips .chip").forEach(function (c) {
      c.onclick = function () {
        orderFilter = c.dataset.id;
        document.querySelectorAll("#order-chips .chip").forEach(function (x) { x.classList.toggle("active", x === c); });
        loadOrders();
      };
    });
    await loadOrders();
    pollTimer = setInterval(function () {
      if (current === "orders") loadOrders(true).catch(function () {});
    }, 15000);
  }

  async function loadOrders(silent) {
    const wrap = document.getElementById("orders-wrap");
    if (!wrap) return;
    if (!silent) wrap.innerHTML = loadingGrid(4);
    let orders = [], names = {}, couriers = [];
    try {
      const r = await Promise.all([api("/admin/orders"), getProductNameMap(), getCouriers()]);
      orders = r[0] || []; names = r[1] || {}; couriers = r[2] || [];
    } catch (e) { err(e); if (!silent) wrap.innerHTML = emptyState("⚠️", e.message); return; }

    if (orderFilter === "active") orders = orders.filter(function (o) { return ACTIVE_STATUSES.indexOf(o.status) !== -1; });
    else if (orderFilter === "delivered") orders = orders.filter(function (o) { return o.status === "delivered"; });
    else if (orderFilter === "cancelled") orders = orders.filter(function (o) { return o.status === "cancelled"; });
    // already newest-first from backend

    if (!orders.length) { wrap.className = ""; wrap.innerHTML = emptyState("🧾", "Нет заказов"); return; }
    wrap.className = "orders-list";
    wrap.innerHTML = orders.map(function (o) { return orderCard(o, names, couriers); }).join("");
    wireOrderCards(wrap, couriers);
  }

  function orderCard(o, names, couriers) {
    const client = o.client || {};
    const clientName = client.name || "Клиент";
    const phone = client.phone || "";
    const items = (o.items || []).map(function (it) {
      const nm = names[it.product_id] || "Товар";
      const label = it.variant_label ? " · " + it.variant_label : "";
      return '<div class="it"><span class="q">' + it.qty + "×</span>" +
        '<span class="nm">' + escapeHtml(nm) + escapeHtml(label) + "</span>" +
        '<span class="pr">' + tg(it.total_minor) + "</span></div>";
    }).join("");

    const statusSel = '<select class="o-status" data-id="' + escapeHtml(o.id) + '">' +
      STATUS_ORDER.map(function (s) {
        return '<option value="' + s + '"' + (s === o.status ? " selected" : "") + ">" + escapeHtml(STATUS_RU[s]) + "</option>";
      }).join("") + "</select>";

    const curId = o.courier ? o.courier.id : (o.courier_id || "");
    const courierSel = '<select class="o-courier" data-id="' + escapeHtml(o.id) + '">' +
      '<option value="">— не назначен</option>' +
      couriers.map(function (c) {
        return '<option value="' + escapeHtml(c.id) + '"' + (c.id === curId ? " selected" : "") + ">" +
          escapeHtml(c.name || c.phone || "курьер") + "</option>";
      }).join("") + "</select>";

    const addr = o.address ? addressLine(o.address) : "";
    const paid = o.payment_status === "paid";

    return '<div class="order">' +
      '<div class="order__top">' +
        '<span class="order__code">#' + escapeHtml(o.code) + "</span>" +
        statusBadge(o.status) +
        '<span class="order__time">' + escapeHtml(fmtTime(o.created_at)) + "</span>" +
      "</div>" +
      '<div class="order__client"><span class="name">' + escapeHtml(clientName) + "</span>" +
        (phone ? ' · <a href="tel:' + escapeHtml(phone) + '">' + escapeHtml(phone) + "</a>" : "") + "</div>" +
      (addr ? '<div class="order__addr">📍 ' + escapeHtml(addr) + "</div>" : "") +
      '<div class="order__items">' + (items || '<div class="it"><span class="nm">—</span></div>') + "</div>" +
      '<div class="order__foot">' +
        '<span class="order__total">' + tg(o.total_minor) + "</span>" +
        '<span class="badge ' + (paid ? "badge--paid" : "badge--unpaid") + '">' + (paid ? "Оплачен" : "Не оплачен") + "</span>" +
        '<span class="order__pay">' + escapeHtml(PAY_RU[o.payment_method] || o.payment_method) + "</span>" +
      "</div>" +
      '<div class="order__controls">' + statusSel + courierSel + "</div>" +
    "</div>";
  }

  function addressLine(a) {
    const parts = [];
    if (a.street) parts.push(a.street);
    if (a.building) parts.push("д. " + a.building);
    if (a.apt) parts.push("кв. " + a.apt);
    if (a.entrance) parts.push("подъезд " + a.entrance);
    if (a.floor) parts.push("этаж " + a.floor);
    return parts.join(", ");
  }

  function wireOrderCards(wrap, couriers) {
    wrap.querySelectorAll(".o-status").forEach(function (sel) {
      sel.onchange = async function () {
        const id = sel.dataset.id, status = sel.value;
        sel.disabled = true;
        try {
          await api("/admin/orders/" + id + "/status", { method: "POST", body: { status: status } });
          ok("Статус: " + STATUS_RU[status]);
          cache.couriers = null;
          loadOrders(true);
        } catch (e) { err(e); sel.disabled = false; }
      };
    });
    wrap.querySelectorAll(".o-courier").forEach(function (sel) {
      sel.onchange = async function () {
        const id = sel.dataset.id, cid = sel.value || null;
        sel.disabled = true;
        try {
          await api("/admin/orders/" + id + "/assign", { method: "POST", body: { courier_id: cid } });
          ok(cid ? "Курьер назначен" : "Курьер снят");
          cache.couriers = null;
          loadOrders(true);
        } catch (e) { err(e); sel.disabled = false; }
      };
    });
  }

  /* ================= COURIERS ================= */
  async function renderCouriers() {
    view.innerHTML =
      '<div class="page-head"><h1>Курьеры</h1><div class="spacer"></div>' +
      '<button class="btn btn--primary" id="add-courier">+ Курьер</button></div>' +
      '<div id="couriers-wrap">' + loadingGrid(3) + "</div>";
    document.getElementById("add-courier").onclick = openCourierModal;
    await loadCouriers();
  }
  async function loadCouriers() {
    const wrap = document.getElementById("couriers-wrap");
    let couriers = [];
    try { couriers = await getCouriers(true); }
    catch (e) { err(e); wrap.innerHTML = emptyState("⚠️", e.message); return; }
    if (!couriers.length) { wrap.className = ""; wrap.innerHTML = emptyState("🛵", "Нет курьеров"); return; }
    wrap.className = "couriers-list";
    wrap.innerHTML = couriers.map(function (c) {
      return '<div class="courier" data-id="' + escapeHtml(c.id) + '">' +
        '<div class="courier__av">' + escapeHtml(initials(c.name || c.phone)) + "</div>" +
        '<div class="courier__main">' +
          '<div class="courier__name">' + escapeHtml(c.name || "Без имени") + "</div>" +
          '<div class="courier__phone">' + escapeHtml(c.phone || "—") + "</div>" +
          '<div class="courier__meta">Активных заказов: ' + (c.active_orders || 0) + "</div>" +
        "</div>" +
        '<div class="courier__actions">' +
          '<label class="switch"><input type="checkbox" class="c-active"' + (c.is_active ? " checked" : "") + '><span class="track"></span></label>' +
          '<button class="btn btn--sm c-pwd">Сменить пароль</button>' +
        "</div>" +
      "</div>";
    }).join("");
    wrap.querySelectorAll(".courier").forEach(function (node) {
      const id = node.dataset.id;
      const c = couriers.filter(function (x) { return x.id === id; })[0];
      node.querySelector(".c-active").onchange = async function (e) {
        const v = e.target.checked;
        try {
          await api("/admin/couriers/" + id, { method: "PATCH", body: { is_active: v } });
          ok(v ? "Курьер активен" : "Курьер отключён");
          cache.couriers = null;
        } catch (er) { err(er); e.target.checked = !v; }
      };
      node.querySelector(".c-pwd").onclick = function () {
        const pwd = prompt("Новый пароль для " + (c.name || c.phone) + " (мин. 6 символов):");
        if (pwd === null) return;
        if (pwd.length < 6) { err({ message: "Пароль слишком короткий" }); return; }
        api("/admin/couriers/" + id, { method: "PATCH", body: { password: pwd } })
          .then(function () { ok("Пароль обновлён"); })
          .catch(err);
      };
    });
  }
  function openCourierModal() {
    const body =
      '<label class="field"><span>Имя</span><input type="text" id="c-name" placeholder="Имя курьера"></label>' +
      '<label class="field"><span>Телефон</span><input type="tel" id="c-phone" placeholder="+7 700 000 00 00"></label>' +
      '<label class="field"><span>Пароль (мин. 6 символов)</span><input type="password" id="c-pwd" placeholder="••••••"></label>';
    const m = modal("Новый курьер", body, [
      { spacer: true },
      { label: "Отмена", cls: "btn--ghost", onClick: function () { m.close(); } },
      { label: "Создать", cls: "btn--primary", id: "c-save", onClick: function () { saveCourier(m); } },
    ]);
  }
  async function saveCourier(m) {
    const name = m.root.querySelector("#c-name").value.trim();
    const phone = m.root.querySelector("#c-phone").value.trim();
    const pwd = m.root.querySelector("#c-pwd").value;
    if (!phone) { err({ message: "Укажите телефон" }); return; }
    if (pwd.length < 6) { err({ message: "Пароль минимум 6 символов" }); return; }
    const btn = m.root.querySelector("#c-save");
    btn.disabled = true; btn.textContent = "Создание…";
    try {
      await api("/admin/couriers", { method: "POST", body: { name: name || null, phone: phone, password: pwd } });
      ok("Курьер создан");
      cache.couriers = null;
      m.close();
      loadCouriers();
    } catch (e) { err(e); btn.disabled = false; btn.textContent = "Создать"; }
  }

  /* ================= Modal helper ================= */
  function modal(title, bodyHtml, footButtons) {
    const overlay = el('<div class="modal-overlay"></div>');
    const root = el(
      '<div class="modal">' +
        '<div class="modal__head"><h2>' + escapeHtml(title) + '</h2><button class="x" aria-label="Закрыть">×</button></div>' +
        '<div class="modal__body"></div>' +
        '<div class="modal__foot"></div>' +
      "</div>");
    root.querySelector(".modal__body").innerHTML = bodyHtml;
    function close() { overlay.style.opacity = "0"; setTimeout(function () { overlay.remove(); }, 140); }
    root.querySelector(".x").onclick = close;
    overlay.onclick = function (e) { if (e.target === overlay) close(); };

    const foot = root.querySelector(".modal__foot");
    (footButtons || []).forEach(function (b) {
      if (!b) return;
      if (b.spacer) { foot.appendChild(el('<div class="spacer"></div>')); return; }
      const btn = el('<button class="btn ' + (b.cls || "") + '"' + (b.id ? ' id="' + b.id + '"' : "") + ">" + escapeHtml(b.label) + "</button>");
      btn.onclick = b.onClick;
      foot.appendChild(btn);
    });
    overlay.appendChild(root);
    document.getElementById("modal-root").appendChild(overlay);
    return { root: root, close: close, overlay: overlay };
  }

  /* ================= API tag (shows / lets you change base) ================= */
  function apiTagHtml() {
    return '<span class="api-tag" id="api-tag" title="Сменить адрес API">🔌 ' + escapeHtml(API_BASE) + "</span>";
  }
  function wireApiTag() {
    const t = document.getElementById("api-tag");
    if (!t) return;
    t.onclick = function () {
      const v = prompt("Адрес API (base):", API_BASE);
      if (v === null) return;
      try { localStorage.setItem("aziza_api", v.trim()); } catch (e) {}
      location.search = ""; // reload without ?api
    };
  }

  /* ================= Routes & boot ================= */
  const ROUTES = {
    home: renderHome,
    products: renderProducts,
    orders: renderOrders,
    couriers: renderCouriers,
  };
  buildNav();
  const start = (location.hash || "").replace("#", "");
  go(ROUTES[start] ? start : "home");
})();
