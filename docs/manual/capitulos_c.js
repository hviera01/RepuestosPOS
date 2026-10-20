const H = require('./helpers');
const { pantalla, pantallaSola, campo, btn, chip, kpi, tabla, figura, aviso, consejo, cuidado, pasos, datos } = H;

const cap9 = `
<p>Los créditos se manejan en <b>Créditos ▸ Ventas Crédito</b> (lo que los clientes le deben) y <b>Créditos ▸ Compras Crédito</b> (lo que usted le debe a sus proveedores).</p>
${figura(
  pantalla({
    modulo: 'Créditos', sub: 'Ventas Crédito', titulo: 'Ventas Crédito', alto: 80,
    html: `<h5>Ventas Crédito</h5>
    <div class="fila">${campo('Buscar cliente o documento…')}${chip('Todos')}${chip('Pendientes', 'ok')}${chip('Vencidos', 'mal')}${btn('Unir facturas', 'sec')}${btn('Crédito manual')}</div>
    ${tabla(['Documento', 'Cliente', 'Vence', 'Total', 'Saldo', 'Estado'], [
      ['00004512', 'TALLER MECÁNICO LÓPEZ', '15/11/2026', 'L 8,400.00', 'L 5,200.00', chip('Al día', 'ok')],
      ['00004390', 'TRANSPORTES DEL VALLE', '02/10/2026', 'L 12,950.00', 'L 12,950.00', chip('Vencido', 'mal')],
      ['00004288', 'CARLOS MEJÍA', '28/10/2026', 'L 1,980.00', 'L 0.00', chip('Pagado')],
    ], [3, 4])}
    <div class="tarjeta" style="margin-top:2mm"><b>Registrar abono</b>
      <div class="fila" style="margin-top:1.5mm">${campo('Monto', '2,000.00')}${campo('Método', 'Efectivo ▾')}${campo('Fecha', '19/10/2026')}${btn('Guardar abono', 'ok')}</div></div>`,
    marcas: [{ n: 1, x: 60, y: 14 }, { n: 2, x: 85, y: 14 }, { n: 3, x: 80, y: 34 }, { n: 4, x: 14, y: 80 }],
  }),
  'Cuentas por cobrar con el registro de un abono.',
  ['Filtros por estado: pendientes o vencidos.', 'Unir varias facturas de un cliente en un solo crédito, o crear un crédito manual (por ejemplo, saldos de antes del sistema).', 'Estado: <b>Vencido</b> cuando pasó la fecha de vencimiento y aún hay saldo.', 'Cada abono guarda monto, método de pago, fecha, número de recibo y quién lo cobró.']
)}
<h3>Cobrar un abono</h3>
${pasos([
  ['Busque el crédito del cliente.', 'Por nombre, RTN o número de documento.'],
  ['Presione Abonar y escriba el monto.', 'Elija el método de pago (efectivo, tarjeta o transferencia) y la fecha.'],
  ['Guarde.', 'El saldo baja, se genera el número de recibo y puede imprimir el recibo para el cliente.'],
])}
<ul>
  <li>Puede <b>editar</b> o <b>eliminar</b> un abono ya registrado; el sistema recalcula los saldos de los abonos siguientes. Eliminar un crédito completo pide la clave especial si así está configurado.</li>
  <li>El teléfono del crédito queda guardado; úselo para llamar o escribir al cliente cuando tenga un saldo vencido. Puede agregarlo o corregirlo desde el menú del crédito.</li>
  <li>Una venta registrada a crédito aparece aquí automáticamente; no hay que volver a escribirla.</li>
</ul>
<h3>Compras Crédito</h3>
<p>Funciona igual, pero para las facturas que usted debe a los proveedores. Además del abono a una factura puede hacer un <b>abono general</b> a un proveedor: el sistema reparte el monto entre sus facturas más antiguas primero.</p>
${consejo('Revise «Vencidos» al empezar el día. En el Reporte Financiero también verá cuánto tiene por cobrar y por pagar en total.')}
`;

const cap10 = `
<p>Si el negocio tiene más de un local, <b>Sucursales</b> y <b>Traslados</b> permiten mover mercadería entre ellos con control. En este sistema las existencias son una sola bolsa: al registrar un traslado, las unidades salen del inventario (igual que una venta) y quedan anotadas hacia la sucursal destino.</p>

<h3>Sucursales</h3>
<p>En <b>Sucursales</b> (solo administrador) cree cada local con su nombre y dirección. Las sucursales inactivas no aparecen al registrar traslados.</p>

<h3>Registrar un traslado</h3>
${figura(
  pantalla({
    modulo: 'Traslados', sub: 'Registrar Traslado', titulo: 'Registrar Traslado', alto: 78,
    html: `<div class="fila">${campo('Sucursal origen', 'PRINCIPAL ▾')}${campo('Sucursal destino', 'SUCURSAL 2 ▾')}${campo('Estado', 'Entregado ▾')}</div>
    <div class="fila">${campo('Observaciones', 'Reposición semanal')}${btn('Agregar Producto')}</div>
    ${tabla(['Código', 'Producto', 'Ubicación', 'Cantidad', ''], [
      ['PF-2210', 'PASTILLAS FRENO DEL. TOYOTA HILUX 05-15', '(1N)', '4', '✕'],
      ['FA-0087', 'FILTRO ACEITE TOYOTA HILUX 2.5 05-UP', '(3B)', '10', '✕'],
    ], [3])}
    <div class="fila" style="margin-top:2mm">${kpi('Total de unidades', '14')}${btn('Registrar Traslado', 'ok')}</div>`,
    marcas: [{ n: 1, x: 36, y: 13 }, { n: 2, x: 22, y: 26 }, { n: 3, x: 38, y: 55 }, { n: 4, x: 52, y: 86 }],
  }),
  'Registro de un traslado entre sucursales.',
  ['Sucursal de origen y de destino (no pueden ser la misma) y el estado con el que se crea.', 'Agregar repuestos con su cantidad; la ubicación en bodega es opcional y sale en el comprobante.', 'Cantidad de cada repuesto.', 'Al registrar se descuentan las existencias y se imprime el comprobante con espacios para firmas.']
)}
${datos(['Estado', 'Significado'], [
  ['Pendiente', 'Creado pero todavía no salió.'],
  ['Enviado', 'Salió de la sucursal origen.'],
  ['Entregado', 'La sucursal destino confirmó que lo recibió (se registra quién y cuándo).'],
  ['Anulado', 'Se canceló; las unidades vuelven al inventario.'],
])}
<p>Cuando la mercadería sale y llega en el mismo momento puede crear el traslado ya como <b>Entregado</b>. Si no, créelo como Pendiente o Enviado y use los botones <b>Enviar</b> y <b>Confirmar Recepción</b> en el detalle.</p>
<p>Si hay un repuesto repetido en varias líneas, el sistema suma las cantidades y nunca deja el inventario en negativo.</p>

<h3>Ver detalle y reimprimir</h3>
<p>En <b>Traslados ▸ Ver Detalle</b> busque por número (puede escribir solo <code>123</code> en lugar de <code>TRAS-000123</code>). Desde el detalle se imprime el comprobante como original o copia y, si su usuario tiene permiso, se <b>anula</b> (en cualquier estado excepto si ya está anulado). Al anular, las unidades regresan al inventario y queda anotado en el historial de cada repuesto.</p>

<h3>Reporte de traslados</h3>
<p>En <b>Reportes ▸ Traslados</b> filtre por rango de fechas, estado y sucursal, y exporte a PDF o Excel. En el historial de existencias de cada repuesto aparece cada traslado como «Traslado TRAS-000123 a SUCURSAL 2».</p>
`;

const cap11 = `
<h3>Su caja del día</h3>
<p>En <b>Reportes ▸ Caja</b> cada cajero maneja <b>su propia caja</b>. Se abre al empezar el turno con el efectivo con el que arranca y se cierra al terminar, contando el dinero. Lo que usted vende, cobra, paga y gasta mientras su caja está abierta se suma a <b>su</b> caja; lo de otro compañero se suma a la de él. La pantalla tiene dos pestañas: <b>Mi caja</b> e <b>Historial de cajas</b>.</p>

<h3>Abrir la caja</h3>
${figura(
  pantalla({
    modulo: 'Reportes', sub: 'Caja', titulo: 'Caja', alto: 84,
    html: `<h5>Caja</h5>
    <div class="fila">${chip('Mi caja', 'ok')}${chip('Historial de cajas')}</div>
    <div class="tarjeta"><b>Abrir caja</b>
      <p style="color:#6b7280;margin:1mm 0 2mm">No tiene una caja abierta. Indique con cuánto efectivo empieza y desde cuándo se cuentan sus ventas.</p>
      <div class="fila">${campo('Fondo inicial en efectivo (L)', '1,000.00')}</div>
      <div class="fila"><b>Contar mis ventas desde</b>${chip('Ahora', 'ok')}${chip('Último cierre')}${chip('Otra fecha')}</div>
      <div class="fila">${campo('Notas (opcional)', 'Turno de la mañana')}</div>
      <div class="fila">${btn('Abrir caja', 'ok')}</div>
    </div>`,
    marcas: [{ n: 1, x: 40, y: 46 }, { n: 2, x: 56, y: 56 }, { n: 3, x: 70, y: 78 }],
  }),
  'Apertura de la caja.',
  ['<b>Fondo inicial:</b> el efectivo con el que empieza (el cambio que deja en la gaveta). Puede ser 0.', '<b>Desde cuándo se cuenta:</b> «Ahora» (lo normal), «Último cierre» (continúa justo donde terminó su caja anterior) u «Otra fecha» (para empezar a contar desde una fecha y hora que usted elija).', 'Presione <b>Abrir caja</b>. Solo puede tener una caja abierta a la vez.']
)}
${consejo('Abra la caja antes de la primera venta del día. Si la abre después, las ventas anteriores no se cuentan, a menos que elija «Otra fecha» con la hora en que empezó.')}

<h3>Con la caja abierta</h3>
${figura(
  pantalla({
    modulo: 'Reportes', sub: 'Caja', titulo: 'Caja', alto: 98,
    html: `<h5>Caja</h5>
    <div class="fila">${btn('Actualizar', 'sec')}${btn('Corte X', 'sec')}${btn('Cerrar caja (Corte Z)')}</div>
    <div class="tarjeta"><small style="color:#6b7280">Abierta 19/10/2026 07:55</small>
      <div class="rejilla g2" style="margin-top:1.5mm">
        <div>${tabla(['Efectivo en caja', 'Monto'], [['Fondo inicial', 'L 1,000.00'], ['Ventas en efectivo', 'L 6,820.00'], ['Abonos en efectivo', 'L 1,500.00'], ['Gastos en efectivo', '-L 420.00'], ['Pagos a proveedores', '-L 0.00'], ['Compras en efectivo', '-L 0.00'], ['<b>Efectivo esperado</b>', '<b>L 8,900.00</b>']], [1])}</div>
        <div>${tabla(['Ventas (14)', 'Monto'], [['Efectivo', 'L 6,820.00'], ['Tarjeta', 'L 3,240.00'], ['Transferencia', 'L 1,100.00'], ['Cheque', 'L 0.00'], ['Crédito', 'L 2,300.00'], ['<b>Total ventas</b>', '<b>L 13,460.00</b>']], [1])}</div>
      </div></div>`,
    marcas: [{ n: 1, x: 60, y: 15 }, { n: 2, x: 28, y: 52 }, { n: 3, x: 74, y: 52 }],
  }),
  'Caja abierta con el resumen en vivo.',
  ['<b>Actualizar</b> vuelve a calcular el resumen con lo último que se vendió. <b>Corte X</b> imprime o muestra el resumen sin cerrar la caja. <b>Cerrar caja (Corte Z)</b> cuenta el dinero y cierra el turno.', 'A la izquierda, el <b>efectivo que debería haber</b> en la gaveta.', 'A la derecha, las ventas por forma de pago (las ventas a crédito se muestran aparte porque no entra dinero).']
)}
${datos(['Línea', 'Qué incluye'], [
  ['Fondo inicial', 'El efectivo con el que abrió la caja.'],
  ['Ventas en efectivo', 'Ventas de contado pagadas en efectivo, más la parte en efectivo de los pagos mixtos. No incluye cotizaciones ni ventas anuladas.'],
  ['Abonos en efectivo', 'Abonos que los clientes pagaron en efectivo a sus créditos.'],
  ['Gastos en efectivo', 'Egresos pagados en efectivo que usted registró.'],
  ['Pagos a proveedores', 'Abonos en efectivo a facturas de compras a crédito.'],
  ['Compras en efectivo', 'Compras de contado pagadas en efectivo.'],
  ['<b>Efectivo esperado</b>', 'Fondo + ventas en efectivo + abonos en efectivo − gastos − pagos a proveedores − compras en efectivo. Es lo que debería haber en la gaveta.'],
])}
<p>Las ventas con tarjeta, transferencia o cheque no suman al efectivo; aparecen en su propia línea para que el cierre de ese día cuadre contra el banco o el datáfono.</p>

<h3>Corte X: ver cómo va la caja</h3>
<p>El <b>Corte X</b> es un vistazo a mitad del turno: imprime (ticket de 58 u 80 mm) o muestra en PDF el mismo resumen, <b>sin cerrar</b> la caja. Úselo cuando el dueño pregunte cuánto hay o antes de sacar dinero de la gaveta.</p>

<h3>Cerrar la caja (Corte Z)</h3>
${figura(
  pantallaSola({
    titulo: 'Cerrar caja (Corte Z)', alto: 88,
    html: `<h5>Cerrar caja (Corte Z)</h5>
    <p><b>Efectivo esperado: L 8,900.00</b></p>
    <div class="fila">${chip('Contar billetes', 'ok')}${chip('Escribir total')}</div>
    ${tabla(['Billete o moneda', 'Cantidad', 'Subtotal'], [['L 500', '10', 'L 5,000.00'], ['L 200', '9', 'L 1,800.00'], ['L 100', '19', 'L 1,900.00'], ['L 50', '3', 'L 150.00'], ['L 20', '2', 'L 40.00'], ['…', '…', '…']], [1, 2])}
    <div class="fila"><b>Efectivo contado: L 8,880.00</b><b style="color:#c62828">Diferencia: -L 20.00</b></div>
    <div class="fila">${campo('Notas (obligatorias por la diferencia)', 'Faltante por cambio mal dado')}</div>
    <div class="fila">${btn('Cancelar', 'sec')}${btn('Cerrar caja', 'ok')}</div>`,
    marcas: [{ n: 1, x: 12, y: 24 }, { n: 2, x: 42, y: 52 }, { n: 3, x: 40, y: 72 }, { n: 4, x: 74, y: 86 }],
  }),
  'Ventana de cierre con el conteo de billetes.',
  ['Elija <b>Contar billetes</b> (escriba cuántos billetes y monedas de cada tipo tiene) o <b>Escribir total</b> si ya sabe el monto.', 'El sistema suma por usted lo que contó.', 'Compara contra lo esperado y muestra la <b>diferencia</b> (en verde si cuadra, en rojo si hay faltante o sobrante).', 'Si hay diferencia, las <b>notas son obligatorias</b>: explique qué pasó. Luego presione <b>Cerrar caja</b>.']
)}
<p>Al cerrar, el sistema guarda el cierre con todos los números (nadie puede cambiarlos después) y le ofrece imprimir el <b>Corte Z</b>, en ticket o en PDF. A partir de ese momento la caja queda cerrada y puede abrir una nueva cuando empiece el siguiente turno.</p>
${cuidado('Cuente el dinero con calma y escriba lo que realmente hay, aunque no coincida. Una diferencia anotada con su motivo es normal; una caja «cuadrada» a la fuerza esconde errores.')}

<h3>Historial de cajas</h3>
<p>La pestaña <b>Historial de cajas</b> lista las cajas de un rango de fechas (por defecto, los últimos 30 días). El administrador ve las cajas de todos los cajeros; cada cajero ve las suyas. Cada renglón muestra quién, desde cuándo hasta cuándo, el total vendido y la diferencia (o «Abierta»). Al tocar una caja se abre el detalle completo, y desde ahí puede:</p>
<ul>
  <li><b>Imprimir</b> otra vez el corte (ticket o PDF).</li>
  <li><b>Reabrir</b> la caja, si se cerró por error. Solo se puede reabrir la <b>última</b> caja cerrada de ese cajero y siempre que no tenga otra abierta. Al reabrirla se borra el conteo del cierre y la caja vuelve a quedar abierta.</li>
</ul>
${aviso('El efectivo estimado que muestra el Reporte Financiero se calcula con las cajas que están abiertas en este momento. Por eso conviene cerrar la caja todos los días.', 'Reporte financiero')}

<h3>Ingresos y egresos</h3>
<p>En <b>Reportes ▸ Ingresos-Egresos</b> está el libro de movimientos: ventas de contado, abonos a créditos, compras de contado, abonos a proveedores y egresos manuales, todo en una sola lista por fecha.</p>
<p>Para registrar un gasto (luz, agua, sueldos, fletes) use <b>Nuevo egreso</b>: monto, descripción, categoría, método de pago y si ya está pagado o queda pendiente con su fecha de pago.</p>
${aviso('Registre los egresos en caja el mismo día. Si un gasto no se anota, el cierre de caja y la utilidad del reporte financiero quedan más altos de lo real.')}
`;

const cap12 = `
<p>Los reportes están en el módulo <b>Reportes</b>. Se calculan en el servidor y se actualizan solos cuando se registra una venta, aunque la pantalla ya esté abierta. Todos se pueden exportar a PDF o Excel.</p>
${figura(
  pantalla({
    modulo: 'Reportes', sub: 'Reporte Financiero', titulo: 'Reporte Financiero', alto: 84,
    html: `<h5>Reporte Financiero</h5>
    <div class="fila">${campo('Desde', '01/10/2026')}${campo('Hasta', '19/10/2026')}${btn('Buscar')}${btn('PDF', 'sec')}${btn('Excel', 'sec')}</div>
    <div class="rejilla g4" style="margin-bottom:2mm">${kpi('Ventas', 'L 412,980')}${kpi('Utilidad bruta', 'L 128,400')}${kpi('Gastos', 'L 41,200')}${kpi('Utilidad neta', 'L 87,200')}</div>
    <div class="rejilla g2">
      <div class="tarjeta"><b>Flujo de efectivo</b>
        ${tabla(['Concepto', 'Monto'], [['Ingresos efectivo', 'L 288,400'], ['Egresos efectivo', 'L 96,100'], ['Efectivo estimado', 'L 192,300']], [1])}</div>
      <div class="tarjeta"><b>Cuentas</b>
        ${tabla(['Concepto', 'Monto'], [['Por cobrar', 'L 64,800'], ['Por pagar', 'L 38,150'], ['Valor del inventario', 'L 1,204,000']], [1])}</div>
    </div>`,
    marcas: [{ n: 1, x: 36, y: 15 }, { n: 2, x: 36, y: 35 }, { n: 3, x: 36, y: 56 }, { n: 4, x: 74, y: 56 }],
  }),
  'Reporte financiero de un periodo.',
  ['Rango de fechas del reporte.', 'Ventas, utilidad bruta (ventas menos costo real de lo vendido), gastos y utilidad neta.', 'Flujo de efectivo: cuánto entró y salió en efectivo.', 'Cuentas por cobrar y por pagar y valor del inventario.']
)}
${datos(['Reporte', 'Qué muestra'], [
  ['Reporte de Ventas', 'Todas las ventas del rango con tipo de documento, cliente, método de pago y total; filtros por tipo, estado y usuario. Cotizaciones y anuladas se distinguen.'],
  ['Reporte de Compras', 'Compras del rango por proveedor, con condición y total.'],
  ['Traslados', 'Traslados por estado y sucursal.'],
  ['Reporte Financiero', 'Utilidad, gastos, flujo de efectivo, cuentas por cobrar y pagar, repuestos y clientes con más movimiento, clientes inactivos, serie mensual y sugerencia de cuánto destinar a proveedores.'],
  ['Caja', 'Su caja del día y el historial de cajas con apertura, cierre, cortes y diferencias (capítulo 11).'],
  ['Ingresos-Egresos', 'Libro de todos los movimientos de dinero.'],
])}
<h3>Cómo leer la utilidad</h3>
<p>La <b>utilidad bruta</b> usa el costo real de cada repuesto vendido, tomado del lote del que salió (primero que entra, primero que sale). La <b>utilidad neta</b> resta además los egresos registrados. Por eso es importante registrar todas las compras con su costo correcto.</p>
${consejo('En ventas con muchos meses de datos, elija rangos de un mes o menos: el reporte carga más rápido y es más fácil de revisar.')}
`;

const cap13 = `
<p>El sistema imprime tickets en impresoras térmicas de 58 o 80 mm y también genera PDF. La configuración está en <b>Configuración</b> (capítulo 3).</p>
${datos(['Situación', 'Qué hace el sistema'], [
  ['Computadora de la caja con impresora conectada', 'Imprime directo (o muestra vista previa, según el modo elegido).'],
  ['Celular, tableta o navegador sin impresora', 'Pide a la PC principal que imprima el ticket. Sale en la caja automáticamente.'],
  ['Impresora de red', 'Se configura con la IP y el puerto (normalmente 9100).'],
  ['Impresora Bluetooth en Android', 'Se empareja en el celular y se elige en Configuración.'],
  ['Impresora que no acepta impresión directa', 'Active «Usar driver de Windows» para imprimir por el controlador de la impresora.'],
])}
<h3>Si un ticket no sale</h3>
<ol>
  <li>Revise que la impresora esté encendida, con papel y bien conectada.</li>
  <li>Entre a <b>Ventas ▸ Registrar Venta ▸ Pendientes de Impresión</b>: allí queda el ticket para reintentar.</li>
  <li>Use el botón <b>Imprimir ticket de prueba</b> en Configuración para comprobar la impresora sin registrar una venta.</li>
  <li>Si la impresora gasta papel en blanco sin cortar, pruebe «Usar driver de Windows».</li>
  <li>Revise que la <b>PC principal</b> esté marcada y encendida si imprime desde otros equipos.</li>
</ol>
<h3>Facturas con CAI</h3>
<p>Las facturas llevan el RTN, el CAI, el rango autorizado y la fecha límite del negocio, y la numeración correlativa. Configure estos datos antes de la primera factura y revise la fecha límite cada cierto tiempo: cuando se acerca el vencimiento o el final del rango, solicite el nuevo.</p>
`;

const cap14 = `
<h3>Varios equipos trabajando a la vez</h3>
<p>Puede haber varias cajas, el administrador consultando reportes desde su celular y un encargado en otra sucursal, todos al mismo tiempo. El sistema está preparado para eso:</p>
<ul>
  <li>Dos personas pueden vender el mismo repuesto a la vez sin que se descuente mal: el servidor procesa cada venta de forma ordenada y protege las existencias.</li>
  <li>La numeración de documentos nunca se repite, aunque dos cajas registren en el mismo segundo.</li>
  <li>Los cambios (precios, clientes, existencias) aparecen en los demás equipos en pocos segundos, sin refrescar.</li>
</ul>

<h3>Rapidez</h3>
<ul>
  <li>El inventario, los clientes, los proveedores y las categorías se guardan en cada equipo. Al abrir el sistema se muestran de inmediato y solo se descargan los cambios nuevos.</li>
  <li>Los reportes se calculan en el servidor y se piden por partes, para que abran rápido aunque haya muchos años de ventas.</li>
  <li>El detalle de una venta se pide en una sola consulta y se recuerda unos segundos, por lo que volver a abrirlo es instantáneo.</li>
</ul>

<h3>Si se corta el internet</h3>
<p>Cuando una operación (una venta, una compra, un abono, un ajuste) no logra llegar al servidor por un corte de conexión, el sistema <b>la reintenta automáticamente con el mismo identificador</b>. Eso evita el peor problema posible: que se registre dos veces. Aunque el primer intento sí hubiera llegado, el segundo no duplica nada.</p>
${datos(['Situación', 'Qué verá y qué hacer'], [
  ['La conexión se cae un momento', 'El sistema reintenta solo unos segundos. Si llega, todo sigue normal.'],
  ['La conexión tarda mucho en volver', 'Aparece el aviso de reintentar. Presione «Reintentar»; no vuelva a escribir la venta.'],
  ['La operación se rechaza por una regla (por ejemplo, no hay existencias)', 'Se muestra el motivo exacto; corrija y vuelva a intentar.'],
  ['Una operación guardada quedó pendiente', 'Se envía sola cuando vuelve el internet. Un indicador muestra cuántas están pendientes.'],
])}
${cuidado('Nunca registre dos veces una venta «por si acaso» sin verificar antes en Ver Detalle si ya existe. El sistema evita duplicados, pero dos ventas escritas a mano sí son dos ventas.')}

<h3>Actualizaciones automáticas</h3>
<p>Cuando hay una versión nueva, el sistema lo avisa. Las actualizaciones están <b>firmadas</b>: el programa comprueba la firma digital del instalador antes de instalarlo y rechaza cualquier archivo alterado.</p>
${datos(['Equipo', 'Cómo se actualiza'], [
  ['Windows', 'Presione «Actualizar». Se descarga, se verifica la firma, se instala sin preguntas y el programa vuelve a abrirse solo con la versión nueva. No necesita permisos de administrador.'],
  ['Android', 'Se descarga y abre el instalador de Android; confirme «Instalar». Como todas las versiones se firman con la misma llave, se instala encima de la anterior sin perder nada.'],
  ['Navegador web', 'Se actualiza solo al recargar la página.'],
])}
<p>En <b>Mantenedor ▸ Dispositivos</b> el administrador ve la versión de cada equipo y cuáles están desactualizados.</p>
${consejo('Si un equipo no actualiza, descargue el instalador más reciente de la página de versiones del sistema e instálelo encima: se conservan todos los datos, que están en la nube.')}
`;

const cap15 = `
${datos(['Problema', 'Causa probable', 'Qué hacer'], [
  ['No puedo ingresar', 'Documento o clave incorrectos, o cuenta bloqueada por intentos fallidos', 'Espere unos minutos y reintente. Si olvidó la clave, el administrador puede cambiarla en Usuarios.'],
  ['No veo un módulo del menú', 'Su usuario no tiene esa pantalla permitida', 'Pídale al administrador que la marque en su usuario.'],
  ['Un botón (anular, crear…) no aparece', 'Esa acción no está permitida para su usuario', 'Pídale al administrador que la active en «Acciones permitidas».'],
  ['El sistema pide una clave especial', 'La acción está protegida', 'Pida la clave al administrador. No se comparte.'],
  ['No encuentro un repuesto', 'La búsqueda exige todas las palabras escritas', 'Escriba menos palabras o use solo el código; revise que el repuesto esté activo.'],
  ['El repuesto no sale al filtrar por vehículo', 'No tiene ese vehículo registrado', 'Abra su ficha y agregue el vehículo y los años en «Vehículos compatibles».'],
  ['Dice «Ya existe un producto con ese código»', 'Otro repuesto usa ese código', 'Use otro código o busque el repuesto existente.'],
  ['No me deja agregar un repuesto a la venta: «no tiene existencia disponible»', 'Por defecto el sistema no vende lo que no tiene en existencia', 'Registre la compra o un ajuste de ingreso. Si necesita venderlo igual, el administrador debe activar «Vender un producto sin existencia» y la clave especial.'],
  ['No puedo abrir mi caja: «Ya tenés una caja abierta»', 'Quedó una caja abierta de un día anterior', 'Entre a Caja ▸ Mi caja, ciérrela con su conteo y luego abra la nueva.'],
  ['Al cerrar la caja pide una nota', 'Hay diferencia entre lo esperado y lo contado', 'Escriba el motivo de la diferencia; es obligatorio para dejar constancia.'],
  ['Falta una venta en el reporte', 'Otro rango de fechas, o la venta se guardó en espera / es una cotización', 'Revise «Ver en Espera» y el tipo de documento. Las cotizaciones y anuladas no suman.'],
  ['El ticket sale muy largo o en blanco', 'Ancho de rollo mal configurado o impresora que no acepta impresión directa', 'Revise 58/80 mm y pruebe «Usar driver de Windows».'],
  ['Los colores se ven mal', 'Color principal demasiado claro', 'Elija otro en Configuración ▸ Apariencia, o use «Restablecer».'],
  ['El sistema se ve lento', 'Conexión a internet débil', 'Compruebe la señal del equipo; las listas guardadas se muestran igual, y las operaciones se reintentan solas.'],
  ['La versión de un equipo no cambia', 'Instalador viejo guardado en Descargas', 'Use «Buscar actualización» dentro del programa o descargue el instalador más reciente.'],
])}
<h3>Buenas prácticas</h3>
<ul>
  <li>Un usuario por persona, y desactive a quien ya no trabaja en el negocio.</li>
  <li>Registre las compras el mismo día, con el costo real: de eso depende la utilidad.</li>
  <li>Haga el cierre de caja todos los días y anote los egresos.</li>
  <li>Use siempre <b>Ver Detalle</b> antes de repetir una operación que pareció no completarse.</li>
  <li>Registre los vehículos compatibles al crear cada repuesto: ahorra mucho tiempo al buscar.</li>
  <li>Cambie la clave especial si sospecha que alguien la conoce.</li>
</ul>
`;

module.exports = { cap9, cap10, cap11, cap12, cap13, cap14, cap15 };
