'use strict';

/* ============================================================
   Aziza Food — Courier SPA (vanilla JS, no build step)
   ============================================================ */

// ---- API base resolution -------------------------------------------------
// Allow ?api=<url> to override and persist for local testing against live API.
(function captureApiOverride() {
  try {
    const qs = new URLSearchParams(location.search);
    const api = qs.get('api');
    if (api) localStorage.setItem('aziza_api', api);
  } catch (_) { /* ignore */ }
})();

const API_BASE = (window.API_BASE || localStorage.getItem('aziza_api') || '/api/v1')
  .replace(/\/+$/, '');

const TOKEN_KEY = 'aziza_courier_token';
const NAME_KEY = 'aziza_courier_name';
const POLL_MS = 20000;

// ---- Tiny state ----------------------------------------------------------
let pollTimer = null;
let inFlight = false; // guards overlapping refreshes

// ---- DOM refs ------------------------------------------------------------
const $ = (id) => document.getElementById(id);
const loginScreen = $('login');
const boardScreen = $('board');
const loginForm = $('login-form');
const loginError = $('login-error');
const loginBtn = $('login-btn');
const feedEl = $('feed');

// ---- Helpers -------------------------------------------------------------
function escapeHtml(value) {
  if (value === null || value === undefined) return '';
  return String(value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

function getToken() { return localStorage.getItem(TOKEN_KEY); }
function setToken(t) { localStorage.setItem(TOKEN_KEY, t); }
function clearToken() {
  localStorage.removeItem(TOKEN_KEY);
  localStorage.removeItem(NAME_KEY);
}

function fmtTenge(minor) {
  const n = Math.round((Number(minor) || 0) / 100);
  return n.toLocaleString('ru-RU') + ' ₸';
}

function fmtTime(iso) {
  if (!iso) return '';
  const d = new Date(iso);
  if (isNaN(d.getTime())) return '';
  return d.toLocaleString('ru-RU', {
    day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit',
  });
}

const STATUS_RU = {
  pending: 'Новый',
  confirmed: 'Подтверждён',
  preparing: 'Готовится',
  courier_assigned: 'Назначен',
  in_transit: 'В пути',
  delivered: 'Доставлен',
  cancelled: 'Отменён',
};

const PAYMENT_RU = {
  cash: 'Наличные',
  card_online: 'Картой онлайн',
  kaspi: 'Kaspi',
  halyk: 'Halyk',
  apple_pay: 'Apple Pay',
  google_pay: 'Google Pay',
};

function statusLabel(s) { return STATUS_RU[s] || s || '—'; }
function paymentLabel(p) { return PAYMENT_RU[p] || p || '—'; }

// ---- Toasts --------------------------------------------------------------
function toast(message, kind) {
  const root = $('toast-root');
  if (!root) return;
  const el = document.createElement('div');
  el.className = 'toast' + (kind ? ' toast--' + kind : '');
  el.textContent = message;
  root.appendChild(el);
  setTimeout(() => {
    el.style.transition = 'opacity .25s';
    el.style.opacity = '0';
    setTimeout(() => el.remove(), 260);
  }, 3200);
}

// ---- API layer -----------------------------------------------------------
async function api(path, { method = 'GET', body, auth = true } = {}) {
  const headers = { 'Accept': 'application/json' };
  if (body !== undefined) headers['Content-Type'] = 'application/json';
  if (auth) {
    const t = getToken();
    if (t) headers['Authorization'] = 'Bearer ' + t;
  }

  let res;
  try {
    res = await fetch(API_BASE + path, {
      method,
      headers,
      body: body !== undefined ? JSON.stringify(body) : undefined,
    });
  } catch (networkErr) {
    const e = new Error('Нет связи с сервером');
    e.network = true;
    throw e;
  }

  // 401 -> session is dead. Bail to login (skip for the login call itself).
  if (res.status === 401 && auth) {
    handleUnauthorized();
    const e = new Error('Сессия истекла');
    e.status = 401;
    throw e;
  }

  let data = null;
  const text = await res.text();
  if (text) {
    try { data = JSON.parse(text); } catch (_) { data = null; }
  }

  if (!res.ok) {
    const detail = data && data.detail ? data.detail : ('Ошибка ' + res.status);
    const e = new Error(typeof detail === 'string' ? detail : 'Ошибка запроса');
    e.status = res.status;
    e.data = data;
    throw e;
  }
  return data;
}

// ---- Auth flow -----------------------------------------------------------
function handleUnauthorized() {
  clearToken();
  stopPolling();
  showLogin();
}

async function doLogin(phone, password) {
  // auth:false so a bad login shows the inline error instead of bouncing.
  const data = await api('/auth/login', {
    method: 'POST',
    body: { phone, password },
    auth: false,
  });

  const user = data && data.user;
  if (!user || user.role !== 'courier') {
    const e = new Error('Этот вход только для курьеров');
    e.role = true;
    throw e;
  }
  setToken(data.access_token);
  if (user.name) localStorage.setItem(NAME_KEY, user.name);
  else localStorage.setItem(NAME_KEY, user.phone || 'Курьер');
}

// ---- Screen switching ----------------------------------------------------
function showLogin() {
  boardScreen.hidden = true;
  loginScreen.hidden = false;
  loginError.hidden = true;
  if (loginBtn) { loginBtn.disabled = false; loginBtn.textContent = 'Войти'; }
}

function showBoard() {
  loginScreen.hidden = true;
  boardScreen.hidden = false;
  const nameEl = $('courier-name');
  if (nameEl) nameEl.textContent = localStorage.getItem(NAME_KEY) || 'Курьер';
  feedEl.innerHTML = '<div class="feed__loading">Загрузка…</div>';
  refresh();
  startPolling();
}

// ---- Polling -------------------------------------------------------------
function startPolling() {
  stopPolling();
  pollTimer = setInterval(() => { refresh({ silent: true }); }, POLL_MS);
}
function stopPolling() {
  if (pollTimer) { clearInterval(pollTimer); pollTimer = null; }
}

// ---- Rendering -----------------------------------------------------------
function mapsLink(address) {
  if (!address) return null;
  const lat = Number(address.lat);
  const lng = Number(address.lng);
  if (isFinite(lat) && isFinite(lng) && (lat !== 0 || lng !== 0)) {
    return 'https://maps.google.com/?q=' + lat + ',' + lng;
  }
  const text = addressText(address);
  if (!text) return null;
  return 'https://maps.google.com/?q=' + encodeURIComponent(text);
}

function addressText(address) {
  if (!address) return '';
  if (typeof address === 'string') return address;
  const main = [];
  if (address.street) main.push(address.street);
  if (address.building) main.push('д. ' + address.building);
  const extra = [];
  if (address.apt) extra.push('кв. ' + address.apt);
  if (address.entrance) extra.push('подъезд ' + address.entrance);
  if (address.floor) extra.push('этаж ' + address.floor);
  let line = main.join(', ');
  if (extra.length) line += (line ? ', ' : '') + extra.join(', ');
  return line;
}

function clientName(order) {
  if (order.client && order.client.name) return order.client.name;
  if (order.client_name) return order.client_name;
  return 'Клиент';
}

function clientPhone(order) {
  if (order.client && order.client.phone) return order.client.phone;
  if (order.client_phone) return order.client_phone;
  return null;
}

function telHref(phone) {
  return 'tel:' + String(phone).replace(/[^\d+]/g, '');
}

function renderItems(items) {
  if (!Array.isArray(items) || !items.length) return '';
  const rows = items.map((it) => {
    const label = escapeHtml(it.variant_label || 'Позиция');
    const qty = Number(it.qty) || 1;
    return (
      '<div class="item">' +
        '<span class="item__name"><span class="item__qty">' + qty + '×</span> ' + label + '</span>' +
        '<span class="item__sum">' + escapeHtml(fmtTenge(it.total_minor)) + '</span>' +
      '</div>'
    );
  }).join('');
  return '<div class="items">' + rows + '</div>';
}

function renderActions(order, kind) {
  if (kind === 'available') {
    return '<div class="card__actions">' +
      '<button class="btn btn--primary" data-action="take" data-id="' + escapeHtml(order.id) + '">Взять заказ</button>' +
    '</div>';
  }
  if (kind === 'mine') {
    const id = escapeHtml(order.id);
    let btns = '';
    if (order.status === 'courier_assigned') {
      btns += '<button class="btn btn--info" data-action="status" data-status="in_transit" data-id="' + id + '">В пути</button>';
    }
    // Allow marking delivered from either assigned or in_transit.
    btns += '<button class="btn btn--ok" data-action="status" data-status="delivered" data-id="' + id + '">Доставлен</button>';
    return '<div class="card__actions">' + btns + '</div>';
  }
  return '';
}

function orderCard(order, kind) {
  const status = order.status || '';
  const phone = clientPhone(order);
  const addr = order.address;
  const addrStr = addressText(addr);
  const link = mapsLink(addr);
  const addrComment = addr && typeof addr === 'object' && addr.comment ? addr.comment : '';
  const paid = order.payment_status === 'paid';
  const payCls = paid ? '' : ' card__pay--unpaid';
  const payText = paymentLabel(order.payment_method) + (paid ? ' · оплачен' : '');

  let html = '<article class="card' + (kind === 'done' ? ' card--done' : '') + '">';

  // top: code + status badge
  html += '<div class="card__top">' +
    '<div>' +
      '<div class="card__code">' + escapeHtml(order.code || ('#' + String(order.id).slice(0, 6))) + '</div>' +
      '<div class="card__time">' + escapeHtml(fmtTime(order.created_at)) + '</div>' +
    '</div>' +
    '<span class="badge badge--' + escapeHtml(status) + '">' + escapeHtml(statusLabel(status)) + '</span>' +
  '</div>';

  // total + payment
  html += '<div class="card__total">' +
    '<span class="card__total-amt">' + escapeHtml(fmtTenge(order.total_minor)) + '</span>' +
    '<span class="card__pay' + payCls + '">' + escapeHtml(payText) + '</span>' +
  '</div>';

  // client + address
  html += '<div class="card__client">' +
    '<div class="card__client-name">' + escapeHtml(clientName(order)) + '</div>';
  if (addrStr) html += '<div class="card__addr">' + escapeHtml(addrStr) + '</div>';
  if (addrComment) html += '<div class="card__addr-comment">' + escapeHtml(addrComment) + '</div>';
  html += '</div>';

  // contact buttons
  const contacts = [];
  if (phone) {
    contacts.push('<a class="btn btn--outline btn--sm" href="' + escapeHtml(telHref(phone)) + '">📞 Позвонить</a>');
  }
  if (link) {
    contacts.push('<a class="btn btn--outline btn--sm" href="' + escapeHtml(link) + '" target="_blank" rel="noopener">📍 Карта</a>');
  }
  if (contacts.length) html += '<div class="card__contact">' + contacts.join('') + '</div>';

  // items
  html += renderItems(order.items);

  // order comment (delivery note from client)
  if (order.comment) {
    html += '<div class="card__comment">' + escapeHtml(order.comment) + '</div>';
  }

  // actions
  html += renderActions(order, kind);

  html += '</article>';
  return html;
}

function sectionBlock(opts) {
  const { id, title, list, kind, modifier, collapsed } = opts;
  const arr = Array.isArray(list) ? list : [];
  let head = '<div class="section__head">' +
    '<span class="section__title">' + escapeHtml(title) + '</span>' +
    '<span class="section__count">' + arr.length + '</span>';
  if (kind === 'done') {
    head += '<button class="section__toggle" data-toggle="' + id + '">' +
      (collapsed ? 'Показать' : 'Скрыть') + '</button>';
  }
  head += '</div>';

  let body;
  if (kind === 'done' && collapsed) {
    body = '';
  } else if (!arr.length) {
    body = '<div class="section__empty">' +
      (kind === 'available' ? 'Нет свободных заказов' :
       kind === 'mine' ? 'У вас нет активных заказов' :
       'Пока нет доставленных') + '</div>';
  } else {
    body = '<div class="section__list">' +
      arr.map((o) => orderCard(o, kind)).join('') + '</div>';
  }

  return '<section class="section' + (modifier ? ' ' + modifier : '') +
    '" id="' + id + '">' + head + body + '</section>';
}

// keep "done" collapsed state across re-renders
let doneCollapsed = true;

function renderFeed(data) {
  const available = (data && data.available) || [];
  const mine = (data && data.mine) || [];
  const done = (data && data.done) || [];

  feedEl.innerHTML =
    sectionBlock({ id: 'sec-available', title: 'Свободные', list: available, kind: 'available' }) +
    sectionBlock({ id: 'sec-mine', title: 'Мои', list: mine, kind: 'mine' }) +
    sectionBlock({ id: 'sec-done', title: 'Доставлены', list: done, kind: 'done',
      modifier: 'section--done', collapsed: doneCollapsed });
}

// ---- Data actions --------------------------------------------------------
async function refresh(opts = {}) {
  if (inFlight) return;
  if (!getToken()) { handleUnauthorized(); return; }
  inFlight = true;
  const btn = $('refresh-btn');
  if (btn && !opts.silent) btn.classList.add('is-spinning');
  try {
    const data = await api('/courier/orders');
    renderFeed(data);
  } catch (err) {
    if (err.status === 401) return; // already handled
    if (!opts.silent) {
      if (feedEl.querySelector('.feed__loading')) {
        feedEl.innerHTML = '<div class="feed__error">' +
          escapeHtml(err.message || 'Не удалось загрузить заказы') + '</div>';
      }
      toast(err.message || 'Ошибка обновления', 'error');
    }
  } finally {
    inFlight = false;
    if (btn) btn.classList.remove('is-spinning');
  }
}

async function takeOrder(id, btn) {
  if (btn) btn.disabled = true;
  try {
    await api('/courier/orders/' + encodeURIComponent(id) + '/take', { method: 'POST' });
    toast('Заказ взят', 'ok');
    await refresh();
  } catch (err) {
    if (err.status === 401) return;
    if (err.status === 409) {
      toast('Заказ уже взят', 'error');
      await refresh();
    } else {
      toast(err.message || 'Не удалось взять заказ', 'error');
      if (btn) btn.disabled = false;
    }
  }
}

async function setStatus(id, status, btn) {
  if (btn) btn.disabled = true;
  try {
    await api('/courier/orders/' + encodeURIComponent(id) + '/status', {
      method: 'POST',
      body: { status },
    });
    toast(status === 'delivered' ? 'Заказ доставлен' : 'Статус: В пути', 'ok');
    await refresh();
  } catch (err) {
    if (err.status === 401) return;
    toast(err.message || 'Не удалось изменить статус', 'error');
    if (btn) btn.disabled = false;
  }
}

// ---- Event wiring --------------------------------------------------------
loginForm.addEventListener('submit', async (e) => {
  e.preventDefault();
  const phone = $('login-phone').value.trim();
  const password = $('login-password').value;
  loginError.hidden = true;
  if (!phone || !password) {
    loginError.textContent = 'Введите телефон и пароль';
    loginError.hidden = false;
    return;
  }
  loginBtn.disabled = true;
  loginBtn.textContent = 'Вход…';
  try {
    await doLogin(phone, password);
    showBoard();
  } catch (err) {
    let msg;
    if (err.role) msg = err.message;
    else if (err.status === 401) msg = 'Неверный телефон или пароль';
    else if (err.network) msg = 'Нет связи с сервером';
    else msg = err.message || 'Не удалось войти';
    loginError.textContent = msg;
    loginError.hidden = false;
    loginBtn.disabled = false;
    loginBtn.textContent = 'Войти';
  }
});

$('logout-btn').addEventListener('click', () => {
  clearToken();
  stopPolling();
  $('login-password').value = '';
  showLogin();
});

$('refresh-btn').addEventListener('click', () => refresh());

// Delegated clicks for order actions + section toggle.
feedEl.addEventListener('click', (e) => {
  const toggle = e.target.closest('[data-toggle]');
  if (toggle) {
    doneCollapsed = !doneCollapsed;
    refresh({ silent: true });
    return;
  }
  const btn = e.target.closest('[data-action]');
  if (!btn) return;
  const action = btn.getAttribute('data-action');
  const id = btn.getAttribute('data-id');
  if (!id) return;
  if (action === 'take') takeOrder(id, btn);
  else if (action === 'status') setStatus(id, btn.getAttribute('data-status'), btn);
});

// Refresh when tab becomes visible again (catches up after sleep).
document.addEventListener('visibilitychange', () => {
  if (!document.hidden && !boardScreen.hidden) refresh({ silent: true });
});

// ---- Boot ----------------------------------------------------------------
(function boot() {
  if (getToken()) showBoard();
  else showLogin();
})();
