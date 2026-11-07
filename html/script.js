const $ = id => document.getElementById(id);
const res = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'rsg-lawman';
const post = (cb, data = {}) => fetch(`https://${res}/${cb}`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(data) }).catch(() => {});
let mode = null;

function esc(s) { const d = document.createElement('div'); d.textContent = s ?? ''; return d.innerHTML; }
function hideAll() { $('root').classList.add('hidden'); $('menu').classList.add('hidden'); $('input').classList.add('hidden'); mode = null; }

function openMenu(d) {
  $('menu-title').textContent = d.title || '';
  $('menu-sub').textContent = d.subtitle || '';
  const list = $('menu-list'); list.innerHTML = '';
  (d.options || []).forEach(o => {
    const row = document.createElement('div');
    row.className = 'row' + (o.disabled ? ' disabled' : '');
    row.innerHTML = `<div class="badge-icon"><i class="${esc(o.icon || 'fa-solid fa-star')}"></i></div>
      <div class="row-text"><div class="row-title">${esc(o.title)}</div>${o.description ? `<div class="row-desc">${esc(o.description)}</div>` : ''}</div>
      <i class="fa-solid fa-chevron-right row-arrow"></i>`;
    if (!o.disabled) row.addEventListener('click', () => { hideAll(); post('menuSelect', { id: o.id }); });
    list.appendChild(row);
  });
  $('root').classList.remove('hidden'); $('menu').classList.remove('hidden'); mode = 'menu';
}

function openInput(d) {
  $('input-title').textContent = d.title || '';
  $('input-label').textContent = d.label || '';
  $('input-confirm').textContent = d.confirm || 'Confirm';
  $('input-cancel').textContent = d.cancel || 'Cancel';
  const i = $('input-value'); i.value = ''; i.classList.remove('err');
  $('root').classList.remove('hidden'); $('input').classList.remove('hidden'); mode = 'input';
  setTimeout(() => i.focus(), 50);
}

function confirmInput() {
  const i = $('input-value'); const v = parseInt(i.value, 10);
  if (!Number.isInteger(v) || v <= 0 || String(v) !== i.value.trim()) { i.classList.add('err'); return; }
  hideAll(); post('inputSubmit', { value: v });
}
function cancel() { const m = mode; hideAll(); post(m === 'input' ? 'inputSubmit' : 'close', { value: null }); }

$('menu-close').addEventListener('click', cancel);
$('input-cancel').addEventListener('click', cancel);
$('input-confirm').addEventListener('click', confirmInput);
$('input-value').addEventListener('input', e => { e.target.value = e.target.value.replace(/[^0-9]/g, ''); e.target.classList.remove('err'); });
document.addEventListener('keydown', e => {
  if (!mode) return;
  if (e.key === 'Escape') cancel();
  else if (e.key === 'Enter' && mode === 'input') confirmInput();
});
window.addEventListener('message', e => {
  const d = e.data || {};
  if (d.action === 'openMenu') openMenu(d);
  else if (d.action === 'openInput') openInput(d);
  else if (d.action === 'close') hideAll();
});
