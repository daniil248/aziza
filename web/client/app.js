/* Aziza Food — Customer storefront (vanilla JS, no build step).
 * Fast PWA replacing the old heavy Flutter app. Talks to the FastAPI backend.
 * Conventions mirror web/admin and web/courier (api helper, mediaUrl, escapeHtml,
 * tg() money, toasts, the ?api= override). */
(function () {
  "use strict";

  /* ================= API base ================= */
  // ?api=<url> overrides + persists for local testing against the live API.
  const params = new URLSearchParams(location.search);
  const apiOverride = params.get("api");
  if (apiOverride) {
    try { localStorage.setItem("aziza_api", apiOverride); } catch (e) {}
  }
  const API_BASE = (window.API_BASE || localStorage.getItem("aziza_api") || "/api/v1").replace(/\/+$/, "");

  // Origin used to resolve relative /static/... image URLs.
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

  /* ================= localStorage keys ================= */
  const TOKEN_KEY = "aziza_token";
  const CART_KEY = "aziza_cart";
  const USER_KEY = "aziza_user";

  function getToken() { try { return localStorage.getItem(TOKEN_KEY); } catch (e) { return null; } }
  function setToken(t) { try { localStorage.setItem(TOKEN_KEY, t); } catch (e) {} }
  function clearToken() {
    try { localStorage.removeItem(TOKEN_KEY); localStorage.removeItem(USER_KEY); } catch (e) {}
  }
  function getUser() {
    try { return JSON.parse(localStorage.getItem(USER_KEY) || "null"); } catch (e) { return null; }
  }
  function setUser(u) {
    try { u ? localStorage.setItem(USER_KEY, JSON.stringify(u)) : localStorage.removeItem(USER_KEY); } catch (e) {}
  }

  /* ================= HTTP ================= */
  async function api(path, opts) {
    opts = opts || {};
    const init = { method: opts.method || "GET", headers: { Accept: "application/json" } };
    if (opts.body !== undefined) {
      init.headers["Content-Type"] = "application/json";
      init.body = JSON.stringify(opts.body);
    }
    if (opts.auth) {
      const t = getToken();
      if (t) init.headers["Authorization"] = "Bearer " + t;
    }
    let res;
    try {
      res = await fetch(API_BASE + path, init);
    } catch (e) {
      throw new Error("Нет связи с сервером");
    }
    // 401 on an authed call -> session dead. Drop token + prompt login.
    if (res.status === 401 && opts.auth) {
      clearToken();
      paintAccount();
      if (!opts.noAuthRedirect) openAuth();
      const e = new Error("Сессия истекла, войдите снова");
      e.status = 401;
      throw e;
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
      const e = new Error(typeof msg === "string" ? msg : "Ошибка запроса");
      e.status = res.status;
      throw e;
    }
    return data;
  }

  /* ================= Helpers ================= */
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
    const v = Math.round((Number(money) || 0) / 100);
    return v.toLocaleString("ru-RU") + " ₸";
  }
  function el(html) {
    const t = document.createElement("template");
    t.innerHTML = html.trim();
    return t.content.firstChild;
  }
  function nameRu(i18n) {
    if (!i18n) return "";
    return i18n.ru || i18n.kk || i18n.en || (Object.values(i18n)[0] || "");
  }
  function fmtDate(iso) {
    if (!iso) return "";
    const d = new Date(iso);
    if (isNaN(d)) return "";
    const now = new Date();
    const hm = d.toLocaleTimeString("ru-RU", { hour: "2-digit", minute: "2-digit" });
    if (d.toDateString() === now.toDateString()) return "сегодня " + hm;
    return d.toLocaleDateString("ru-RU", { day: "2-digit", month: "2-digit" }) + " " + hm;
  }
  function initials(name) {
    const s = (name || "?").trim();
    return s ? s[0].toUpperCase() : "?";
  }
  function plural(n, one, few, many) {
    const m10 = n % 10, m100 = n % 100;
    if (m10 === 1 && m100 !== 11) return one;
    if (m10 >= 2 && m10 <= 4 && (m100 < 10 || m100 >= 20)) return few;
    return many;
  }
  // Cheapest variant's price (variants are the source of truth for price).
  function cheapestVariant(variants) {
    if (!variants || !variants.length) return null;
    return variants.reduce(function (a, b) {
      return (b.price_minor || 0) < (a.price_minor || 0) ? b : a;
    }, variants[0]);
  }

  /* ================= Domain constants ================= */
  const STATUS_RU = {
    pending: "Новый",
    confirmed: "Подтверждён",
    preparing: "Готовится",
    courier_assigned: "Курьер назначен",
    in_transit: "В пути",
    delivered: "Доставлен",
    cancelled: "Отменён",
  };
  const PAY_METHODS = [
    { id: "cash", label: "Наличные", sub: "Оплата курьеру при получении", ic: "💵" },
    { id: "kaspi", label: "Kaspi", sub: "Перевод по номеру / Kaspi QR", ic: "🟥" },
    { id: "card_online", label: "Картой онлайн", sub: "Visa / Mastercard", ic: "💳" },
  ];
  const PAY_RU = { cash: "Наличные", kaspi: "Kaspi", card_online: "Картой онлайн" };
  const ADDR_LABEL_RU = { home: "Дом", work: "Работа", custom: "Другое" };

  function statusBadge(s) {
    return '<span class="badge badge--' + escapeHtml(s) + '">' + escapeHtml(STATUS_RU[s] || s) + "</span>";
  }

  /* ================= Toast ================= */
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

  /* ================= Cart (localStorage) ================= */
  // Stored as [{product_id, slug, name, image, variant_label, price_minor, qty}].
  // price_minor is for display only — the server recomputes money on order.
  let cart = [];
  try { cart = JSON.parse(localStorage.getItem(CART_KEY) || "[]"); } catch (e) { cart = []; }
  if (!Array.isArray(cart)) cart = [];

  function saveCart() {
    try { localStorage.setItem(CART_KEY, JSON.stringify(cart)); } catch (e) {}
    paintCartBar();
  }
  function cartKey(productId, variant) { return productId + "::" + variant; }
  function findLine(productId, variant) {
    return cart.find(function (l) { return l.product_id === productId && l.variant_label === variant; });
  }
  function cartCount() { return cart.reduce(function (s, l) { return s + l.qty; }, 0); }
  function cartSubtotal() { return cart.reduce(function (s, l) { return s + l.price_minor * l.qty; }, 0); }
  function addToCart(item, qty) {
    qty = qty || 1;
    const line = findLine(item.product_id, item.variant_label);
    if (line) line.qty = Math.min(999, line.qty + qty);
    else cart.push({
      product_id: item.product_id, slug: item.slug, name: item.name,
      image: item.image || "", variant_label: item.variant_label,
      price_minor: item.price_minor, qty: Math.min(999, qty),
    });
    saveCart();
  }
  function setLineQty(productId, variant, qty) {
    const line = findLine(productId, variant);
    if (!line) return;
    if (qty <= 0) cart = cart.filter(function (l) { return l !== line; });
    else line.qty = Math.min(999, qty);
    saveCart();
  }

  /* ================= Cart bar ================= */
  const cartbar = document.getElementById("cartbar");
  const cartbarCount = document.getElementById("cartbar-count");
  const cartbarTotal = document.getElementById("cartbar-total");
  function paintCartBar() {
    const n = cartCount();
    if (!n) { cartbar.hidden = true; refreshCardBadges(); return; }
    cartbar.hidden = false;
    cartbarCount.textContent = String(n);
    cartbarTotal.textContent = tg(cartSubtotal());
    refreshCardBadges();
  }
  document.getElementById("cartbar-btn").onclick = openCart;
  // Reflect cart state on visible "+" buttons without a full re-render.
  function refreshCardBadges() {
    document.querySelectorAll(".card__add[data-pid]").forEach(function (b) {
      const inCart = cart.some(function (l) { return l.product_id === b.dataset.pid; });
      b.classList.toggle("in-cart", inCart);
      b.textContent = inCart ? "✓" : "+";
    });
  }

  /* ================= Account button ================= */
  const accountLabel = document.getElementById("account-label");
  document.getElementById("account-btn").onclick = function () {
    if (getToken()) renderProfile(); else openAuth();
  };
  document.getElementById("brand").onclick = function () { renderCatalog(); window.scrollTo(0, 0); };
  function paintAccount() {
    const u = getUser();
    accountLabel.textContent = (u && (u.name || u.phone)) ? (u.name || u.phone) : "Войти";
  }

  /* ================= View / loading / empty ================= */
  const view = document.getElementById("view");
  function loadingGrid(n) {
    let h = '<div class="skel-grid">';
    for (let i = 0; i < (n || 8); i++) h += '<div class="skel"></div>';
    return h + "</div>";
  }
  function emptyState(ico, text, sub) {
    return '<div class="empty"><div class="ico">' + ico + "</div><p>" + escapeHtml(text) + "</p>" +
      (sub ? '<div class="sub">' + escapeHtml(sub) + "</div>" : "") + "</div>";
  }

  /* ================= Catalog (home) ================= */
  let _categories = null;
  let _activeCat = "";   // "" = Все
  let _query = "";
  let _searchTimer = null;
  let _catReqId = 0;

  async function renderCatalog() {
    view.innerHTML =
      '<section class="hero"><span class="hero__emoji">🥟</span>' +
        "<h1>Домашние манты и пельмени</h1>" +
        "<p>Лепим вручную каждый день. Доставим горячими по Алматы.</p></section>" +
      '<div class="searchbar">' +
        '<span class="searchbar__ic">🔎</span>' +
        '<input id="search" type="search" inputmode="search" placeholder="Поиск: манты, самса, пельмени…" autocomplete="off" value="' + escapeHtml(_query) + '">' +
        (_query ? '<button class="searchbar__clear" id="search-clear" aria-label="Очистить">×</button>' : "") +
      "</div>" +
      '<div class="chips" id="chips"></div>' +
      '<div id="catalog">' + loadingGrid(8) + "</div>";

    const search = document.getElementById("search");
    search.oninput = function () {
      _query = search.value;
      const clear = document.getElementById("search-clear");
      if (_query && !clear) {
        const c = el('<button class="searchbar__clear" id="search-clear" aria-label="Очистить">×</button>');
        c.onclick = clearSearch;
        document.querySelector(".searchbar").appendChild(c);
      } else if (!_query && clear) clear.remove();
      clearTimeout(_searchTimer);
      _searchTimer = setTimeout(loadProducts, 280);
    };
    const sc = document.getElementById("search-clear");
    if (sc) sc.onclick = clearSearch;

    await ensureCategories();
    paintChips();
    await loadProducts();
  }
  function clearSearch() {
    _query = "";
    const s = document.getElementById("search");
    if (s) s.value = "";
    const c = document.getElementById("search-clear");
    if (c) c.remove();
    loadProducts();
  }

  async function ensureCategories() {
    if (_categories) return _categories;
    try { _categories = await api("/categories"); }
    catch (e) { _categories = []; err(e); }
    return _categories;
  }
  function paintChips() {
    const wrap = document.getElementById("chips");
    if (!wrap) return;
    const chips = [{ slug: "", name: "Все" }].concat(
      (_categories || []).map(function (c) { return { slug: c.slug, name: nameRu(c.name_i18n) }; })
    );
    wrap.innerHTML = chips.map(function (c) {
      return '<button class="chip' + (c.slug === _activeCat ? " active" : "") + '" data-slug="' + escapeHtml(c.slug) + '">' +
        escapeHtml(c.name) + "</button>";
    }).join("");
    wrap.querySelectorAll(".chip").forEach(function (b) {
      b.onclick = function () {
        if (_activeCat === b.dataset.slug) return;
        _activeCat = b.dataset.slug;
        paintChips();
        loadProducts();
      };
    });
  }

  async function loadProducts() {
    const wrap = document.getElementById("catalog");
    if (!wrap) return;
    wrap.innerHTML = loadingGrid(8);
    const reqId = ++_catReqId;
    const qs = new URLSearchParams();
    if (_activeCat) qs.set("category", _activeCat);
    if (_query.trim()) qs.set("q", _query.trim());
    qs.set("limit", "60");
    let data;
    try { data = await api("/products?" + qs.toString()); }
    catch (e) {
      if (reqId !== _catReqId) return;
      wrap.innerHTML = emptyState("⚠️", e.message, "Потяните вниз или попробуйте позже");
      return;
    }
    if (reqId !== _catReqId) return; // a newer request superseded this one
    const items = (data && data.items) || [];
    if (!items.length) {
      wrap.innerHTML = emptyState("🍽️", _query ? "Ничего не найдено" : "В этой категории пока пусто",
        _query ? "Попробуйте другой запрос" : "");
      return;
    }
    wrap.className = "grid";
    wrap.innerHTML = items.map(productCard).join("");
    wrap.querySelectorAll(".card").forEach(function (node) {
      node.onclick = function (ev) {
        if (ev.target.closest(".card__add")) return;
        openProduct(node.dataset.slug);
      };
    });
    wrap.querySelectorAll(".card__add").forEach(function (b) {
      b.onclick = function (ev) { ev.stopPropagation(); quickAdd(b.dataset.slug); };
    });
    refreshCardBadges();
  }

  function productCard(p) {
    const v = cheapestVariant(p.variants);
    const img = mediaUrl(p.main_image_url);
    const hasRange = p.variants && p.variants.length > 1;
    const priceHtml = v
      ? (hasRange ? '<span class="card__price">от ' + tg(v.price_minor) + "</span>" : '<span class="card__price">' + tg(v.price_minor) + "</span>")
      : '<span class="card__price muted">—</span>';
    const weight = v && v.weight_g ? '<div class="card__weight">' + escapeHtml(v.label) + " · " + v.weight_g + " г</div>"
      : (v ? '<div class="card__weight">' + escapeHtml(v.label) + "</div>" : "");
    const imgStyle = img ? ' style="background-image:url(\'' + escapeHtml(img) + '\')"' : "";
    const ph = img ? "" : '<span class="ph">🥟</span>';
    return '<div class="card" data-slug="' + escapeHtml(p.slug) + '">' +
      '<div class="card__img"' + imgStyle + ">" + ph + "</div>" +
      '<div class="card__body">' +
        '<div class="card__name">' + escapeHtml(nameRu(p.name_i18n)) + "</div>" +
        weight +
        '<div class="card__foot">' + priceHtml +
          '<button class="card__add" data-pid="' + escapeHtml(p.id) + '" data-slug="' + escapeHtml(p.slug) + '" aria-label="В корзину">+</button>' +
        "</div>" +
      "</div></div>";
  }

  // Quick "+" from the grid: add the cheapest variant directly.
  async function quickAdd(slug) {
    let p;
    try { p = await api("/products/" + encodeURIComponent(slug)); }
    catch (e) { err(e); return; }
    const v = cheapestVariant(p.variants);
    if (!v) { err({ message: "Нет доступных вариантов" }); return; }
    addToCart({
      product_id: p.id, slug: p.slug, name: nameRu(p.name_i18n),
      image: p.main_image_url, variant_label: v.label, price_minor: v.price_minor,
    }, 1);
    ok("Добавлено в корзину");
  }

  /* ================= Product detail (sheet) ================= */
  async function openProduct(slug) {
    const sheet = openSheet("", '<div>' + loadingGrid(2) + "</div>");
    let p;
    try { p = await api("/products/" + encodeURIComponent(slug)); }
    catch (e) { sheet.close(); err(e); return; }
    paintProduct(sheet, p);
  }

  function paintProduct(sheet, p) {
    const variants = (p.variants || []).slice();
    let vIdx = 0;
    let qty = 1;
    const gallery = [];
    if (p.main_image_url) gallery.push(p.main_image_url);
    (p.gallery_urls || []).forEach(function (u) { if (gallery.indexOf(u) === -1) gallery.push(u); });

    const kbju = p.kbju || {};
    const hasKbju = kbju && (kbju.kcal || kbju.protein || kbju.fat || kbju.carb);
    const desc = nameRu(p.description_i18n);

    const heroImg = gallery.length ? mediaUrl(gallery[0]) : "";
    const body =
      '<div class="pd__hero" id="pd-hero"' + (heroImg ? ' style="background-image:url(\'' + escapeHtml(heroImg) + '\')"' : "") + ">" +
        (heroImg ? "" : '<span class="ph">🥟</span>') + "</div>" +
      (gallery.length > 1 ? '<div class="pd__gallery" id="pd-gallery">' + gallery.map(function (u, i) {
          return '<div class="pd__thumb' + (i === 0 ? " active" : "") + '" data-i="' + i + '" style="background-image:url(\'' + escapeHtml(mediaUrl(u)) + '\')"></div>';
        }).join("") + "</div>" : "") +
      '<h2 class="pd__name">' + escapeHtml(nameRu(p.name_i18n)) + "</h2>" +
      (desc ? '<p class="pd__desc">' + escapeHtml(desc) + "</p>" : "") +
      (hasKbju ? '<div class="kbju">' +
          kbjuCell(kbju.kcal, "ккал") + kbjuCell(kbju.protein, "белки") +
          kbjuCell(kbju.fat, "жиры") + kbjuCell(kbju.carb, "углев.") +
        "</div>" : "") +
      (variants.length ? '<div class="variants" id="pd-variants">' + variants.map(function (v, i) {
          return variantRow(v, i === 0);
        }).join("") + "</div>" : emptyState("🚫", "Нет доступных вариантов"));

    sheet.setBody(body);
    sheet.setTitle("");

    if (!variants.length) { sheet.setFoot(""); return; }

    // Gallery thumbs
    const hero = sheet.root.querySelector("#pd-hero");
    sheet.root.querySelectorAll(".pd__thumb").forEach(function (th) {
      th.onclick = function () {
        sheet.root.querySelectorAll(".pd__thumb").forEach(function (x) { x.classList.toggle("active", x === th); });
        hero.style.backgroundImage = "url('" + mediaUrl(gallery[+th.dataset.i]) + "')";
      };
    });

    // Variant select
    const vWrap = sheet.root.querySelector("#pd-variants");
    function selectVariant(i) {
      vIdx = i;
      vWrap.querySelectorAll(".variant").forEach(function (n, k) { n.classList.toggle("active", k === i); });
      updateFoot();
    }
    vWrap.querySelectorAll(".variant").forEach(function (n, i) { n.onclick = function () { selectVariant(i); }; });

    // Footer: stepper + add button
    const foot = el(
      '<div class="pd__action">' +
        '<div class="stepper">' +
          '<button id="pd-dec" aria-label="Меньше">−</button>' +
          '<span class="stepper__val" id="pd-qty">1</span>' +
          '<button id="pd-inc" aria-label="Больше">+</button>' +
        "</div>" +
        '<button class="btn btn--primary btn--lg" id="pd-add"></button>' +
      "</div>");
    sheet.setFoot("");
    sheet.foot.appendChild(foot);

    function updateFoot() {
      foot.querySelector("#pd-qty").textContent = String(qty);
      foot.querySelector("#pd-dec").disabled = qty <= 1;
      const v = variants[vIdx];
      foot.querySelector("#pd-add").innerHTML = "Добавить · " + tg((v ? v.price_minor : 0) * qty);
    }
    foot.querySelector("#pd-dec").onclick = function () { if (qty > 1) { qty--; updateFoot(); } };
    foot.querySelector("#pd-inc").onclick = function () { if (qty < 999) { qty++; updateFoot(); } };
    foot.querySelector("#pd-add").onclick = function () {
      const v = variants[vIdx];
      addToCart({
        product_id: p.id, slug: p.slug, name: nameRu(p.name_i18n),
        image: p.main_image_url, variant_label: v.label, price_minor: v.price_minor,
      }, qty);
      ok("Добавлено в корзину");
      sheet.close();
    };
    selectVariant(0);
  }
  function kbjuCell(val, lbl) {
    return '<div class="kbju__cell"><div class="kbju__val">' + escapeHtml(String(Math.round(Number(val) || 0))) +
      '</div><div class="kbju__lbl">' + escapeHtml(lbl) + "</div></div>";
  }
  function variantRow(v, active) {
    const label = nameRu(v.label_i18n) || v.label;
    const weight = v.weight_g ? '<span class="variant__weight">' + v.weight_g + " г</span>" : "";
    const old = v.old_price_minor && v.old_price_minor > v.price_minor
      ? '<span class="old">' + tg(v.old_price_minor) + "</span>" : "";
    return '<div class="variant' + (active ? " active" : "") + '">' +
      '<span class="variant__radio"></span>' +
      '<span class="variant__label">' + escapeHtml(label) + " " + weight + "</span>" +
      '<span class="variant__price">' + old + tg(v.price_minor) + "</span>" +
    "</div>";
  }

  /* ================= Cart sheet ================= */
  function openCart() {
    const sheet = openSheet("Корзина", "");
    function paint() {
      if (!cart.length) {
        sheet.setBody(emptyState("🛒", "Корзина пуста", "Добавьте что-нибудь вкусное"));
        sheet.setFoot("");
        return;
      }
      sheet.setBody('<div id="cart-lines"></div>' +
        '<div class="summary"><div class="summary__row total"><span>Итого</span><span id="cart-sum">' + tg(cartSubtotal()) + "</span></div></div>" +
        '<div class="muted center mt8" style="font-size:12.5px">Доставка рассчитывается при оформлении</div>');
      const linesWrap = sheet.root.querySelector("#cart-lines");
      linesWrap.innerHTML = cart.map(cartLine).join("");
      linesWrap.querySelectorAll(".cart-line").forEach(function (node) {
        const pid = node.dataset.pid, variant = node.dataset.variant;
        node.querySelector(".dec").onclick = function () {
          const l = findLine(pid, variant); setLineQty(pid, variant, l.qty - 1); paint();
        };
        node.querySelector(".inc").onclick = function () {
          const l = findLine(pid, variant); setLineQty(pid, variant, l.qty + 1); paint();
        };
        node.querySelector(".cart-line__rm").onclick = function () { setLineQty(pid, variant, 0); paint(); };
      });
      sheet.setFoot("");
      const checkout = el('<button class="btn btn--primary btn--lg btn--block">Оформить заказ · ' + tg(cartSubtotal()) + "</button>");
      checkout.onclick = function () { sheet.close(); openCheckout(); };
      sheet.foot.appendChild(checkout);
    }
    paint();
  }
  function cartLine(l) {
    const img = mediaUrl(l.image);
    const imgInner = img ? "" : "🥟";
    const imgStyle = img ? ' style="background-image:url(\'' + escapeHtml(img) + '\')"' : "";
    return '<div class="cart-line" data-pid="' + escapeHtml(l.product_id) + '" data-variant="' + escapeHtml(l.variant_label) + '">' +
      '<div class="cart-line__img"' + imgStyle + ">" + imgInner + "</div>" +
      '<div class="cart-line__main">' +
        '<div class="cart-line__name">' + escapeHtml(l.name) + "</div>" +
        '<div class="cart-line__variant">' + escapeHtml(l.variant_label) + "</div>" +
        '<div class="cart-line__price">' + tg(l.price_minor * l.qty) + "</div>" +
      "</div>" +
      '<div class="cart-line__side">' +
        '<div class="stepper"><button class="dec">−</button><span class="stepper__val">' + l.qty + '</span><button class="inc">+</button></div>' +
        '<button class="cart-line__rm">удалить</button>' +
      "</div>" +
    "</div>";
  }

  /* ================= Auth (login / register sheet) ================= */
  function openAuth(onSuccess) {
    const sheet = openSheet("Вход", "");
    let mode = "login"; // or "register"
    function paint() {
      const isReg = mode === "register";
      sheet.setTitle(isReg ? "Регистрация" : "Вход");
      sheet.setBody(
        '<div class="auth-tabs">' +
          '<button data-m="login" class="' + (!isReg ? "active" : "") + '">Вход</button>' +
          '<button data-m="register" class="' + (isReg ? "active" : "") + '">Регистрация</button>' +
        "</div>" +
        (isReg ? '<label class="field"><span>Имя</span><input id="a-name" type="text" placeholder="Как вас зовут"></label>' : "") +
        '<label class="field"><span>Телефон</span><input id="a-phone" type="tel" inputmode="tel" placeholder="+7 700 000 00 00"></label>' +
        '<label class="field"><span>Пароль</span><input id="a-pwd" type="password" placeholder="••••••" autocomplete="' + (isReg ? "new-password" : "current-password") + '"></label>' +
        (isReg ? '<div class="muted" style="font-size:12px">Минимум 6 символов</div>' : "")
      );
      sheet.root.querySelectorAll(".auth-tabs button").forEach(function (b) {
        b.onclick = function () { mode = b.dataset.m; paint(); };
      });
      sheet.setFoot("");
      const submit = el('<button class="btn btn--primary btn--lg btn--block">' + (isReg ? "Зарегистрироваться" : "Войти") + "</button>");
      submit.onclick = doSubmit;
      sheet.foot.appendChild(submit);
      // Enter submits
      sheet.root.querySelectorAll("input").forEach(function (inp) {
        inp.onkeydown = function (e) { if (e.key === "Enter") doSubmit(); };
      });

      async function doSubmit() {
        const phone = (sheet.root.querySelector("#a-phone").value || "").trim();
        const pwd = sheet.root.querySelector("#a-pwd").value || "";
        const name = isReg ? (sheet.root.querySelector("#a-name").value || "").trim() : "";
        if (!phone) { err({ message: "Укажите телефон" }); return; }
        if (isReg && pwd.length < 6) { err({ message: "Пароль минимум 6 символов" }); return; }
        if (!pwd) { err({ message: "Укажите пароль" }); return; }
        submit.disabled = true;
        submit.innerHTML = '<span class="spin"></span>';
        try {
          const payload = isReg ? { phone: phone, password: pwd, name: name || null } : { phone: phone, password: pwd };
          const res = await api(isReg ? "/auth/register" : "/auth/login", { method: "POST", body: payload });
          setToken(res.access_token);
          setUser(res.user);
          paintAccount();
          ok(isReg ? "Добро пожаловать!" : "С возвращением!");
          sheet.close();
          if (onSuccess) onSuccess();
        } catch (e) {
          err(e);
          submit.disabled = false;
          submit.textContent = isReg ? "Зарегистрироваться" : "Войти";
        }
      }
    }
    paint();
  }

  /* ================= Checkout ================= */
  async function openCheckout() {
    if (!cart.length) { err({ message: "Корзина пуста" }); return; }
    if (!getToken()) { openAuth(function () { openCheckout(); }); return; }

    const sheet = openSheet("Оформление", loadingGrid(2));
    let addresses = [];
    try { addresses = await api("/auth/me/addresses", { auth: true }); }
    catch (e) { if (e.status === 401) { sheet.close(); return; } err(e); addresses = []; }

    let selectedAddr = (addresses.find(function (a) { return a.is_default; }) || addresses[0] || {}).id || "";
    let payMethod = "cash";
    let addingAddr = !addresses.length;

    function paint() {
      const addrSection = addingAddr ? addrForm() : addrPicker();
      sheet.setBody(
        '<div class="section-title">Адрес доставки</div>' +
        '<div id="addr-section">' + addrSection + "</div>" +
        '<div class="section-title">Способ оплаты</div>' +
        '<div class="radio-list" id="pay-list">' + PAY_METHODS.map(function (m) {
          return '<label class="radio' + (m.id === payMethod ? " active" : "") + '" data-id="' + m.id + '">' +
            '<span class="radio__dot"></span>' +
            '<span class="radio__body"><span class="radio__title">' + m.ic + " " + escapeHtml(m.label) + "</span>" +
            '<span class="radio__sub">' + escapeHtml(m.sub) + "</span></span></label>";
        }).join("") + "</div>" +
        '<label class="field"><span>Комментарий к заказу</span><textarea id="ck-comment" placeholder="Напр.: позвонить за 10 минут"></textarea></label>'
      );
      wireAddr();
      sheet.root.querySelectorAll("#pay-list .radio").forEach(function (r) {
        r.onclick = function () {
          payMethod = r.dataset.id;
          sheet.root.querySelectorAll("#pay-list .radio").forEach(function (x) { x.classList.toggle("active", x === r); });
        };
      });
      sheet.setFoot("");
      const submit = el('<button class="btn btn--primary btn--lg btn--block">Заказать · ' + tg(cartSubtotal()) + "</button>");
      submit.onclick = placeOrder;
      sheet.foot.appendChild(submit);

      async function placeOrder() {
        let addrId = selectedAddr;
        // Inline new address — create it first.
        if (addingAddr) {
          const data = readAddrForm();
          if (!data) return;
          submit.disabled = true; submit.innerHTML = '<span class="spin"></span>';
          try {
            const created = await api("/auth/me/addresses", { method: "POST", auth: true, body: data });
            addrId = created.id;
          } catch (e) { err(e); submit.disabled = false; submit.textContent = "Заказать · " + tgPlain(); return; }
        }
        if (!addrId) { err({ message: "Выберите или добавьте адрес" }); return; }

        const comment = (sheet.root.querySelector("#ck-comment").value || "").trim();
        const items = cart.map(function (l) {
          return { product_id: l.product_id, variant_label: l.variant_label, qty: l.qty };
        });
        submit.disabled = true; submit.innerHTML = '<span class="spin"></span>';
        try {
          const order = await api("/orders", {
            method: "POST", auth: true,
            body: { address_id: addrId, items: items, payment_method: payMethod, comment: comment || null },
          });
          cart = []; saveCart();
          showOrderSuccess(sheet, order);
        } catch (e) {
          // 422 -> a product/variant changed or is gone. Make it actionable.
          if (e.status === 422) {
            err({ message: "Товар изменился или недоступен: " + e.message + ". Проверьте корзину." });
          } else err(e);
          submit.disabled = false; submit.textContent = "Заказать · " + tgPlain();
        }
      }
      function tgPlain() { return tg(cartSubtotal()); }
    }

    function addrPicker() {
      return '<div class="radio-list">' + addresses.map(function (a) {
        return '<label class="radio' + (a.id === selectedAddr ? " active" : "") + '" data-aid="' + escapeHtml(a.id) + '">' +
          '<span class="radio__dot"></span>' +
          '<span class="radio__body"><span class="radio__title">' + escapeHtml(addrTitle(a)) + "</span>" +
          '<span class="radio__sub">' + escapeHtml(addrLine(a)) + "</span></span></label>";
      }).join("") + "</div>" +
      '<button class="linkbtn" id="add-addr-btn">+ Добавить новый адрес</button>';
    }
    function addrForm() {
      return '<div class="addr-form">' +
        '<label class="field"><span>Улица *</span><input id="ad-street" type="text" placeholder="ул. Абая"></label>' +
        '<div class="row">' +
          '<label class="field"><span>Дом</span><input id="ad-building" type="text" placeholder="12"></label>' +
          '<label class="field"><span>Квартира</span><input id="ad-apt" type="text" placeholder="34"></label>' +
        "</div>" +
        '<div class="row">' +
          '<label class="field"><span>Подъезд</span><input id="ad-entrance" type="text"></label>' +
          '<label class="field"><span>Этаж</span><input id="ad-floor" type="text"></label>' +
        "</div>" +
        '<label class="field"><span>Комментарий</span><input id="ad-comment" type="text" placeholder="Домофон, ориентир"></label>' +
        (addresses.length ? '<button class="linkbtn" id="cancel-addr-btn">← Выбрать из сохранённых</button>' : "") +
      "</div>";
    }
    function wireAddr() {
      const addBtn = sheet.root.querySelector("#add-addr-btn");
      if (addBtn) addBtn.onclick = function () { addingAddr = true; paint(); };
      const cancelBtn = sheet.root.querySelector("#cancel-addr-btn");
      if (cancelBtn) cancelBtn.onclick = function () { addingAddr = false; paint(); };
      sheet.root.querySelectorAll(".radio[data-aid]").forEach(function (r) {
        r.onclick = function () {
          selectedAddr = r.dataset.aid;
          sheet.root.querySelectorAll(".radio[data-aid]").forEach(function (x) { x.classList.toggle("active", x === r); });
        };
      });
    }
    function readAddrForm() {
      const street = (sheet.root.querySelector("#ad-street").value || "").trim();
      if (!street) { err({ message: "Укажите улицу" }); return null; }
      return {
        label: "home",
        street: street,
        building: (sheet.root.querySelector("#ad-building").value || "").trim() || null,
        apt: (sheet.root.querySelector("#ad-apt").value || "").trim() || null,
        entrance: (sheet.root.querySelector("#ad-entrance").value || "").trim() || null,
        floor: (sheet.root.querySelector("#ad-floor").value || "").trim() || null,
        comment: (sheet.root.querySelector("#ad-comment").value || "").trim() || null,
        is_default: !addresses.length,
      };
    }
    paint();
  }

  function showOrderSuccess(sheet, order) {
    paintCartBar();
    sheet.setTitle("Заказ оформлен");
    sheet.setBody(
      '<div class="success">' +
        '<div class="success__ic">✓</div>' +
        "<h2>Заказ принят!</h2>" +
        "<p>Мы свяжемся с вами для подтверждения</p>" +
        '<div class="success__code">' + escapeHtml(order.code) + "</div>" +
        '<p style="font-size:17px;color:var(--text);font-weight:800">' + tg(order.total_minor) + "</p>" +
        (order.delivery_fee_minor ? '<p class="muted" style="font-size:13px">включая доставку ' + tg(order.delivery_fee_minor) + "</p>" : "") +
      "</div>");
    sheet.setFoot("");
    const myOrders = el('<button class="btn btn--ghost btn--block">Мои заказы</button>');
    myOrders.onclick = function () { sheet.close(); renderProfile(); };
    const back = el('<button class="btn btn--primary btn--block mt8">За покупками</button>');
    back.onclick = function () { sheet.close(); renderCatalog(); };
    sheet.foot.appendChild(myOrders);
    sheet.foot.appendChild(back);
  }

  /* ================= Profile ================= */
  async function renderProfile() {
    if (!getToken()) { openAuth(function () { renderProfile(); }); return; }
    window.scrollTo(0, 0);
    view.className = "view";
    view.innerHTML =
      '<div class="profile-head" id="profile-head"></div>' +
      '<div class="list-section"><div class="list-section__head"><h3>Мои заказы</h3></div>' +
        '<div id="orders-wrap">' + loadingGrid(2) + "</div></div>" +
      '<div class="list-section"><div class="list-section__head"><h3>Адреса</h3>' +
        '<button class="linkbtn" id="add-addr">+ Добавить</button></div>' +
        '<div id="addr-wrap"></div></div>' +
      '<button class="btn btn--block" id="logout-btn">Выйти</button>';

    const u = getUser() || {};
    document.getElementById("profile-head").innerHTML =
      '<div class="profile-head__av">' + escapeHtml(initials(u.name || u.phone)) + "</div>" +
      "<div><div class=\"profile-head__name\">" + escapeHtml(u.name || "Гость") + "</div>" +
      '<div class="profile-head__phone">' + escapeHtml(u.phone || "") + "</div></div>";

    document.getElementById("logout-btn").onclick = function () {
      clearToken();
      paintAccount();
      ok("Вы вышли");
      renderCatalog();
    };
    document.getElementById("add-addr").onclick = function () { openAddrSheet(loadAddresses); };

    // Refresh user from server (best effort), then load orders + addresses.
    api("/auth/me", { auth: true, noAuthRedirect: true }).then(function (me) {
      if (me) {
        setUser(me); paintAccount();
        const head = document.getElementById("profile-head");
        if (head) head.querySelector(".profile-head__name").textContent = me.name || "Гость";
      }
    }).catch(function () {});

    loadOrders();
    loadAddresses();
  }

  async function loadOrders() {
    const wrap = document.getElementById("orders-wrap");
    if (!wrap) return;
    let orders;
    try { orders = await api("/orders", { auth: true, noAuthRedirect: true }); }
    catch (e) {
      if (e.status === 401) { wrap.innerHTML = emptyState("🔒", "Войдите снова"); return; }
      wrap.innerHTML = emptyState("⚠️", e.message); return;
    }
    if (!orders || !orders.length) { wrap.innerHTML = emptyState("🧾", "Заказов пока нет", "Самое время заказать манты"); return; }
    wrap.className = "olist";
    wrap.innerHTML = orders.map(orderCardHtml).join("");
    wrap.querySelectorAll(".ocard").forEach(function (node) {
      node.onclick = function () { openOrderDetail(node.dataset.id); };
    });
  }
  function orderCardHtml(o) {
    const count = (o.items || []).reduce(function (s, it) { return s + it.qty; }, 0);
    return '<div class="ocard" data-id="' + escapeHtml(o.id) + '">' +
      '<div class="ocard__top"><span class="ocard__code">#' + escapeHtml(o.code) + "</span>" +
        statusBadge(o.status) +
        '<span class="ocard__time">' + escapeHtml(fmtDate(o.created_at)) + "</span></div>" +
      '<div class="ocard__foot"><span class="ocard__total">' + tg(o.total_minor) + "</span>" +
        '<span class="ocard__count">' + count + " " + plural(count, "товар", "товара", "товаров") + "</span></div>" +
    "</div>";
  }

  async function openOrderDetail(id) {
    const sheet = openSheet("Заказ", loadingGrid(2));
    let o;
    try { o = await api("/orders/" + encodeURIComponent(id), { auth: true, noAuthRedirect: true }); }
    catch (e) { sheet.close(); err(e); return; }
    sheet.setTitle("Заказ #" + o.code);
    const items = (o.items || []).map(function (it) {
      return '<div class="odi"><span class="odi__q">' + it.qty + "×</span>" +
        '<span class="odi__nm">' + escapeHtml(it.variant_label || "Товар") + "</span>" +
        '<span class="odi__pr">' + tg(it.total_minor) + "</span></div>";
    }).join("");
    sheet.setBody(
      '<div class="center" style="margin-bottom:12px">' + statusBadge(o.status) +
        '<div class="muted mt8" style="font-size:13px">' + escapeHtml(fmtDate(o.created_at)) + "</div></div>" +
      '<div class="section-title">Состав</div>' +
      '<div class="order-detail-items">' + (items || '<div class="muted">—</div>') + "</div>" +
      '<div class="summary">' +
        '<div class="summary__row"><span>Сумма</span><span>' + tg(o.subtotal_minor) + "</span></div>" +
        (o.delivery_fee_minor ? '<div class="summary__row"><span>Доставка</span><span>' + tg(o.delivery_fee_minor) + "</span></div>" : "") +
        (o.discount_minor ? '<div class="summary__row"><span>Скидка</span><span>−' + tg(o.discount_minor) + "</span></div>" : "") +
        '<div class="summary__row total"><span>Итого</span><span>' + tg(o.total_minor) + "</span></div>" +
      "</div>" +
      '<div class="muted mt16" style="font-size:13px">Оплата: ' + escapeHtml(PAY_RU[o.payment_method] || o.payment_method) + "</div>" +
      (o.comment ? '<div class="muted" style="font-size:13px">Комментарий: ' + escapeHtml(o.comment) + "</div>" : "")
    );
    sheet.setFoot("");
  }

  async function loadAddresses() {
    const wrap = document.getElementById("addr-wrap");
    if (!wrap) return;
    let addresses;
    try { addresses = await api("/auth/me/addresses", { auth: true, noAuthRedirect: true }); }
    catch (e) { wrap.innerHTML = emptyState("⚠️", e.message); return; }
    if (!addresses || !addresses.length) { wrap.innerHTML = '<div class="muted" style="padding:4px 2px">Нет сохранённых адресов</div>'; return; }
    wrap.innerHTML = addresses.map(function (a) {
      return '<div class="addr-card" data-id="' + escapeHtml(a.id) + '">' +
        '<div class="addr-card__body">' +
          '<div class="addr-card__label">' + escapeHtml(addrTitle(a)) +
            (a.is_default ? ' <span class="pill-default">по умолчанию</span>' : "") + "</div>" +
          '<div class="addr-card__text">' + escapeHtml(addrLine(a)) + "</div>" +
        "</div>" +
        '<button class="addr-card__del" aria-label="Удалить">🗑</button>' +
      "</div>";
    }).join("");
    wrap.querySelectorAll(".addr-card").forEach(function (node) {
      node.querySelector(".addr-card__del").onclick = async function () {
        if (!confirm("Удалить адрес?")) return;
        try { await api("/auth/me/addresses/" + node.dataset.id, { method: "DELETE", auth: true }); ok("Адрес удалён"); loadAddresses(); }
        catch (e) { err(e); }
      };
    });
  }

  function openAddrSheet(after) {
    const sheet = openSheet("Новый адрес", "");
    sheet.setBody(
      '<label class="field"><span>Улица *</span><input id="ns-street" type="text" placeholder="ул. Абая"></label>' +
      '<div class="row">' +
        '<label class="field"><span>Дом</span><input id="ns-building" type="text" placeholder="12"></label>' +
        '<label class="field"><span>Квартира</span><input id="ns-apt" type="text" placeholder="34"></label>' +
      "</div>" +
      '<div class="row">' +
        '<label class="field"><span>Подъезд</span><input id="ns-entrance" type="text"></label>' +
        '<label class="field"><span>Этаж</span><input id="ns-floor" type="text"></label>' +
      "</div>" +
      '<label class="field"><span>Комментарий</span><input id="ns-comment" type="text" placeholder="Домофон, ориентир"></label>'
    );
    sheet.setFoot("");
    const save = el('<button class="btn btn--primary btn--lg btn--block">Сохранить адрес</button>');
    save.onclick = async function () {
      const street = (sheet.root.querySelector("#ns-street").value || "").trim();
      if (!street) { err({ message: "Укажите улицу" }); return; }
      save.disabled = true; save.innerHTML = '<span class="spin"></span>';
      try {
        await api("/auth/me/addresses", {
          method: "POST", auth: true,
          body: {
            label: "home", street: street,
            building: (sheet.root.querySelector("#ns-building").value || "").trim() || null,
            apt: (sheet.root.querySelector("#ns-apt").value || "").trim() || null,
            entrance: (sheet.root.querySelector("#ns-entrance").value || "").trim() || null,
            floor: (sheet.root.querySelector("#ns-floor").value || "").trim() || null,
            comment: (sheet.root.querySelector("#ns-comment").value || "").trim() || null,
          },
        });
        ok("Адрес добавлен");
        sheet.close();
        if (after) after();
      } catch (e) { err(e); save.disabled = false; save.textContent = "Сохранить адрес"; }
    };
    sheet.foot.appendChild(save);
  }

  function addrTitle(a) {
    return ADDR_LABEL_RU[a.label] || "Адрес";
  }
  function addrLine(a) {
    const parts = [];
    if (a.street) parts.push(a.street);
    if (a.building) parts.push("д. " + a.building);
    if (a.apt) parts.push("кв. " + a.apt);
    if (a.entrance) parts.push("подъезд " + a.entrance);
    if (a.floor) parts.push("этаж " + a.floor);
    return parts.join(", ");
  }

  /* ================= Sheet helper ================= */
  function openSheet(title, bodyHtml) {
    const overlay = el('<div class="overlay"></div>');
    const root = el(
      '<div class="sheet">' +
        '<div class="sheet__grip"></div>' +
        '<div class="sheet__head"><h2></h2><button class="sheet__x" aria-label="Закрыть">×</button></div>' +
        '<div class="sheet__body"></div>' +
        '<div class="sheet__foot" hidden></div>' +
      "</div>");
    const headEl = root.querySelector("h2");
    const bodyEl = root.querySelector(".sheet__body");
    const footEl = root.querySelector(".sheet__foot");
    headEl.textContent = title || "";
    if (bodyHtml) bodyEl.innerHTML = bodyHtml;

    function close() {
      overlay.classList.remove("show");
      document.body.style.overflow = "";
      setTimeout(function () { overlay.remove(); }, 200);
    }
    root.querySelector(".sheet__x").onclick = close;
    overlay.onclick = function (e) { if (e.target === overlay) close(); };

    overlay.appendChild(root);
    document.getElementById("sheet-root").appendChild(overlay);
    document.body.style.overflow = "hidden";
    requestAnimationFrame(function () { overlay.classList.add("show"); });

    return {
      root: root, overlay: overlay, foot: footEl, close: close,
      setTitle: function (t) { headEl.textContent = t || ""; },
      setBody: function (h) { bodyEl.innerHTML = h; bodyEl.scrollTop = 0; },
      setFoot: function (h) {
        // Callers either pass HTML or pass "" then append child buttons —
        // in both cases the footer should be shown.
        footEl.innerHTML = h || "";
        footEl.hidden = false;
      },
    };
  }

  /* ================= Boot ================= */
  paintAccount();
  paintCartBar();
  renderCatalog();
})();
