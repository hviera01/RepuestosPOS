const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const H = require('./helpers');
const A = require('./capitulos_a');
const B = require('./capitulos_b');
const C = require('./capitulos_c');
const D = require('./capitulos_d');
const E = require('./capitulos_e');

const capitulos = [
  ['Bienvenida', A.cap1],
  ['Primeros pasos', A.cap2],
  ['Configuración del negocio', A.cap3],
  ['Usuarios, roles y permisos', A.cap4],
  ['Inventario y vehículos compatibles', B.cap5],
  ['Clientes y proveedores', B.cap6],
  ['Ventas', B.cap7],
  ['Compras', B.cap8],
  ['Créditos y cobros', C.cap9],
  ['Sucursales y traslados', C.cap10],
  ['Caja, ingresos y egresos', C.cap11],
  ['Reportes', C.cap12],
  ['Impresión e impresión remota', D.capImpresion],
  ['Escanear con el celular', D.capEscaner],
  ['Varios equipos, internet y actualizaciones', C.cap14],
  ['Instalación, seguridad y respaldo', D.capInstalacion],
  ['Problemas frecuentes y buenas prácticas', C.cap15],
  ['Glosario', E.capGlosario],
];

const css = fs.readFileSync(path.join(__dirname, 'estilos.css'), 'utf8');
const hoy = new Date();
const fecha = hoy.toLocaleDateString('es-HN', { year: 'numeric', month: 'long' });

const toc = `<div class="toc"><h2>Contenido</h2><ol>${capitulos
  .map(([t], i) => `<li><b>${i + 1}</b><a href="#cap${i + 1}">${t}</a></li>`)
  .join('')}</ol></div>`;

const cuerpo = capitulos
  .map(([t, c], i) => `<h2 class="capitulo" id="cap${i + 1}"><span class="num">${i + 1}</span>${t}</h2>${c}`)
  .join('\n');

const html = `<!doctype html><html lang="es"><head><meta charset="utf-8"><title>Manual de usuario - Repuestos POS</title><style>${css}</style></head><body>
<section class="portada">
  ${H.ENGRANAJE.replace('fill="#fff"', 'fill="#303846"').replace('r="14" fill="#303846"', 'r="14" fill="#fff"')}
  <h1>Manual de usuario</h1>
  <div class="linea"></div>
  <div class="sub">Repuestos POS</div>
  <div class="pie">${fecha}</div>
</section>
${toc}
${cuerpo}
</body></html>`;

const salidaHtml = path.join(__dirname, 'manual.html');
fs.writeFileSync(salidaHtml, html);

const salidaPdf = path.join(__dirname, 'Manual_de_Usuario_Repuestos_POS.pdf');
const chrome = process.env.CHROME || 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
execFileSync(chrome, [
  '--headless=new',
  '--disable-gpu',
  '--no-pdf-header-footer',
  `--print-to-pdf=${salidaPdf}`,
  'file:///' + salidaHtml.replace(/\\/g, '/'),
], { stdio: 'inherit' });
console.log('PDF generado:', salidaPdf);
