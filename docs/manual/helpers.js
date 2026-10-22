const MODULOS = [
  ['Usuarios', []],
  ['Mantenedor', ['Categorías', 'Inventario', 'Auditoría de Inventario', 'Pendientes de Reposición', 'Configuración', 'Dispositivos', 'Descuentos y Promociones']],
  ['Ventas', ['Registrar Venta', 'Ver Detalle']],
  ['Compras', ['Registrar Compra', 'Ver Detalle', 'Hacer Pedido']],
  ['Clientes', []],
  ['Proveedores', []],
  ['Sucursales', []],
  ['Traslados', ['Registrar Traslado', 'Ver Detalle']],
  ['Créditos', ['Ventas Crédito', 'Compras Crédito']],
  ['Reportes', ['Reporte de Ventas', 'Reporte de Compras', 'Traslados', 'Reporte Financiero', 'Caja', 'Ingresos-Egresos']],
];

function menuLateral(modulo, sub) {
  return MODULOS.map(([m, subs]) => {
    const abierto = m === modulo;
    let h = `<div class="${abierto && !sub ? 'act' : ''}">${m}</div>`;
    if (abierto && subs.length) {
      h += subs.map((s) => `<div class="sub ${s === sub ? 'act' : ''}">${s}</div>`).join('');
    }
    return h;
  }).join('');
}

function marcas(lista) {
  return (lista || []).map((m) => `<span class="marca-num" style="left:${m.x}%;top:${m.y}%">${m.n}</span>`).join('');
}

function pantalla({ modulo, sub, titulo, html, marcas: ms, alto }) {
  return `
  <div class="pantalla">
    <div class="barra"><span>Repuestos POS</span><span>${titulo || sub || modulo || ''}</span><span>Administrador ▾</span></div>
    <div class="cuerpo" style="${alto ? `min-height:${alto}mm` : ''}">
      <div class="menu">${menuLateral(modulo, sub)}</div>
      <div class="contenido">${html}</div>
    </div>
    ${marcas(ms)}
  </div>`;
}

function pantallaSola({ html, marcas: ms, alto, titulo }) {
  return `
  <div class="pantalla">
    <div class="barra"><span>Repuestos POS</span><span>${titulo || ''}</span><span></span></div>
    <div class="cuerpo" style="${alto ? `min-height:${alto}mm` : ''}"><div class="contenido">${html}</div></div>
    ${marcas(ms)}
  </div>`;
}

const campo = (etq, val) => `<div class="campo ${val ? 'lleno' : ''}"><b>${etq}</b>${val || ''}</div>`;
const btn = (t, tipo = '') => `<span class="btn ${tipo}">${t}</span>`;
const chip = (t, tipo = '') => `<span class="chip ${tipo}">${t}</span>`;
const kpi = (t, v) => `<div class="kpi"><small>${t}</small><b>${v}</b></div>`;

function tabla(cols, filas, numericas = []) {
  return `<table class="mini"><thead><tr>${cols.map((c, i) => `<th class="${numericas.includes(i) ? 'num' : ''}">${c}</th>`).join('')}</tr></thead><tbody>${filas
    .map((f) => `<tr>${f.map((c, i) => `<td class="${numericas.includes(i) ? 'num' : ''}">${c}</td>`).join('')}</tr>`)
    .join('')}</tbody></table>`;
}

function figura(contenido, pie, leyenda) {
  let h = `<div class="figura">${contenido}<div class="pie">${pie}</div></div>`;
  if (leyenda && leyenda.length) h += `<ol class="leyenda">${leyenda.map((l) => `<li><span>${l}</span></li>`).join('')}</ol>`;
  return '<div class="bloque-fig">' + h + '</div>';
}

const aviso = (t, titulo = 'Importante') => `<div class="aviso"><b>${titulo}</b>${t}</div>`;
const consejo = (t, titulo = 'Consejo') => `<div class="consejo"><b>${titulo}</b>${t}</div>`;
const cuidado = (t, titulo = 'Cuidado') => `<div class="cuidado"><b>${titulo}</b>${t}</div>`;

function pasos(lista) {
  return lista.map((p, i) => {
    const [t, d] = Array.isArray(p) ? p : [p, ''];
    return `<div class="paso"><div class="n">${i + 1}</div><div class="t"><b>${t}</b>${d}</div></div>`;
  }).join('');
}

function datos(cols, filas) {
  return `<table class="datos"><thead><tr>${cols.map((c) => `<th>${c}</th>`).join('')}</tr></thead><tbody>${filas
    .map((f) => `<tr>${f.map((c) => `<td>${c}</td>`).join('')}</tr>`)
    .join('')}</tbody></table>`;
}

const ENGRANAJE = `<svg class="engranaje" viewBox="-50 -50 100 100"><g fill="#fff">${Array.from({ length: 10 }, (_, i) => `<rect x="-5.5" y="-47" width="11" height="22" transform="rotate(${i * 36})"/>`).join('')}<circle r="31"/></g><circle r="14" fill="#303846"/></svg>`;

module.exports = { pantalla, pantallaSola, campo, btn, chip, kpi, tabla, figura, aviso, consejo, cuidado, pasos, datos, ENGRANAJE };
