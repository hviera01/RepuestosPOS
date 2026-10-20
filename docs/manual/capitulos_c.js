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
  <li>Con el teléfono del crédito se pueden enviar avisos de pago al cliente.</li>
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
<p>En <b>Reportes ▸ Traslados</b> filtre por rango de fechas, estado y sucursal, y exporte a PDF o Excel. También se puede ver en la ficha de cada repuesto su historial de traslados.</p>
`;

const cap11 = `
<h3>Cierre de caja</h3>
<p>En <b>Reportes ▸ Cierre de Caja</b> se cuenta el dinero al final del turno o del día.</p>
${figura(
  pantalla({
    modulo: 'Reportes', sub: 'Cierre de Caja', titulo: 'Cierre de Caja', alto: 80,
    html: `<h5>Cierre de Caja</h5>
    <div class="rejilla g4" style="margin-bottom:2mm">${kpi('Monto inicial', 'L 1,000.00')}${kpi('Ingresos efectivo', 'L 9,820.00')}${kpi('Egresos efectivo', 'L 1,150.00')}${kpi('Efectivo esperado', 'L 9,670.00')}</div>
    <div class="rejilla g3" style="margin-bottom:2mm">${kpi('Ingresos tarjeta', 'L 4,310.00')}${kpi('Transferencias', 'L 2,300.00')}${kpi('Gran total', 'L 16,280.00')}</div>
    <div class="fila">${campo('Efectivo contado', '9,650.00')}${campo('Diferencia', '-20.00')}${campo('Observaciones', 'Falta cambio de L20')}${btn('Registrar cierre', 'ok')}</div>`,
    marcas: [{ n: 1, x: 36, y: 22 }, { n: 2, x: 36, y: 44 }, { n: 3, x: 36, y: 66 }, { n: 4, x: 82, y: 66 }],
  }),
  'Cierre de caja con el efectivo esperado y la diferencia.',
  ['El monto inicial del turno (es el efectivo con el que se quedó en el cierre anterior).', 'Los ingresos y egresos del turno se calculan solos desde las ventas, abonos, compras y egresos.', 'Total de tarjeta, transferencias y gran total.', 'Usted cuenta el efectivo real, el sistema calcula la diferencia y se guarda el cierre.']
)}
<p>Las ventas con <b>pago mixto</b> se reparten entre efectivo, tarjeta y transferencia según cada parte. El historial de cierres se conserva y se puede consultar e imprimir.</p>

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
  ['Cierre de Caja', 'Historial de cierres con diferencias.'],
  ['Ingresos-Egresos', 'Libro de todos los movimientos de dinero.'],
])}
<h3>Cómo leer la utilidad</h3>
<p>La <b>utilidad bruta</b> usa el costo real de cada repuesto vendido, tomado del lote del que salió (primero que entra, primero que sale). La <b>utilidad neta</b> resta además los egresos registrados. Por eso es importante registrar todas las compras con su costo correcto.</p>
${consejo('En ventas con muchos meses de datos, elija rangos de un mes o menos: el reporte carga más rápido y es más fácil de revisar.')}
`;

const cap13 = `
<p>El sistema imprime tickets en impresoras térmicas de 58 o 80 mm y también genera PDF. La configuración está en <b>Negocio</b> (capítulo 3).</p>
${datos(['Situación', 'Qué hace el sistema'], [
  ['Computadora de la caja con impresora conectada', 'Imprime directo (o muestra vista previa, según el modo elegido).'],
  ['Celular, tableta o navegador sin impresora', 'Pide a la PC principal que imprima el ticket. Sale en la caja automáticamente.'],
  ['Impresora de red', 'Se configura con la IP y el puerto (normalmente 9100).'],
  ['Impresora Bluetooth en Android', 'Se empareja en el celular y se elige en Negocio.'],
  ['Impresora que no acepta impresión directa', 'Active «Usar driver de Windows» para imprimir por el controlador de la impresora.'],
])}
<h3>Si un ticket no sale</h3>
<ol>
  <li>Revise que la impresora esté encendida, con papel y bien conectada.</li>
  <li>Entre a <b>Ventas ▸ Registrar Venta ▸ Pendientes de Impresión</b>: allí queda el ticket para reintentar.</li>
  <li>Use el botón <b>Imprimir ticket de prueba</b> en Negocio para comprobar la impresora sin registrar una venta.</li>
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
  ['No me deja vender: sin existencia', 'La categoría controla existencias y no hay unidades', 'Registre la compra o el ajuste de ingreso; o pida la autorización si el negocio la permite.'],
  ['Falta una venta en el reporte', 'Otro rango de fechas, o la venta se guardó en espera / es una cotización', 'Revise «Ver en Espera» y el tipo de documento. Las cotizaciones y anuladas no suman.'],
  ['El ticket sale muy largo o en blanco', 'Ancho de rollo mal configurado o impresora que no acepta impresión directa', 'Revise 58/80 mm y pruebe «Usar driver de Windows».'],
  ['Los colores se ven mal', 'Color principal demasiado claro', 'Elija otro en Negocio ▸ Apariencia, o use «Restablecer».'],
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
