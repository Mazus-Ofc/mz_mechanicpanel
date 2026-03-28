const resourceName = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'mz_mechanicpanel';

const root = document.getElementById('root');
const sectionsArea = document.getElementById('sectionsArea');
const categoryTabs = document.getElementById('categoryTabs');
const statsGrid = document.getElementById('statsGrid');
const totalPrice = document.getElementById('totalPrice');
const subtotalPrice = document.getElementById('subtotalPrice');
const laborPrice = document.getElementById('laborPrice');
const vehicleLabel = document.getElementById('vehicleLabel');
const vehicleMeta = document.getElementById('vehicleMeta');
const ownerLabel = document.getElementById('ownerLabel');
const shopLabel = document.getElementById('shopLabel');
const waitingBadge = document.getElementById('waitingBadge');

const ownerApprovalModal = document.getElementById('ownerApprovalModal');
const approvalTitle = document.getElementById('approvalTitle');
const approvalSubtitle = document.getElementById('approvalSubtitle');
const approvalSubtotal = document.getElementById('approvalSubtotal');
const approvalLabor = document.getElementById('approvalLabor');
const approvalTotal = document.getElementById('approvalTotal');
const approvalLines = document.getElementById('approvalLines');

let state = {
  open: false,
  currency: '$',
  payload: null,
  activeCategory: null,
  currentState: {},
  quote: null,
  ownerRequestId: null,
  stats: { speed: 0, acceleration: 0, brakes: 0, traction: 0 },
};

const iconMap = {
  engine: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M4 10h4l2-3h4l2 3h4v6h-2l-2 2H8l-2-2H4z"/><path d="M7 16v2M17 16v2M12 7V4"/></svg>',
  paint: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M7 16a4 4 0 1 0 0-8h8a4 4 0 0 1 0 8"/><path d="M12 8V4"/></svg>',
  paint2: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M19 11c0 4-5 9-7 9s-7-5-7-9a7 7 0 0 1 14 0Z"/><circle cx="12" cy="11" r="2.5"/></svg>',
  wheel: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><circle cx="12" cy="12" r="8"/><circle cx="12" cy="12" r="3"/><path d="M12 4v5M12 15v5M4 12h5M15 12h5"/></svg>',
  wheel2: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><circle cx="12" cy="12" r="8"/><path d="M12 4l2.5 5.5L20 12l-5.5 2.5L12 20l-2.5-5.5L4 12l5.5-2.5L12 4Z"/></svg>',
  body: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M3 14h18l-2-5H5z"/><path d="M5 14v3h2v-3M17 14v3h2v-3"/></svg>',
  interior: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M7 18V8c0-2 2-3 5-3s5 1 5 3v10"/><path d="M7 13h10"/></svg>',
  brakes: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><circle cx="12" cy="12" r="8"/><path d="M9 9h6v6H9z"/></svg>',
  transmission: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M8 4v16M16 4v16M8 8h8M8 16h8"/></svg>',
  suspension: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M7 4v6l5 4 5-4V4"/><path d="M7 20v-6l5-4 5 4v6"/></svg>',
  turbo: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M5 12a7 7 0 1 1 14 0c0 4-3 7-7 7"/><path d="M12 12 9 6"/></svg>',
  armor: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M12 3 5 6v6c0 5 3.5 7.5 7 9 3.5-1.5 7-4 7-9V6z"/></svg>',
  neon: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M8 4h8l-4 7h5l-9 9 3-7H6z"/></svg>',
  xenon: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M5 12h6M7 9l4 3-4 3"/><path d="M13 8h6M15 5l4 3-4 3"/><path d="M13 16h6M15 13l4 3-4 3"/></svg>',
  extras: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M12 5v14M5 12h14"/><circle cx="12" cy="12" r="9"/></svg>',
  service: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M14 7a4 4 0 1 0-5.6 5.6L17 21l4-4-8.4-8.4A4 4 0 0 0 14 7z"/></svg>',
  repair: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M14 7a4 4 0 1 0-5.6 5.6L17 21l4-4-8.4-8.4A4 4 0 0 0 14 7z"/></svg>',
  repairfull: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M4 12h6"/><path d="M14 12h6"/><path d="M12 4v6"/><path d="M12 14v6"/><circle cx="12" cy="12" r="3"/></svg>',
  clean: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M7 18c0 1.1.9 2 2 2h6a2 2 0 0 0 2-2v-1H7z"/><path d="M6 10h12l-1 7H7z"/><path d="M9 4h6l1 3H8z"/></svg>',
  tire: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><circle cx="12" cy="12" r="8"/><circle cx="12" cy="12" r="3"/></svg>',
  tint: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M4 5h16v14H4z"/><path d="M8 5v14"/></svg>',
  plate: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><rect x="4" y="7" width="16" height="10" rx="2"/><path d="M8 11h8"/></svg>',
};

function icon(key) {
  return iconMap[key] || iconMap.engine;
}

function fmt(n) {
  return `${state.currency}${Number(n || 0).toLocaleString('pt-BR')}`;
}

function post(event, data = {}) {
  return fetch(`https://${resourceName}/${event}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data),
  }).then(r => r.json()).catch(() => ({}));
}

function renderStats(stats) {
  const defs = [
    ['Velocidade', stats.speed],
    ['Aceleração', stats.acceleration],
    ['Freios', stats.brakes],
    ['Controle', stats.traction],
  ];
  statsGrid.innerHTML = defs.map(([label, value]) => `
    <div class="stats-item">
      <label>${label}</label>
      <div class="stats-bar"><div class="stats-fill" style="width:${value}%"></div></div>
      <span class="stats-value">${value}%</span>
    </div>
  `).join('');
}

function setSummary(quote) {
  state.quote = quote || { subtotal: 0, labor: 0, total: 0, lines: [] };
  subtotalPrice.textContent = fmt(state.quote.subtotal);
  laborPrice.textContent = fmt(state.quote.labor);
  totalPrice.textContent = fmt(state.quote.total);
}

function eq(a, b) {
  return JSON.stringify(a) === JSON.stringify(b);
}

function renderTabs() {
  categoryTabs.innerHTML = '';
  state.payload.categories.forEach(category => {
    const btn = document.createElement('button');
    btn.className = `tab-btn ${state.activeCategory === category.key ? 'active' : ''}`;
    btn.innerHTML = `<span class="icon-badge">${icon(category.icon)}</span><span>${category.label}</span>`;
    btn.addEventListener('click', () => {
      state.activeCategory = category.key;
      renderTabs();
      renderSections();
    });
    categoryTabs.appendChild(btn);
  });
}

function isServiceFullActive() {
  return state.currentState?.service_full === true;
}

function renderSelectSection(section) {
  const current = state.currentState[section.key];
  const fullServiceActive = isServiceFullActive();
  const serviceDisabled = section.mode === 'serviceToggle' && fullServiceActive && section.key !== 'service_full';
  const options = section.options.map(option => {
    const active = eq(option.value, current);
    const colorStyle = option.hex ? `style="box-shadow: inset 0 0 0 999px ${option.hex}; border-color: rgba(255,255,255,0.12);"` : '';
    return `<button class="select-chip ${active ? 'active' : ''} ${serviceDisabled ? 'disabled' : ''}" ${serviceDisabled ? 'disabled' : ''} data-section="${section.key}" data-value='${encodeURIComponent(JSON.stringify(option.value))}'>
      ${option.hex ? `<span class="color-swatch" ${colorStyle}></span>` : ''}
      <span>${option.label}</span>
    </button>`;
  }).join('');

  const custom = section.allowCustomColor ? `
    <div class="custom-color-row">
      <input type="color" value="#00b7ff" data-custom="${section.key}" />
      <button class="small-btn" data-apply-custom="${section.key}">Aplicar cor personalizada</button>
    </div>
  ` : '';

  const serviceHint = section.mode === 'serviceToggle'
    ? `<div class="service-hint ${fullServiceActive && section.key !== 'service_full' ? 'warning' : ''}">${section.key === 'service_full' ? 'Selecionar reparo completo substitui os demais serviços.' : (fullServiceActive ? 'Desative o reparo completo para editar serviços individuais.' : 'Serviços individuais removem o reparo completo automaticamente.')}</div>`
    : '';

  return `<div class="section-body"><div class="select-row ${section.mode === 'serviceToggle' ? 'service-row' : ''}">${options}</div>${custom}${serviceHint}</div>`;
}

function renderExtrasSection(section) {
  const current = state.currentState[section.key] || {};
  return `<div class="section-body"><div class="extra-grid">${section.options.map(option => {
    const active = !!current[option.value];
    return `<button class="extra-chip ${active ? 'active' : ''}" data-extra-section="${section.key}" data-extra-id="${option.value}">${option.label}</button>`;
  }).join('')}</div></div>`;
}

function getDisplaySections(category) {
  const items = [...(category.items || [])];
  if (category.key === 'wheels') {
    const priority = {
      wheel_type: 0,
      wheels: 1,
      custom_tires: 2,
      bulletproof_tires: 3,
      tire_smoke: 4,
    };
    items.sort((a, b) => {
      const pa = priority[a.key] ?? 99;
      const pb = priority[b.key] ?? 99;
      if (pa !== pb) return pa - pb;
      return (a.label || '').localeCompare(b.label || '', 'pt-BR');
    });
  }
  if (category.key === 'service') {
    const priority = {
      service_full: 0,
      service_engine: 1,
      service_body: 2,
      service_tires: 3,
      service_clean: 4,
    };
    items.sort((a, b) => {
      const pa = priority[a.key] ?? 99;
      const pb = priority[b.key] ?? 99;
      if (pa !== pb) return pa - pb;
      return (a.label || '').localeCompare(b.label || '', 'pt-BR');
    });
  }
  return items;
}

function renderSections() {
  const category = state.payload.categories.find(c => c.key === state.activeCategory) || state.payload.categories[0];
  if (!category) return;
  const displaySections = getDisplaySections(category);
  sectionsArea.innerHTML = displaySections.map(section => {
    const body = section.mode === 'extras' ? renderExtrasSection(section) : renderSelectSection(section);
    return `
      <article class="section-card">
        <div class="section-head">
          <span class="icon-badge">${icon(section.icon)}</span>
          <div>
            <h3>${section.label}</h3>
            <p>${section.description}</p>
          </div>
        </div>
        ${body}
      </article>
    `;
  }).join('');

  bindSectionActions();
}

function bindSectionActions() {
  sectionsArea.querySelectorAll('[data-section]').forEach(button => {
    button.addEventListener('click', async () => {
      const sectionKey = button.dataset.section;
      const value = JSON.parse(decodeURIComponent(button.dataset.value));
      const resp = await post('previewChange', { sectionKey, value });
      if (resp && resp.ok) {
        state.currentState = resp.currentState || state.currentState;
        if (resp.categories) state.payload.categories = resp.categories;
        if (resp.stats) {
          state.stats = resp.stats;
          renderStats(resp.stats);
        }
        setSummary(resp.quote);
        renderSections();
      }
    });
  });

  sectionsArea.querySelectorAll('[data-extra-section]').forEach(button => {
    button.addEventListener('click', async () => {
      const sectionKey = button.dataset.extraSection;
      const value = button.dataset.extraId;
      const resp = await post('previewChange', { sectionKey, value });
      if (resp && resp.ok) {
        state.currentState = resp.currentState || state.currentState;
        if (resp.categories) state.payload.categories = resp.categories;
        if (resp.stats) {
          state.stats = resp.stats;
          renderStats(resp.stats);
        }
        setSummary(resp.quote);
        renderSections();
      }
    });
  });

  sectionsArea.querySelectorAll('[data-apply-custom]').forEach(button => {
    button.addEventListener('click', async () => {
      const sectionKey = button.dataset.applyCustom;
      const input = sectionsArea.querySelector(`input[data-custom="${sectionKey}"]`);
      if (!input) return;
      const resp = await post('previewChange', { sectionKey, value: { customHex: input.value } });
      if (resp && resp.ok) {
        state.currentState = resp.currentState || state.currentState;
        if (resp.categories) state.payload.categories = resp.categories;
        if (resp.stats) {
          state.stats = resp.stats;
          renderStats(resp.stats);
        }
        setSummary(resp.quote);
        renderSections();
      }
    });
  });
}

function openPanel(payload) {
  state.open = true;
  state.payload = payload;
  state.currency = payload.currency || '$';
  state.currentState = payload.currentState || {};
  state.activeCategory = payload.categories[0]?.key || null;
  state.stats = payload.stats || { speed: 0, acceleration: 0, brakes: 0, traction: 0 };
  vehicleLabel.textContent = payload.vehicleLabel;
  vehicleMeta.textContent = `Placa ${payload.plate}`;
  ownerLabel.textContent = payload.ownerLabel || 'Cliente';
  shopLabel.textContent = payload.shopLabel || 'Oficina';
  setSummary(payload.quote);
  renderStats(state.stats);
  renderTabs();
  renderSections();
  waitingBadge.classList.add('hidden');
  root.classList.remove('hidden');
}

function closePanel() {
  state.open = false;
  state.payload = null;
  root.classList.add('hidden');
}

function openOwnerApproval(payload) {
  state.ownerRequestId = payload.requestId;
  approvalTitle.textContent = payload.shopLabel || 'Oficina';
  approvalSubtitle.textContent = `${payload.mechanicName} quer aplicar alterações no veículo ${payload.plate}`;
  approvalSubtotal.textContent = fmt(payload.subtotal);
  approvalLabor.textContent = fmt(payload.labor);
  approvalTotal.textContent = fmt(payload.total);
  approvalLines.innerHTML = (payload.lines || []).map(line => `
    <div class="approval-line">
      <div>
        <strong>${line.label}</strong>
        <div class="muted">${line.description || ''}</div>
      </div>
      <strong>${fmt(line.total)}</strong>
    </div>
  `).join('');
  ownerApprovalModal.classList.remove('hidden');
}

function closeOwnerApproval() {
  state.ownerRequestId = null;
  ownerApprovalModal.classList.add('hidden');
}

window.addEventListener('message', (event) => {
  const { action, payload, quote, currentState } = event.data || {};
  if (action === 'openPanel') openPanel(payload);
  if (action === 'closePanel') closePanel();
  if (action === 'summary') {
    if (currentState) state.currentState = currentState;
    if (quote) setSummary(quote);
    if (event.data?.stats) {
      state.stats = event.data.stats;
      renderStats(state.stats);
    }
  }
  if (action === 'awaitingOwner') waitingBadge.classList.remove('hidden');
  if (action === 'ownerApprovalRequest') openOwnerApproval(payload);
  if (action === 'closeOwnerRequest') closeOwnerApproval();
});

document.getElementById('closeBtn').addEventListener('click', () => post('closePanel'));
document.getElementById('cancelBtn').addEventListener('click', () => post('closePanel'));
document.getElementById('finishBtn').addEventListener('click', () => post('finishOrder'));
document.getElementById('rotateLeftBtn').addEventListener('click', () => post('rotateCamera', { direction: 'left' }));
document.getElementById('rotateRightBtn').addEventListener('click', () => post('rotateCamera', { direction: 'right' }));
document.getElementById('zoomInBtn').addEventListener('click', () => post('zoomCamera', { delta: -1.6 }));
document.getElementById('zoomOutBtn').addEventListener('click', () => post('zoomCamera', { delta: 1.6 }));
document.getElementById('approvalAccept').addEventListener('click', () => {
  if (state.ownerRequestId) post('ownerApproval', { requestId: state.ownerRequestId, accepted: true });
});
document.getElementById('approvalDecline').addEventListener('click', () => {
  if (state.ownerRequestId) post('ownerApproval', { requestId: state.ownerRequestId, accepted: false });
});

document.addEventListener('keyup', (event) => {
  if (event.key === 'Escape') {
    if (state.open) post('closePanel');
    if (state.ownerRequestId) post('ownerApproval', { requestId: state.ownerRequestId, accepted: false });
  }
});
