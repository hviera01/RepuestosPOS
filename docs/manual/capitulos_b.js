const H = require('./helpers');
const { pantalla, pantallaSola, campo, btn, chip, kpi, tabla, figura, aviso, consejo, cuidado, pasos, datos } = H;

const cap5 = `
<p>El inventario está en <b>Mantenedor ▸ Inventario</b>. Allí se ven todos los repuestos con su código, nombre, categoría, existencia y precios. La lista se guarda en el equipo, por lo que abre al instante aunque haya miles de repuestos; los cambios hechos desde otros equipos llegan solos en segundos.</p>

${figura(
  pantalla({
    modulo: 'Mantenedor', sub: 'Inventario', titulo: 'Inventario', alto: 88,
    html: `<h5>Inventario</h5>
    <div class="fila">${campo('Vista', 'Productos filtrados ▾')}${campo('Buscar en', 'Todo ▾')}${campo('Buscar', 'disco freno')}</div>
    <div class="fila">${campo('Vehículo', 'toyota hilux')}${campo('Año', '2012')}${btn('Refrescar', 'sec')}${btn('Importar', 'sec')}${btn('Excel', 'sec')}${btn('PDF', 'sec')}${btn('Nuevo Producto')}</div>
    ${tabla(['Código', 'Nombre', 'Categoría', 'Existencia', 'Precio'], [
      ['DF-1042', 'DISCO FRENO DEL. TOYOTA HILUX 05-15, FORTUNER 09-UP', 'Frenos', '12', 'L 1,450.00'],
      ['PF-2210', 'PASTILLAS FRENO DEL. TOYOTA HILUX 05-15', 'Frenos', '3 ' + chip('Bajo', 'aviso'), 'L 680.00'],
      ['FA-0087', 'FILTRO ACEITE TOYOTA HILUX 2.5 05-UP', 'Filtros', '40', 'L 145.00'],
      ['AM-3301', 'AMORTIGUADOR TRAS. TOYOTA HILUX 06-15', 'Suspensión', '0 ' + chip('Agotado', 'mal'), 'L 1,980.00'],
    ], [3, 4])}`,
    marcas: [{ n: 1, x: 40, y: 26 }, { n: 2, x: 33, y: 41 }, { n: 3, x: 90, y: 41 }, { n: 4, x: 88, y: 58 }],
  }),
  'Inventario con búsqueda por texto y filtro por vehículo y año.',
  ['Vista: <b>Productos filtrados</b>, <b>Mostrar todos</b> o <b>Bajo existencia</b>.', 'Filtro de <b>vehículo y año</b>: se aplica junto con el texto al presionar Enter.', 'Botones de importar desde Excel y de exportar a Excel, PDF, ticket o etiquetas.', 'Doble clic (o toque prolongado en el celular) sobre un repuesto abre su ficha completa.']
)}

<h3>Buscar un repuesto</h3>
<p>El buscador es <b>estricto</b>: cada palabra que escribe debe aparecer en el código, el nombre, la descripción o los vehículos del repuesto. Si escribe <code>disco civic</code>, solo salen repuestos que tengan las dos palabras. El código se puede escribir sin guiones ni espacios, y el código exacto aparece primero.</p>
<h4>Buscar por vehículo y año</h4>
<p>Junto al buscador hay dos campos: <b>Vehículo</b> (marca y/o modelo, por ejemplo <code>toyota hilux</code>) y <b>Año</b> (por ejemplo <code>2012</code> o <code>12</code>). Presione Enter para aplicarlos. El resultado muestra los repuestos compatibles con ese vehículo en ese año; los que sirven para el vehículo pero no tienen años registrados salen al final, para no esconder un repuesto que quizá sirva.</p>
${consejo('Puede usar solo el vehículo, solo el año, o combinarlos con el texto: «pastillas» + «hilux» + «2012» deja únicamente las pastillas que sirven para una Hilux 2012.')}
<p>El mismo filtro está en la ventana <b>Buscar Producto</b> de ventas, compras, pedidos y traslados.</p>

<h3>Crear un repuesto nuevo</h3>
<p>Presione <b>Nuevo Producto</b> (si su usuario tiene permiso). Se abre la ficha del repuesto:</p>
${datos(['Campo', 'Qué escribir'], [
  ['Código', 'Código interno o del fabricante. Si lo deja vacío, el sistema genera uno. No puede repetirse.'],
  ['Código de barras', 'Escanéelo con la cámara o con lector. Si lo deja vacío, se genera uno interno.'],
  ['Nombre', 'Nombre del repuesto. Puede escribirse a mano o armarse solo (ver abajo).'],
  ['Descripción', 'Ubicación en bodega, marca del fabricante u otra nota (opcional).'],
  ['Categoría', 'Obligatoria. Las categorías se crean en Mantenedor ▸ Categorías.'],
  ['Existencia inicial', 'Cuántas unidades hay hoy. Se crea el primer lote de costo con el precio de compra.'],
  ['Precio de compra', 'Lo que le cuesta cada unidad.'],
  ['Precio de venta (hasta 3 niveles)', 'Precio normal y, si lo necesita, dos precios alternativos (mayorista, taller).'],
  ['Foto', 'Opcional. Se sube a internet y se ve en las búsquedas.'],
  ['Estado', 'Activo o inactivo. Los inactivos no aparecen para vender.'],
])}

<h3>Vehículos compatibles y nombre automático</h3>
<p>Dentro de la ficha hay una tarjeta <b>Vehículos compatibles (opcional)</b>. Con ella se registra para qué vehículos sirve el repuesto y el sistema puede armar el nombre solo.</p>
${figura(
  pantallaSola({
    titulo: 'Nuevo producto', alto: 96,
    html: `<h5>Nuevo producto</h5>
    <div class="fila">${campo('Código', 'PF-2210')}${campo('Código de barras', '2012345678901')}</div>
    <div class="campo lleno" style="margin-bottom:2mm"><b>Nombre</b>PASTILLAS FRENO DEL. TOYOTA HILUX 05-15, FORTUNER 09-UP, NISSAN FRONTIER +1</div>
    <div class="tarjeta" style="margin-bottom:2mm;background:#f6f7f9"><b>Vehículos compatibles (opcional) &nbsp; ${chip('Activado', 'ok')}</b>
      <div class="campo lleno" style="margin:1.5mm 0"><b>Nombre del repuesto</b>PASTILLAS FRENO DEL.</div>
      ${tabla(['Marca', 'Modelo', 'Año desde', 'Año hasta', ''], [
        ['TOYOTA', 'HILUX', '2005', '2015', '✕'],
        ['TOYOTA', 'FORTUNER', '2009', '', '✕'],
        ['NISSAN', 'FRONTIER', '', '', '✕'],
        ['FORD', 'RANGER', '2012', '2018', '✕'],
      ])}
      <div class="fila" style="margin-top:1.5mm">${btn('+ Agregar vehículo', 'sec')}${chip('Armar el nombre automáticamente', 'ok')}</div>
    </div>
    <div class="fila">${campo('Categoría', 'Frenos ▾')}${campo('Existencia', '12')}${campo('P. compra', '420.00')}${campo('P. venta', '680.00')}</div>`,
    marcas: [{ n: 1, x: 6, y: 25 }, { n: 2, x: 6, y: 38 }, { n: 3, x: 50, y: 50 }, { n: 4, x: 50, y: 82 }],
  }),
  'Ficha de un repuesto con vehículos compatibles y nombre armado automáticamente.',
  ['El <b>nombre</b> se completa solo al agregar vehículos; puede corregirlo a mano.', 'Escriba el <b>nombre del repuesto</b> sin vehículos.', 'Una fila por vehículo: marca, modelo y rango de años. Año hasta vacío significa «en adelante».', 'Con <b>Armar el nombre automáticamente</b> activado, el nombre se actualiza cada vez que cambia la lista.']
)}
${pasos([
  ['Active «Vehículos compatibles».', 'Aparece el cuadro para escribir el nombre del repuesto y la lista de vehículos.'],
  ['Escriba el nombre del repuesto.', 'Por ejemplo <code>PASTILLAS FRENO DEL.</code>.'],
  ['Agregue cada vehículo.', 'Marca y modelo tienen sugerencias: al escribir las primeras letras aparecen las marcas y modelos que ya usó antes, así no se escriben distinto.'],
  ['Indique los años.', 'Desde y hasta, con cuatro cifras (2005 y 2015). Si el repuesto sirve de 2009 en adelante, deje «hasta» vacío.'],
  ['Revise el nombre.', 'El sistema lo arma corto: nombre del repuesto + primeros tres vehículos + «+N» si hay más. Los años se abrevian a dos cifras.'],
])}
<h4>Reglas del nombre automático</h4>
<ul>
  <li>La marca solo se repite cuando cambia: <code>TOYOTA HILUX 05-15, FORTUNER 09-UP, NISSAN FRONTIER</code>.</li>
  <li>Los años se muestran como <code>05-15</code>, <code>09-UP</code> (en adelante) o <code>12</code> (un solo año).</li>
  <li>Si hay más de tres vehículos se agrega <code>+N</code> al final; la lista completa queda guardada y la búsqueda por vehículo la usa completa.</li>
  <li><b>Es opcional y editable.</b> Si prefiere escribir el nombre a mano, simplemente edítelo: la opción de armado automático se desactiva sola para ese repuesto. Para volver al nombre automático, active de nuevo la casilla.</li>
  <li>Los repuestos que ya existían sin vehículos siguen funcionando: el filtro por vehículo intenta leer las marcas y años que estén escritos en su nombre.</li>
</ul>

<h3>Ajustar existencias</h3>
<p>Desde la ficha o el menú de cada fila se abre <b>Ajustar existencias</b>. Hay dos movimientos:</p>
<ul>
  <li><b>Ingreso:</b> suma unidades indicando el costo unitario. Se crea un lote de costo nuevo.</li>
  <li><b>Salida:</b> resta unidades. Puede elegir de qué lote salen o dejar que el sistema use el más antiguo primero (FIFO).</li>
</ul>
<p>Todo ajuste queda en el <b>historial de existencias</b> con fecha, usuario y motivo. Si la clave especial está activada para esta acción, se la pedirá antes de confirmar.</p>

<h3>Lotes de costo e historiales</h3>
<p>Cada compra o ingreso crea un <b>lote</b> con su costo. Al vender, el sistema descuenta de los lotes más antiguos y calcula el costo real de la venta, así la utilidad de los reportes es exacta. En la ficha del repuesto puede ver:</p>
<ul>
  <li>Los lotes con su cantidad restante (y reordenarlos si necesita que salga primero uno distinto).</li>
  <li>El historial de existencias, de precios de compra, de ventas y de traslados del repuesto.</li>
</ul>

<h3>Importar y exportar</h3>
<ul>
  <li><b>Importar:</b> carga o actualiza muchos repuestos desde un archivo de Excel. El sistema crea las categorías que falten y actualiza los repuestos cuyo código ya existe.</li>
  <li><b>Excel / PDF:</b> exporta la lista que está viendo.</li>
  <li><b>Ticket / Etiquetas:</b> imprime la lista en rollo o etiquetas con código de barras.</li>
</ul>

<h3>Auditoría y pendientes de reposición</h3>
<p><b>Auditoría de Inventario</b> permite comparar las existencias del sistema contra un conteo físico y ver las diferencias. <b>Pendientes de Reposición</b> muestra los repuestos que se vendieron sin existencia (venta anticipada) y que están esperando que llegue la compra para completarse.</p>

<h3>Categorías</h3>
<p>En <b>Mantenedor ▸ Categorías</b> se crean las categorías (Frenos, Filtros, Suspensión…). Cada categoría puede <b>controlar existencias</b> o no: las que no controlan existencias (por ejemplo, servicios o mano de obra) se pueden vender siempre.</p>

<h3>Descuentos y promociones</h3>
<p>En <b>Mantenedor ▸ Descuentos y Promociones</b> se crean ofertas: porcentaje de descuento, precio fijo, combo por cantidad, combo de varios productos o regalo. Cada una tiene fechas, forma de pago y condición (contado o crédito). En Registrar Venta el botón <b>Ver promociones vigentes</b> muestra las que aplican.</p>
`;

const cap6 = `
<h3>Clientes</h3>
<p>En <b>Clientes</b> se registran las personas y empresas a quienes se vende. No es obligatorio registrar al cliente antes de vender: puede escribir su nombre en la venta y el sistema lo crea solo.</p>
${figura(
  pantalla({
    modulo: 'Clientes', titulo: 'Clientes', alto: 62,
    html: `<h5>Clientes</h5>
    <div class="fila">${campo('Buscar cliente…')}${btn('Nuevo Cliente')}</div>
    ${tabla(['RTN / DNI', 'Nombre', 'Teléfono', 'Última compra'], [
      ['08011985123456', 'TALLER MECÁNICO LÓPEZ', '9988-7766', '12/10/2026'],
      ['0801199012311', 'CARLOS MEJÍA', '3322-1100', '05/10/2026'],
      ['—', 'CONSUMIDOR FINAL', '—', '—'],
    ])}`,
    marcas: [{ n: 1, x: 82, y: 24 }, { n: 2, x: 8, y: 44 }],
  }),
  'Lista de clientes.',
  ['Crea un cliente nuevo (si su usuario tiene permiso).', 'Tocar un cliente abre su detalle: ventas, créditos y abonos.']
)}
<p>El <b>detalle del cliente</b> reúne todo su historial: compras realizadas, créditos pendientes, abonos el resumen de compras (total comprado, cantidad de compras, cliente desde y última compra). Un cliente activo que lleva muchos días sin comprar aparece como inactivo en el reporte financiero.</p>
<p>No se pueden repetir los números de RTN o DNI; si intenta registrar uno repetido el sistema avisa.</p>

<h3>Proveedores</h3>
<p>En <b>Proveedores</b> se registran las empresas a quienes se compra: RTN, razón social, correo y teléfono. Se usan al registrar compras y créditos con proveedores.</p>
`;

const cap7 = `
<p>La venta se registra en <b>Ventas ▸ Registrar Venta</b>. La pantalla se adapta al tamaño: en computadora muestra el buscador y el carrito lado a lado, y en celular los muestra en dos mitades.</p>

${figura(
  pantalla({
    modulo: 'Ventas', sub: 'Registrar Venta', titulo: 'Registrar Venta', alto: 100,
    html: `<div class="fila">${chip('Factura', 'ok')}${chip('Boleta')}${chip('Cotización')}${chip('Venta')}${campo('Condición', 'Contado ▾')}${campo('Método de pago', 'Efectivo ▾')}</div>
    <div class="fila">${campo('Cliente', 'TALLER MECÁNICO LÓPEZ')}${campo('RTN / Documento', '08011985123456')}${btn('Más datos', 'sec')}</div>
    <div class="fila">${btn('Agregar Producto')}${btn('Escanear con celular', 'sec')}${btn('Ver promociones vigentes', 'sec')}</div>
    ${tabla(['Producto', 'Cant.', 'Precio', 'Desc.', 'Subtotal'], [
      ['DISCO FRENO DEL. TOYOTA HILUX 05-15', '2', '1,450.00', '0%', '2,900.00'],
      ['PASTILLAS FRENO DEL. TOYOTA HILUX 05-15', '1', '680.00', '5%', '646.00'],
      ['LÍQUIDO DE FRENOS DOT4 500ML', '2', '95.00', '0%', '190.00'],
    ], [1, 2, 3, 4])}
    <div class="fila" style="justify-content:space-between;margin-top:2mm"><div class="rejilla g3" style="flex:1">${kpi('Subtotal', 'L 3,736.00')}${kpi('ISV 15%', 'L 560.40')}${kpi('TOTAL A PAGAR', 'L 4,296.40')}</div>${campo('Paga con', '4,300.00')}</div>
    <div class="fila">${btn('Guardar en Espera', 'sec')}${btn('Limpiar Venta', 'rojo')}${btn('Registrar Venta', 'ok')}</div>`,
    marcas: [{ n: 1, x: 36, y: 12 }, { n: 2, x: 36, y: 26 }, { n: 3, x: 36, y: 38 }, { n: 4, x: 36, y: 57 }, { n: 5, x: 60, y: 76 }, { n: 6, x: 76, y: 91 }],
  }),
  'Pantalla de Registrar Venta.',
  ['<b>Tipo de documento</b> (el que usted eligió como predeterminado aparece marcado), <b>condición</b> (contado o crédito) y <b>método de pago</b>.', '<b>Cliente</b> y RTN. Si no escribe nada, la venta sale a nombre de Consumidor final.', '<b>Agregar Producto</b> abre el buscador de repuestos; también puede escanear el código con la cámara o con el celular.', 'Tabla de <b>productos en la venta</b>: cambie cantidad, descuento o quite líneas.', 'Totales y monto con el que paga el cliente (el sistema calcula el cambio).', 'Botones para guardar la venta en espera, limpiar o <b>registrarla</b>.']
)}

<h3>Registrar una venta paso a paso</h3>
${pasos([
  ['Elija el tipo de documento.', 'Factura y Boleta cobran ISV; Venta es un ticket simple; Cotización no descuenta existencias.'],
  ['Busque los repuestos.', 'Presione <b>Agregar Producto</b> y escriba lo que busca. Para un vehículo concreto, llene los campos <b>Vehículo</b> y <b>Año</b> y presione Enter. Doble clic (o Enter sobre la fila resaltada) agrega el repuesto.'],
  ['Ajuste cantidades y descuentos.', 'Puede aplicar un descuento a una línea o un descuento general a toda la venta.'],
  ['Indique el cliente (opcional).', 'Escriba el nombre o use la lupa para buscarlo. Para facturas conviene registrar el RTN.'],
  ['Elija cómo paga.', 'Efectivo, tarjeta, transferencia o mixto. En efectivo escriba con cuánto paga y el sistema muestra el cambio.'],
  ['Presione Registrar Venta.', 'La venta recibe su número, descuenta las existencias y se imprime el ticket o la factura según la configuración.'],
])}

<h3>Buscar repuestos al vender</h3>
${figura(
  pantallaSola({
    titulo: 'Buscar Producto', alto: 70,
    html: `<h5>Buscar Producto</h5>
    <div class="fila">${campo('Buscar', 'pastillas')}${campo('Vehículo', 'toyota hilux')}${campo('Año', '2012')}${campo('Precio', 'Nivel 1 ▾')}</div>
    ${tabla(['Foto', 'Código', 'Nombre', 'Existencia', 'Precio'], [
      ['▢', 'PF-2210', 'PASTILLAS FRENO DEL. TOYOTA HILUX 05-15', '3', 'L 680.00'],
      ['▢', 'PF-2215', 'PASTILLAS FRENO TRAS. TOYOTA HILUX 05-15', '8', 'L 540.00'],
      ['▢', 'PF-0090', 'PASTILLAS FRENO DEL. TOYOTA HILUX (SIN AÑO)', '5', 'L 610.00'],
    ], [3, 4])}
    <p style="color:#6b7280;margin-top:2mm">Los repuestos para ese vehículo que no tienen años registrados aparecen al final.</p>`,
    marcas: [{ n: 1, x: 10, y: 22 }, { n: 2, x: 38, y: 22 }, { n: 3, x: 80, y: 40 }],
  }),
  'Buscador de repuestos dentro de una venta.',
  ['Texto de búsqueda (todas las palabras deben aparecer).', 'Filtro por vehículo y año.', 'Doble clic o Enter para agregar el repuesto a la venta.']
)}
<p>Si el repuesto no existe puede crearlo desde el mismo buscador con <b>Nuevo producto</b>. Si no tiene existencias, el sistema avisa y, si la clave especial está activa para esta acción, la pide antes de dejarlo agregar.</p>

<h3>Formas de pago</h3>
${datos(['Forma', 'Cómo se usa'], [
  ['Efectivo', 'Escriba «Paga con» y el sistema calcula el cambio.'],
  ['Tarjeta / Transferencia', 'Se registra el total completo con ese método.'],
  ['Mixto', 'Divide el total entre varios métodos (por ejemplo, L 2,000 en efectivo y el resto con tarjeta). El cierre de caja reparte cada parte en su método.'],
  ['Crédito', 'Cambie la condición a Crédito: no se cobra nada ahora, se pide fecha de vencimiento y un teléfono para avisos, y la venta queda en Ventas Crédito.'],
])}

<h3>Datos adicionales y envío</h3>
<p>El botón <b>Más datos</b> permite anotar número de orden de compra exenta, registro de exonerado, registro SAG, observaciones y, si la mercadería se envía, los datos del envío (nombre, dirección y teléfono) para imprimir la guía.</p>

<h3>Ventas en espera</h3>
<ul>
  <li><b>Guardar en Espera:</b> aparta la venta (y reserva las existencias) para continuar después. Útil cuando el cliente va a buscar el dinero o decidir.</li>
  <li><b>Ver en Espera:</b> lista de ventas guardadas; elija una para retomarla o eliminarla (se liberan las existencias).</li>
  <li><b>Ver Perdidas:</b> el sistema guarda solo cada venta en curso; si se cerró la pestaña o se fue la luz, aquí se recuperan.</li>
</ul>

<h3>Cotizaciones</h3>
<p>Elija el tipo <b>Cotización</b> para dar un precio. No descuenta existencias ni suma a las ventas. Más tarde, desde <b>Ver Detalle</b>, el botón <b>Convertir a venta</b> la transforma en venta real.</p>

<h3>Ver detalle, reimprimir y anular</h3>
<p>En <b>Ventas ▸ Ver Detalle</b> (o <b>Ver Facturas</b>) busque la venta por número de documento, cliente o fecha. El detalle abre al instante y muestra las líneas, los costos y el método de pago. Desde ahí puede:</p>
<ul>
  <li><b>Reimprimir</b> el ticket o la factura (como copia o como original).</li>
  <li><b>Duplicar</b> la venta para repetirla.</li>
  <li><b>Convertir a venta</b> si es una cotización.</li>
  <li><b>Anular</b> la venta (según permisos): devuelve las existencias al lote del que salieron, cancela el crédito si no tiene abonos y deja constancia del motivo.</li>
</ul>
${cuidado('Una venta anulada no se puede reactivar. Si anuló por error, registre una venta nueva.')}

<h3>Imprimir</h3>
<p>Según la configuración, al registrar la venta se muestra la vista previa o se imprime directo. Si el equipo no tiene impresora (por ejemplo el celular o el navegador), el sistema puede pedirle a la <b>PC principal</b> que imprima: el ticket sale en la caja sin que nadie haga nada. En <b>Pendientes de Impresión</b> quedan los tickets que no se pudieron imprimir para reintentar.</p>
`;

const cap8 = `
<p>Las compras se registran en <b>Compras ▸ Registrar Compra</b>. Sirven para aumentar existencias, actualizar costos y llevar las cuentas por pagar a proveedores.</p>
${figura(
  pantalla({
    modulo: 'Compras', sub: 'Registrar Compra', titulo: 'Registrar Compra', alto: 82,
    html: `<div class="fila">${campo('Proveedor', 'AUTOPARTES DEL NORTE')}${campo('No. de factura', '001-001-01-00045821')}${campo('Condición', 'Crédito ▾')}${campo('Vence', '18/11/2026')}</div>
    <div class="fila">${btn('Agregar Producto')}${btn('Compras en espera', 'sec')}</div>
    ${tabla(['Producto', 'Cant.', 'Costo', 'Desc.', 'Nuevo P. venta', 'Subtotal'], [
      ['DISCO FRENO DEL. TOYOTA HILUX 05-15', '10', '980.00', '0%', '1,450.00', '9,800.00'],
      ['PASTILLAS FRENO DEL. TOYOTA HILUX 05-15', '20', '420.00', '5%', '680.00', '7,980.00'],
    ], [1, 2, 3, 4, 5])}
    <div class="rejilla g3" style="margin-top:2mm">${kpi('Subtotal', 'L 17,780.00')}${kpi('ISV', 'L 2,667.00')}${kpi('Total a pagar', 'L 20,447.00')}</div>
    <div class="fila" style="margin-top:2mm">${btn('Registrar Compra', 'ok')}</div>`,
    marcas: [{ n: 1, x: 36, y: 13 }, { n: 2, x: 20, y: 25 }, { n: 3, x: 74, y: 48 }, { n: 4, x: 38, y: 86 }],
  }),
  'Pantalla de Registrar Compra.',
  ['Proveedor, número de factura del proveedor, condición (contado o crédito) y fecha de vencimiento.', 'Agregar repuestos; puede crear uno nuevo desde el mismo buscador.', 'Opcionalmente un <b>nuevo precio de venta</b> que se aplica al repuesto al registrar la compra.', 'Registrar la compra: suma existencias, crea el lote de costo y, si es a crédito, la cuenta por pagar.']
)}
<h3>Registrar una compra</h3>
${pasos([
  ['Elija el proveedor y escriba el número de factura del proveedor.', 'La condición Crédito pide fecha de vencimiento y crea la cuenta por pagar.'],
  ['Agregue los repuestos.', 'Cantidad, costo unitario y descuento. El buscador tiene el mismo filtro por vehículo y año.'],
  ['Revise el precio de venta nuevo (opcional).', 'Si el costo cambió, puede ajustar el precio de venta ahí mismo.'],
  ['Presione Registrar Compra.', 'Las existencias suben y cada línea queda como un lote con su costo para el cálculo de utilidades.'],
])}
<ul>
  <li><b>Compras en espera:</b> el borrador se guarda solo; puede retomarlo si se interrumpe.</li>
  <li><b>Hacer Pedido:</b> arma una lista de repuestos para pedir al proveedor y la exporta a PDF; no registra una compra.</li>
  <li><b>Ver Detalle:</b> consulta, reimprime o anula una compra (según permisos). Al anular, el sistema resta las existencias que había sumado.</li>
</ul>
${aviso('Si vendió un repuesto sin existencias («venta anticipada»), al registrar la compra del mismo repuesto el sistema le ofrece completar ese pendiente y corrige el costo real de aquella venta.', 'Pendientes de reposición')}
`;

module.exports = { cap5, cap6, cap7, cap8 };
