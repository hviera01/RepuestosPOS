(function () {
  const M = window.MANUAL;
  const app = document.getElementById('app');

  const norm = (s) => s.toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '').replace(/ñ/g, 'n');
  const palabras = (s) => norm(s).split(/[^a-z0-9]+/).filter((w) => w.length > 1);
  const esc = (s) => s.replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));

  const GRUPOS = [
    'crear nuevo nueva agregar anadir registrar alta hacer generar abrir',
    'editar modificar cambiar corregir actualizar arreglar poner',
    'eliminar borrar quitar anular cancelar desactivar bloquear',
    'usuario usuarios empleado cajero vendedor trabajador persona encargado administrador',
    'producto productos repuesto repuestos articulo item inventario mercaderia pieza',
    'venta ventas vender factura facturar cobrar facturas',
    'compra compras comprar',
    'reporte reportes informe informes estadistica estadisticas resumen listado',
    'precio precios costo costos valor tarifa',
    'existencia existencias stock cantidad unidades',
    'imprimir impresora impresion ticket recibo papel imprime',
    'caja cierre cierra corte apertura efectivo gaveta arqueo turno',
    'credito creditos abono abonos deuda fiado saldo pagar cobro cuenta',
    'clave contrasena password pin acceso codigo',
    'cliente clientes comprador',
    'proveedor proveedores',
    'traslado traslados sucursal sucursales mover transferir bodega enviar',
    'gasto gastos egreso egresos pago salida',
    'celular telefono movil tableta tablet android iphone',
    'vehiculo vehiculos carro carros auto marca modelo ano',
    'descuento descuentos promocion promociones oferta rebaja',
    'logo logotipo imagen foto',
    'configuracion configurar ajustes negocio empresa datos',
    'refrescar recargar actualizar version vieja cache',
    'problema falla error funciona',
  ].map((g) => g.split(' '));
  const SIN = {};
  GRUPOS.forEach((g, i) => g.forEach((w) => { (SIN[w] = SIN[w] || []).push(i); }));
  const expandir = (t) => {
    const r = new Set([t]);
    (SIN[t] || []).forEach((i) => GRUPOS[i].forEach((w) => r.add(w)));
    return [...r];
  };

  const lev = (a, b, max) => {
    if (Math.abs(a.length - b.length) > max) return max + 1;
    let prev = Array.from({ length: b.length + 1 }, (_, i) => i);
    for (let i = 1; i <= a.length; i++) {
      const cur = [i];
      let min = i;
      for (let j = 1; j <= b.length; j++) {
        const v = Math.min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (a[i - 1] === b[j - 1] ? 0 : 1));
        cur.push(v);
        if (v < min) min = v;
      }
      if (min > max) return max + 1;
      prev = cur;
    }
    return prev[b.length];
  };
  const prefijoComun = (a, b) => { let i = 0; while (i < a.length && i < b.length && a[i] === b[i]) i++; return i; };
  const parecido = (q, w, difuso) => {
    if (q === w) return 1;
    const menor = Math.min(q.length, w.length);
    if (menor >= 3 && (w.startsWith(q) || q.startsWith(w))) return 0.85;
    if (menor >= 5 && prefijoComun(q, w) >= (menor >= 6 ? 5 : 4)) return 0.7;
    if (difuso && q.length >= 4) {
      const max = q.length >= 8 ? 2 : 1;
      if (lev(q, w, max) <= max) return 0.55;
    }
    return 0;
  };

  const docs = [];
  M.guias.forEach((g) => {
    const pasosTxt = g.pasos.join(' ').replace(/<[^>]+>/g, ' ');
    docs.push({ tipo: 'g', id: g.id, titulo: g.titulo, sub: '', tw: palabras(g.titulo), kw: palabras(g.palabras), bw: palabras(pasosTxt), texto: pasosTxt, bonus: 4 });
  });
  M.articulos.forEach((a) => {
    docs.push({ tipo: 'a', id: a.id, titulo: a.titulo, sub: a.capTitulo, tw: palabras(a.titulo + ' ' + a.capTitulo), kw: palabras(a.claves), bw: palabras(a.texto), texto: a.texto, bonus: 0 });
  });

  const mejor = (q, lista, difuso) => {
    let m = 0;
    for (let i = 0; i < lista.length; i++) {
      const s = parecido(q, lista[i], difuso);
      if (s > m) { m = s; if (m === 1) break; }
    }
    return m;
  };

  function puntuar(doc, tokens) {
    let total = 0, cubiertos = 0;
    for (const alts of tokens) {
      let mejorT = 0;
      for (let k = 0; k < alts.length; k++) {
        const q = alts[k];
        const penal = k === 0 ? 1 : 0.8;
        const st = mejor(q, doc.tw, true) * 10;
        const sk = mejor(q, doc.kw, true) * 5;
        const sb = mejor(q, doc.bw, false) * 2;
        const s = Math.max(st, sk, sb) * penal;
        if (s > mejorT) mejorT = s;
      }
      if (mejorT > 0) cubiertos++;
      total += mejorT;
    }
    if (!cubiertos) return 0;
    const faltan = tokens.length - cubiertos;
    if (tokens.length > 1 && cubiertos < Math.ceil(tokens.length / 2)) return 0;
    return total * (1 - 0.25 * faltan) + doc.bonus;
  }

  function buscar(texto) {
    const base = palabras(texto);
    const stop = new Set(['como', 'para', 'por', 'una', 'uno', 'los', 'las', 'del', 'que', 'con', 'quiero', 'puedo', 'donde', 'se', 'de', 'el', 'la', 'en', 'un', 'mi', 'es']);
    let toks = base.filter((w) => !stop.has(w));
    if (!toks.length) toks = base;
    if (!toks.length) return [];
    const tokens = toks.map(expandir);
    const res = [];
    for (const d of docs) {
      const s = puntuar(d, tokens);
      if (s > 0) res.push({ d, s });
    }
    res.sort((a, b) => b.s - a.s);
    const tope = res.length ? res[0].s * 0.35 : 0;
    return { lista: res.filter((x) => x.s >= tope).slice(0, 25), toks };
  }

  function marcar(texto, toks) {
    const alts = [...new Set(toks.flatMap(expandir))].filter((x) => x.length > 2).sort((x, y) => y.length - x.length);
    const tn = norm(texto);
    const trozos = [];
    for (const a of alts) {
      let p = tn.indexOf(a);
      while (p >= 0) { trozos.push([p, p + a.length]); p = tn.indexOf(a, p + a.length); }
    }
    trozos.sort((x, y) => x[0] - y[0]);
    let out = '', last = 0;
    for (const [x, y] of trozos) {
      if (x < last) continue;
      out += esc(texto.substring(last, x)) + '<mark>' + esc(texto.substring(x, y)) + '</mark>';
      last = y;
    }
    return out + esc(texto.substring(last));
  }
  function resaltar(texto, toks) {
    const t = norm(texto);
    const alts = [...new Set(toks.flatMap(expandir))].filter((x) => x.length > 2);
    let i = -1;
    for (const a of alts) {
      const p = t.indexOf(a);
      if (p >= 0 && (i < 0 || p < i)) i = p;
    }
    const ini = Math.max(0, (i < 0 ? 0 : i) - 50);
    const frag = texto.substring(ini, ini + 170);
    return (ini > 0 ? '… ' : '') + marcar(frag, toks) + (ini + 170 < texto.length ? ' …' : '');
  }
  const marcarTitulo = (titulo, toks) => marcar(titulo, toks);

  const porId = {};
  M.guias.forEach((g) => (porId['g/' + g.id] = g));
  M.articulos.forEach((a) => (porId['a/' + a.id] = a));
  const EJEMPLOS = ['crear usuario', 'cambiar un precio', 'abrir la caja', 'hacer una venta', 'imprimir desde el celular', 'ver las ventas del día', 'cobrar un abono', 'registrar una compra'];

  function cajaBusqueda(valor) {
    return `<div class="buscador ${valor ? 'con-texto' : ''}"><input id="q" type="search" autocomplete="off" spellcheck="false" placeholder="Escriba lo que quiere hacer o ver…" value="${esc(valor || '')}" aria-label="Buscar en el manual"><button type="button" aria-label="Borrar" id="borrar">×</button></div>`;
  }

  function vistaInicio() {
    const g = (id) => M.guias.find((x) => x.id === id);
    const tarjetas = M.basicos.map((id) => g(id)).map((x) => `<a class="tarjeta" href="#/g/${x.id}"><b>${esc(x.titulo)}</b><span>${x.pasos[0].replace(/<[^>]+>/g, '').replace(/.$/, '').substring(0, 80)}</span></a>`).join('');
    const todas = M.guias.map((x) => `<a class="item" href="#/g/${x.id}"><span class="t">${esc(x.titulo)}</span></a>`).join('');
    const caps = M.capitulos.map((c) => {
      const arts = M.articulos.filter((a) => a.cap === c.n);
      return `<details class="cap-ind"><summary><span class="n">${c.n}</span>${esc(c.titulo)}</summary><div class="sub">${arts.map((a) => `<a href="#/a/${a.id}">${esc(a.titulo)}</a>`).join('')}</div></details>`;
    }).join('');
    app.innerHTML = `
      <section class="hero"><h1>¿Qué necesita hacer?</h1><p>Escriba con sus palabras, por ejemplo «${EJEMPLOS[0]}». La lista se filtra mientras escribe.</p>
        ${cajaBusqueda('')}
        <div class="atajos">${EJEMPLOS.slice(0, 6).map((e) => `<button type="button" data-q="${esc(e)}">${esc(e)}</button>`).join('')}</div>
      </section>
      <div id="resultados"></div>
      <div id="inicio">
        <h2 class="sec">Lo más pedido</h2>
        <div class="rejilla">${tarjetas}</div>
        <h2 class="sec">Todas las guías rápidas</h2>
        <div class="lista">${todas}</div>
        <h2 class="sec">Manual completo</h2>
        ${caps}
        <p class="pie-pagina">Manual de Autoparts · versión 8 · Todas las imágenes son capturas reales del sistema.</p>
      </div>`;
    enlazarBusqueda();
  }

  function pintarResultados(texto) {
    const cont = document.getElementById('resultados');
    const inicio = document.getElementById('inicio');
    const t = texto.trim();
    if (!t) { cont.innerHTML = ''; if (inicio) inicio.hidden = false; return; }
    if (inicio) inicio.hidden = true;
    const r = buscar(t);
    if (!r.lista || !r.lista.length) {
      cont.innerHTML = `<h2 class="sec">Resultados</h2><div class="vacio">No encontré nada para «${esc(t)}».<br>Pruebe con otra palabra (por ejemplo «usuario», «venta», «caja», «precio», «imprimir») o mire las guías de abajo.</div>
        <h2 class="sec">Guías rápidas</h2><div class="lista">${M.guias.slice(0, 12).map((x) => `<a class="item" href="#/g/${x.id}"><span class="t">${esc(x.titulo)}</span></a>`).join('')}</div>`;
      return;
    }
    const filas = r.lista.map(({ d }) => {
      const etq = d.tipo === 'g' ? '<span class="etq g">Cómo hacerlo</span>' : '<span class="etq a">Manual</span>';
      const sub = d.tipo === 'g' ? resaltar(d.texto, r.toks) : esc(d.sub) + ' · ' + resaltar(d.texto, r.toks);
      return `<a class="item" href="#/${d.tipo}/${d.id}"><div class="t">${etq}${marcarTitulo(d.titulo, r.toks)}</div><div class="s">${sub}</div></a>`;
    }).join('');
    cont.innerHTML = `<h2 class="sec">${r.lista.length} resultado${r.lista.length === 1 ? '' : 's'}</h2><div class="lista">${filas}</div>`;
  }

  function enlazarBusqueda() {
    const q = document.getElementById('q');
    const caja = q.parentElement;
    let tm;
    q.addEventListener('input', () => {
      caja.classList.toggle('con-texto', !!q.value);
      clearTimeout(tm);
      tm = setTimeout(() => pintarResultados(q.value), 60);
    });
    document.getElementById('borrar').addEventListener('click', () => { q.value = ''; caja.classList.remove('con-texto'); pintarResultados(''); q.focus(); });
    document.querySelectorAll('.atajos button').forEach((b) => b.addEventListener('click', () => { q.value = b.dataset.q; caja.classList.add('con-texto'); pintarResultados(q.value); q.focus(); }));
    q.addEventListener('keydown', (e) => {
      if (e.key === 'Escape') { q.value = ''; caja.classList.remove('con-texto'); pintarResultados(''); }
      if (e.key === 'Enter') { const p = document.querySelector('#resultados .item'); if (p) location.hash = p.getAttribute('href'); }
    });
  }

  function vistaGuia(g) {
    const ver = (g.ver || []).map((id) => porId['a/' + id]).filter(Boolean);
    const movil = g.img && /^img\/m_/.test(g.img);
    app.innerHTML = `
      <div class="migas"><a href="#/">← Volver al inicio</a></div>
      <article class="doc">
        <span class="etq g">Cómo hacerlo</span>
        <h1>${esc(g.titulo)}</h1>
        <ol class="pasos-guia">${g.pasos.map((p) => `<li><span>${p}</span></li>`).join('')}</ol>
        ${g.nota ? `<div class="nota-guia">${g.nota}</div>` : ''}
        ${g.img ? `<div class="guia-img ${movil ? 'movil' : ''}"><img src="${g.img}" alt="Captura de pantalla: ${esc(g.titulo)}" loading="lazy"></div>` : ''}
        ${ver.length ? `<div class="mas"><h3>Más información en el manual</h3><div class="lista">${ver.map((a) => `<a class="item" href="#/a/${a.id}"><div class="t">${esc(a.titulo)}</div><div class="s">${esc(a.capTitulo)}</div></a>`).join('')}</div></div>` : ''}
      </article>`;
    window.scrollTo(0, 0);
  }

  function vistaArticulo(a) {
    const lista = M.articulos.filter((x) => x.cap === a.cap);
    const i = lista.findIndex((x) => x.id === a.id);
    const ant = lista[i - 1], sig = lista[i + 1];
    app.innerHTML = `
      <div class="migas"><a href="#/">Inicio</a> › ${a.cap}. ${esc(a.capTitulo)}</div>
      <article class="doc">
        <span class="etq a">Manual</span>
        <h1>${esc(a.titulo)}</h1>
        <div class="capt">Capítulo ${a.cap}: ${esc(a.capTitulo)}</div>
        <div class="cuerpo">${a.html}</div>
        <div class="navart">${ant ? `<a href="#/a/${ant.id}">← ${esc(ant.titulo)}</a>` : '<span></span>'}${sig ? `<a href="#/a/${sig.id}">${esc(sig.titulo)} →</a>` : ''}</div>
      </article>`;
    window.scrollTo(0, 0);
  }

  function ruta() {
    const h = location.hash.replace(/^#\/?/, '');
    if (h.startsWith('g/') && porId[h]) return vistaGuia(porId[h]);
    if (h.startsWith('a/') && porId[h]) return vistaArticulo(porId[h]);
    vistaInicio();
    const q = document.getElementById('q');
    if (q && !/^(g|a)\//.test(h) && !('ontouchstart' in window)) q.focus();
  }
  window.addEventListener('hashchange', ruta);
  ruta();

  document.addEventListener('keydown', (e) => {
    const q = document.getElementById('q');
    if (e.key === '/' && q && document.activeElement !== q && !/input|textarea/i.test(document.activeElement.tagName)) { e.preventDefault(); q.focus(); }
  });

  const visor = document.getElementById('visor');
  const visorImg = visor.querySelector('img');
  document.addEventListener('click', (e) => {
    const img = e.target.closest('.cap img, .guia-img img');
    if (img) { visorImg.src = img.src; visor.hidden = false; return; }
    const cap = e.target.closest('.cap');
    if (cap) { const i = cap.querySelector('img'); if (i) { visorImg.src = i.src; visor.hidden = false; } return; }
    if (e.target.closest('#visor')) visor.hidden = true;
  });
  document.addEventListener('keydown', (e) => { if (e.key === 'Escape') visor.hidden = true; });
})();
