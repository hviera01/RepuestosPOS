function dims(arch) {
  if (arch.startsWith('m_')) return [780, 1688];
  return [1440, 900];
}
const SIN_RECORTE = ['00_login.png', '01_inicio.png', '02_menu.png', 'inicio2.png', 'inicio_panel.png'];
const ZONAS = {
  'inv_ajustar.png': [460, 240, 520, 500],
  'inv_historial.png': [180, 170, 1070, 640],
  'inv_ticket_opciones.png': [500, 240, 440, 420],
  'inv_pdf_opciones.png': [460, 170, 520, 670],
  'promocion_nueva.png': [400, 108, 640, 792],
  'cliente_nuevo.png': [490, 250, 460, 510],
  'proveedor_nuevo.png': [480, 240, 440, 500],
  'caja_fondo_periodo.png': [430, 110, 570, 780],
  'caja_cerrar_lleno.png': [460, 260, 510, 460],
  'credito_abono.png': [450, 200, 530, 580],
  'venta_pendientes_impresion.png': [430, 140, 570, 650],
  'venta_ver_perdidas.png': [430, 190, 570, 600],
  'web_vista_previa_ticket.png': [370, 300, 690, 380],
  'venta_escanear_celular.png': [520, 250, 390, 480],
  'traslado_detalle.png': [430, 330, 570, 220],
  'venta_tipo_documento.png': [0, 150, 900, 450],
  'venta_metodo_pago.png': [700, 150, 740, 450],
  'inv_menu_fila.png': [700, 300, 740, 360],
  'credito_menu_fila.png': [800, 360, 640, 330],
};
const AJUSTE_X = {
  'promocion_nueva.png': () => 452,
  'cliente_nuevo.png': () => 545,
  'proveedor_nuevo.png': () => 528,
  'caja_fondo_periodo.png': (k) => (k.n === 5 ? k.x : 470),
  'caja_cerrar_lleno.png': (k) => (k.n === 5 ? k.x : 498),
  'credito_abono.png': (k) => (k.n === 7 ? k.x : 496),
  'inv_ajustar.png': (k) => (k.n === 5 ? k.x : 522),
  'inv_pdf_opciones.png': (k) => (k.n === 3 ? 825 : 490),
  'inv_ticket_opciones.png': (k) => (k.n === 2 ? 770 : 548),
  'web_vista_previa_ticket.png': () => 424,
  'venta_escanear_celular.png': (k) => (k.n === 3 ? 640 : 575),
};
function captura(arch, marcas = [], { recorte, ancho: anchoIn, zona } = {}) {
  let ancho = anchoIn;
  const [W, H] = dims(arch);
  let z = zona === false ? null : zona || ZONAS[arch] || null;
  if (!z) {
    const rec = recorte === undefined ? (arch.startsWith('m_') || SIN_RECORTE.includes(arch) ? 0 : 108) : recorte;
    z = [0, rec, W, H - rec];
  }
  const [zx, zy, zw, zh] = z;
  if (!ancho && zh / zw > 0.9) ancho = 110;
  const aj = AJUSTE_X[arch];
  const m = marcas
    .map((k0) => { const k = aj ? { ...k0, x: aj(k0) } : k0; return `<span class="marca-num" style="left:${((k.x - zx) / zw) * 100}%;top:${((k.y - zy) / zh) * 100}%">${k.n}</span>`; })
    .join('');
  const estilo = `aspect-ratio:${zw}/${zh};${ancho ? `width:${ancho}mm;` : ''}`;
  const img = `width:${(W / zw) * 100}%;max-width:none;margin-left:-${(zx / zw) * 100}%;margin-top:-${(zy / zw) * 100}%`;
  return `<div class="cap ${ancho ? 'cap-movil' : ''}" style="${estilo}"><img src="capturas/${arch}" style="${img}">${m}</div>`;
}
function parMovil(items) {
  return `<div class="par-movil">${items.map(([a, m, ancho]) => captura(a, m || [], { ancho: ancho || 58 })).join('')}</div>`;
}
module.exports = { captura, parMovil };
