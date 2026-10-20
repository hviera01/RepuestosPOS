const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const H = require('./helpers');
const A = require('./capitulos_a');
const B = require('./capitulos_b');
const C = require('./capitulos_c');

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
  ['Impresión', C.cap13],
  ['Varios equipos, internet y actualizaciones', C.cap14],
  ['Problemas frecuentes y buenas prácticas', C.cap15],
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
  <div class="marca">${H.ENGRANAJE}<span>Repuestos POS</span></div>
  <div><h1>Manual<br>de usuario</h1><div class="sub">Ventas, compras, inventario por vehículo, créditos, traslados y reportes.</div></div>
  <div class="pie"><span>Versión del manual: ${fecha}</span><span>Para administradores y personal de mostrador</span></div>
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
