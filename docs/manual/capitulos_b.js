const H = require('./helpers');
const { captura, parMovil } = require('./captura_helper');
const { datos, figura, aviso, consejo, cuidado, pasos } = H;

const cap5 = `
<p>El inventario está en <b>Mantenedor ▸ Inventario</b>. Allí se ven todos los repuestos con su código, nombre, categoría, ubicación, existencia y precios. La lista se guarda en el equipo, por lo que abre al instante aunque haya miles de repuestos; los cambios hechos desde otros equipos llegan solos en segundos.</p>
<p>Al abrir la pantalla la lista aparece vacía con el mensaje «Escribí algo y presioná buscar»: escriba lo que busca, o elija <b>Mostrar todos</b> en el selector de vista.</p>

${figura(
  captura('inventario_resultados.png', [{ n: 1, x: 188, y: 150 }, { n: 2, x: 130, y: 204 }, { n: 3, x: 340, y: 204 }, { n: 4, x: 560, y: 204 }, { n: 5, x: 910, y: 204 }, { n: 6, x: 230, y: 253 }, { n: 7, x: 540, y: 253 }, { n: 8, x: 1375, y: 378 }]),
  'Inventario después de buscar «FILTRO».',
  ['Cantidad de productos y valor del inventario a precio de compra y a precio de venta. A la derecha, el cambio entre productos <b>Activos</b> e <b>Inactivos</b>.', '<b>Vista</b>: Productos filtrados (lo que usted busca), Mostrar todos o Bajo existencia.', '<b>Filtrar por</b>: dónde buscar el texto: Todo, Código, Código de barras, Nombre, Descripción o Categoría.', 'Búsqueda por texto o escaneando un código de barras; presione Enter o la flecha.', 'Filtro por <b>vehículo</b> y <b>año</b>: se aplica junto con el texto al presionar Enter.', 'Exportar a Excel o PDF, imprimir un ticket con la lista y las etiquetas con código de barras.', '<b>Nuevo Producto</b> (si su usuario tiene permiso).', 'Menú de acciones de cada repuesto.']
)}
<p>Las columnas Código, Nombre, Existencia, Precio de venta y Precio de compra se pueden ordenar tocando su encabezado. La existencia baja aparece en rojo y la normal en azul. Los nombres de los repuestos se ven siempre completos, sin cortarse con «…».</p>

<h3>Buscar un repuesto</h3>
<p>El buscador es <b>estricto</b>: cada palabra que escribe debe aparecer en el código, el nombre, la descripción o los vehículos del repuesto. Si escribe <code>disco civic</code>, solo salen repuestos que tengan las dos palabras. El código se puede escribir sin guiones ni espacios, y el código exacto aparece primero.</p>
<h4>Buscar con lector o con la cámara</h4>
<p>Al escanear un código de barras, con una pistola lectora o con la cámara del celular, el sistema busca el repuesto aunque el código llegue con espacios, ceros de más o de menos, guiones o el dígito verificador distinto. Si el código está en la ficha como <code>0012345</code> y el lector manda <code>12345</code>, igual lo encuentra. Funciona igual en Inventario, Registrar Venta, Registrar Compra y Auditoría de Inventario.</p>
<h4>Buscar por vehículo y año</h4>
<p>Junto al buscador hay dos campos: <b>Vehículo</b> (marca y/o modelo, por ejemplo <code>toyota hilux</code>) y <b>Año</b> (por ejemplo <code>2012</code> o <code>12</code>). Presione Enter para aplicarlos. El resultado muestra los repuestos compatibles con ese vehículo en ese año; los que sirven para el vehículo pero no tienen años registrados salen al final, para no esconder un repuesto que quizá sirva.</p>
${consejo('Puede usar solo el vehículo, solo el año, o combinarlos con el texto: «pastillas» + «hilux» + «2012» deja únicamente las pastillas que sirven para una Hilux 2012.')}
<p>El mismo filtro está en la ventana <b>Buscar Producto</b> de ventas, compras, pedidos y traslados.</p>

<h3>Menú de cada repuesto</h3>
${figura(
  captura('inv_menu_fila.png', [{ n: 1, x: 1193, y: 427 }, { n: 2, x: 1193, y: 471 }, { n: 3, x: 1193, y: 531 }, { n: 4, x: 1193, y: 591 }]),
  'Menú de los tres puntos de la primera fila.',
  ['<b>Editar producto</b>: abre la misma ficha que Nuevo Producto con los datos del repuesto.', '<b>Ajustar existencia</b>: suma o resta unidades (ver más abajo).', '<b>Historial de existencia</b>: todos los movimientos del repuesto.', '<b>Código de barras</b>: imprime etiquetas con el código del repuesto, de la cantidad que indique.']
)}

<h3>Crear un repuesto nuevo</h3>
<p>Presione <b>Nuevo Producto</b> (si su usuario tiene permiso). Se abre la ficha del repuesto:</p>
${figura(
  captura('producto_vehiculos.png', [{ n: 1, x: 720, y: 264 }, { n: 2, x: 400, y: 354 }, { n: 3, x: 498, y: 416 }, { n: 4, x: 662, y: 489 }, { n: 5, x: 480, y: 562 }, { n: 6, x: 662, y: 790 }, { n: 7, x: 1106, y: 368 }, { n: 8, x: 940, y: 430 }, { n: 9, x: 940, y: 580 }]),
  'Ficha de un repuesto nuevo con dos vehículos compatibles. El nombre se está armando solo.',
  ['<b>Foto</b> (opcional). Se sube a internet y se ve en las búsquedas.', '<b>Código</b> y <b>código de barras</b>. Si deja el código vacío, el sistema genera uno; no puede repetirse. El código de barras se puede escanear con el icono.', '<b>Nombre</b>. Escriba el nombre base; con «Armar el nombre automáticamente» encendido, el sistema le agrega los vehículos.', '<b>Vehículos compatibles</b> (opcional): interruptor para usar la lista de vehículos.', 'Una fila por vehículo: marca, modelo, año desde y año hasta. La X de la derecha quita la fila; «Agregar vehículo» agrega otra.', '<b>Armar el nombre automáticamente</b>: pone al final del nombre los vehículos compatibles. Apáguelo si prefiere escribir todo el nombre a mano.', '<b>Es un combo/kit</b>: para vender varios repuestos juntos con un solo precio.', 'Existencia inicial, precio de compra y precio de venta. «Niveles de precio adicionales» agrega hasta dos precios más (mayorista, taller).', '<b>Estado</b>: activo o inactivo. Los inactivos no aparecen para vender.']
)}
<p>Debajo, con el desplazamiento de la ventana, siguen <b>Descripción</b> (opcional), <b>Ubicación física</b> (opcional; por ejemplo «PASILLO 2 - ESTANTE B», se muestra en las búsquedas y en los traslados) y <b>Categoría</b> (obligatoria).</p>
${datos(['Campo', 'Qué escribir'], [
  ['Código', 'Código interno o del fabricante. Si lo deja vacío, el sistema genera uno. No puede repetirse.'],
  ['Código de barras', 'Escanéelo con la cámara o con lector. Si lo deja vacío, se genera uno interno.'],
  ['Nombre', 'Nombre del repuesto. Puede escribirse a mano o armarse solo con los vehículos.'],
  ['Descripción', 'Marca del fabricante u otra nota (opcional).'],
  ['Ubicación física', 'Dónde está en la bodega (opcional). En los traslados se usa esta ubicación.'],
  ['Categoría', 'Obligatoria. Las categorías se crean en Mantenedor ▸ Categorías.'],
  ['Existencia inicial', 'Cuántas unidades hay hoy. Se crea el primer lote de costo con el precio de compra.'],
  ['Precio de compra', 'Lo que le cuesta cada unidad.'],
  ['Precio de venta (hasta 3 niveles)', 'Precio normal y, si lo necesita, dos precios alternativos. En una venta se elige con qué nivel buscar.'],
])}
<h4>Reglas del nombre automático</h4>
<ul>
  <li>La marca solo se repite cuando cambia: <code>TOYOTA HILUX 05-15, FORTUNER 09-UP, NISSAN FRONTIER</code>.</li>
  <li>Los años se muestran como <code>05-15</code>, <code>09-UP</code> (en adelante) o <code>12</code> (un solo año).</li>
  <li>Si hay más de tres vehículos se agrega <code>+N</code> al final; la lista completa queda guardada y la búsqueda por vehículo la usa completa.</li>
  <li>Una fila de vehículo que todavía no tiene años no se agrega al nombre hasta completarse.</li>
  <li>Los repuestos que ya existían sin vehículos siguen funcionando: el filtro por vehículo intenta leer las marcas y años que estén escritos en su nombre.</li>
</ul>

<h3>Ajustar existencias</h3>
${figura(
  captura('inv_ajustar.png', [{ n: 1, x: 627, y: 392 }, { n: 2, x: 712, y: 455 }, { n: 3, x: 712, y: 516 }, { n: 4, x: 712, y: 588 }, { n: 5, x: 846, y: 660 }]),
  'Ajustar Existencia de un repuesto con 12 unidades.',
  ['<b>Ingreso</b> suma unidades; <b>Salida</b> resta unidades.', '<b>Cantidad</b> que ingresa o sale.', '<b>Costo unitario</b> de lo que ingresa (en un ingreso se crea un lote de costo nuevo). En una salida puede elegir de qué lote sale o dejar que el sistema use el más antiguo primero.', '<b>Motivo</b> (opcional): queda escrito en el historial.', '<b>Guardar</b>. Si la clave especial está activada para esta acción, se la pedirá antes.']
)}
<p>Todo ajuste queda en el historial de existencias con fecha, usuario y motivo.</p>

<h3>Historial de existencia</h3>
<p>Desde el menú del repuesto se abre una sola ventana con todo lo que movió sus existencias, separado en pestañas. Se actualiza al instante: si alguien anula una venta, el movimiento aparece de inmediato.</p>
${figura(
  captura('inv_historial.png', [{ n: 1, x: 540, y: 278 }, { n: 2, x: 310, y: 327 }, { n: 3, x: 410, y: 430 }, { n: 4, x: 718, y: 430 }, { n: 5, x: 1180, y: 430 }]),
  'Historial de existencia de un repuesto.',
  ['Pestañas: <b>Movimientos</b> (todo junto), <b>Ventas</b>, <b>Compras</b>, <b>Traslados</b>, <b>Ajustes manuales</b> y <b>Lotes de costo</b>.', 'Filtro de fechas <b>Desde</b> y <b>Hasta</b>.', '<b>Tipo</b> de movimiento: Venta, Anulación de venta, Traslado, etc. Un traslado se muestra como «Traslado» y al tocarlo se ve su detalle.', 'Existencia <b>anterior</b>, <b>nueva</b> y <b>cambio</b>, con el motivo (por ejemplo «Venta 0277»).', 'Usuario que hizo el movimiento.']
)}
<p>En la pestaña <b>Lotes de costo</b> se ven los lotes con su cantidad restante; cada compra o ingreso crea un lote con su costo. Al vender, el sistema descuenta de los lotes más antiguos primero y calcula el costo real de la venta, así la utilidad de los reportes es exacta.</p>

<h3>Importar y exportar</h3>
${figura(
  captura('inv_pdf_opciones.png', [{ n: 1, x: 660, y: 325 }, { n: 2, x: 720, y: 540 }, { n: 3, x: 887, y: 786 }]),
  'Ventana de Exportar a PDF.',
  ['Columnas que saldrán en el PDF; toque para activar o quitar.', 'Productos que se incluyen: todos los de la búsqueda, con casillas para quitar los que no quiera.', '<b>Exportar</b> genera el PDF; también se puede guardar o compartir.']
)}
<ul>
  <li><b>Importar:</b> carga o actualiza muchos repuestos desde un archivo de Excel. El sistema crea las categorías que falten y actualiza los repuestos cuyo código ya existe.</li>
  <li><b>Excel y PDF:</b> exportan la lista que está viendo.</li>
  <li><b>Etiquetas:</b> imprime etiquetas con el código de barras de los repuestos de la lista.</li>
</ul>
${figura(
  captura('inv_ticket_opciones.png', [{ n: 1, x: 574, y: 433 }, { n: 2, x: 831, y: 606 }]),
  'Opciones del ticket de inventario.',
  ['Qué datos incluir de cada repuesto: código, descripción, categoría, existencia, precio de venta y precio de compra.', '<b>Continuar</b> muestra la vista previa y permite imprimirla.']
)}
<p>El ticket del inventario sale en impresora térmica con el nombre de cada repuesto partido en varias líneas, de modo que nunca queda cortado.</p>

<h3>Auditoría de inventario</h3>
${figura(
  captura('auditoria.png', [{ n: 1, x: 160, y: 225 }, { n: 2, x: 440, y: 225 }]),
  'Auditoría de Inventario.',
  ['<b>Categoría a auditar</b>: elija la categoría que va a contar.', 'Busque o escanee cada repuesto para registrar lo que hay físicamente.']
)}
<p>La auditoría sirve para comparar las existencias del sistema con un conteo físico y ver las diferencias. Si escanea un repuesto, la categoría se elige sola.</p>

<h3>Pendientes de reposición</h3>
${figura(
  captura('pendientes_reposicion.png', [{ n: 1, x: 370, y: 173 }]),
  'Pendientes de Reposición cuando no hay ninguno.',
  ['Aquí aparecen las ventas anticipadas que esperan la compra que las repone. Se completan solas al registrar esa compra.']
)}

<h3>Categorías</h3>
${figura(
  captura('categorias.png', [{ n: 1, x: 570, y: 206 }, { n: 2, x: 1330, y: 206 }, { n: 3, x: 1196, y: 322 }]),
  'Lista de categorías.',
  ['Buscador por descripción.', '<b>Nueva Categoría</b>.', 'Cada fila muestra la categoría y su estado. Al tocarla se edita.']
)}
<p>Cada categoría puede <b>controlar existencias</b> o no: las que no controlan existencias (por ejemplo, servicios o mano de obra) se pueden vender siempre.</p>

<h3>Descuentos y promociones</h3>
<p>En <b>Mantenedor ▸ Descuentos y Promociones</b> se crean las ofertas. La lista muestra por defecto solo las vigentes.</p>
${figura(
  captura('promocion_nueva.png', [{ n: 1, x: 720, y: 218 }, { n: 2, x: 720, y: 350 }, { n: 3, x: 720, y: 490 }, { n: 4, x: 720, y: 540 }, { n: 5, x: 590, y: 619 }, { n: 6, x: 720, y: 734 }, { n: 7, x: 720, y: 810 }]),
  'Ventana Nueva Promoción.',
  ['Nombre de la promoción.', '<b>Tipo de promoción</b>: % Descuento, Precio Fijo, Combo por Cantidad, Combo de Productos o Regalo.', 'El valor que pide el tipo elegido (aquí, el porcentaje de descuento).', '<b>Elegir productos</b> a los que aplica.', '<b>Vigencia</b>: fecha de inicio y, si se quita la casilla «Sin fecha de fin», fecha de fin.', '<b>Condición de la venta</b>: Todos, Contado o Crédito.', '<b>Método de pago</b>: se pueden elegir varios. Ambos filtros son independientes: tienen que cumplirse los dos para que la promoción se aplique.']
)}
<p>En Registrar Venta el botón <b>Ver promociones vigentes</b> (el icono de etiqueta) muestra las que aplican.</p>
`;

const cap6 = `
<h3>Clientes</h3>
<p>En <b>Clientes</b> se registran las personas y empresas a quienes se vende. No es obligatorio registrar al cliente antes de vender: puede escribir su nombre en la venta y el sistema lo crea solo.</p>
${figura(
  captura('clientes_lista.png', [{ n: 1, x: 130, y: 204 }, { n: 2, x: 390, y: 204 }, { n: 3, x: 778, y: 197 }, { n: 4, x: 1368, y: 326 }]),
  'Lista de clientes después de buscar «MECANICA».',
  ['Vista: Clientes filtrados o Mostrar todos.', 'Buscador por DNI, nombre, dirección o teléfono.', '<b>Nuevo Cliente</b> (si su usuario tiene permiso).', 'Menú de cada cliente: <b>Ver detalle</b>, <b>Editar</b> y <b>Eliminar</b>.']
)}
${figura(
  captura('cliente_nuevo.png', [{ n: 1, x: 720, y: 382 }, { n: 2, x: 720, y: 444 }, { n: 3, x: 720, y: 530 }, { n: 4, x: 856, y: 634 }]),
  'Ventana de Nuevo Cliente.',
  ['<b>DNI</b> o RTN (opcional). No se pueden repetir; si intenta registrar uno repetido el sistema avisa.', '<b>Nombre completo</b>.', 'Dirección y teléfono (opcionales).', '<b>Estado</b>: activo o inactivo.']
)}
<h4>Detalle del cliente</h4>
${figura(
  captura('cliente_detalle.png', [{ n: 1, x: 480, y: 250 }, { n: 2, x: 720, y: 397 }, { n: 3, x: 720, y: 570 }, { n: 4, x: 327, y: 715 }, { n: 5, x: 480, y: 830 }], { recorte: 164 }),
  'Detalle de un cliente con crédito vencido.',
  ['Datos del cliente: DNI, teléfono y estado.', '<b>Seguimiento de crédito</b>: si hay crédito vencido, un aviso con el monto.', 'Historial de créditos del cliente: cada factura con su fecha, vencimiento, saldo y estado (Vigente, Vencida o Liquidada).', '<b>Puntualidad histórica de pago</b>: cuántos créditos pagó a tiempo.', '<b>Resumen de compras</b>: total comprado, cantidad de compras, ticket promedio, cliente desde y última compra.']
)}

<h3>Proveedores</h3>
<p>En <b>Proveedores</b> se registran las empresas a quienes se compra. Se usan al registrar compras y créditos con proveedores.</p>
${figura(
  captura('proveedores_lista.png', [{ n: 1, x: 130, y: 204 }, { n: 2, x: 390, y: 204 }, { n: 3, x: 775, y: 197 }, { n: 4, x: 1358, y: 313 }]),
  'Lista de proveedores.',
  ['Vista: Proveedores filtrados o Mostrar todos.', 'Buscador por RTN, razón social, correo o teléfono.', '<b>Nuevo Proveedor</b>.', 'Menú de cada proveedor: <b>Editar</b> o <b>Eliminar</b>.']
)}
${figura(
  captura('proveedor_nuevo.png', [{ n: 1, x: 712, y: 367 }, { n: 2, x: 712, y: 430 }, { n: 3, x: 712, y: 491 }, { n: 4, x: 712, y: 553 }, { n: 5, x: 857, y: 620 }]),
  'Ventana de Nuevo Proveedor.',
  ['<b>RTN</b> (opcional).', '<b>Razón social</b>.', 'Correo electrónico (opcional).', 'Teléfono (opcional).', '<b>Estado</b>: activo o inactivo.']
)}
`;

const cap7 = `
<p>La venta se registra en <b>Ventas ▸ Registrar Venta</b>. La pantalla se adapta al tamaño del equipo. Arriba a la derecha hay un botón para cambiar la <b>vista</b>: <b>Clásica</b>, <b>Dividida</b> (buscador y carrito lado a lado) o <b>Tabla grande</b>. La vista elegida se recuerda.</p>

${figura(
  captura('venta_con_items.png', [{ n: 1, x: 330, y: 154 }, { n: 2, x: 810, y: 154 }, { n: 3, x: 123, y: 204 }, { n: 4, x: 700, y: 281 }, { n: 5, x: 87, y: 336 }, { n: 6, x: 257, y: 429 }, { n: 7, x: 339, y: 429 }, { n: 8, x: 1134, y: 429 }, { n: 9, x: 1316, y: 429 }, { n: 10, x: 880, y: 565 }, { n: 11, x: 80, y: 730 }, { n: 12, x: 720, y: 858 }]),
  'Registrar Venta con tres repuestos agregados (vista clásica).',
  ['<b>Vendiendo como</b>: el usuario al que se le registra la venta. Se puede cambiar.', 'Botones: <b>Limpiar Venta</b>, <b>Guardar en Espera</b>, <b>Ver en Espera</b>, <b>Ver Perdidas</b> y <b>Ver Facturas</b>.', '<b>Pendientes de Impresión</b>, con un contador amarillo cuando hay tickets sin imprimir.', 'Fecha, <b>tipo de documento</b>, cliente, RTN o documento, <b>condición</b> (contado o crédito) y <b>método de pago</b>.', '<b>Más datos</b>: campos poco frecuentes (descuento global, O/C exenta, registro de exonerado, SAG, observaciones y envío).', '<b>Con ISV / Sin ISV</b>: muestra los precios de cada línea con o sin impuesto. No cambia el total.', 'Ver la tabla más grande en una ventana completa.', '<b>Escanear con celular</b>: usa el celular como lector de códigos (capítulo 14).', '<b>Agregar Producto</b> abre el buscador de repuestos.', 'Cada línea: código, descripción, cantidad, precio y descuento. Los iconos de la derecha marcan la línea como venta anticipada o la quitan.', 'Subtotal, ISV y <b>total a pagar</b>.', '<b>Crear Venta</b> registra la venta.']
)}

<h3>Registrar una venta paso a paso</h3>
${pasos([
  ['Elija el tipo de documento.', 'Factura muestra el ISV desglosado; Venta es un ticket simple sin ISV; Cotización puede ser «sin ISV» o «con ISV» y no descuenta existencias.'],
  ['Busque los repuestos.', 'Presione <b>Agregar Producto</b> y escriba lo que busca. Para un vehículo concreto, llene los campos <b>Vehículo</b> y <b>Año</b> y presione Enter. Haga doble clic en el repuesto (o selecciónelo y presione Enter) para agregarlo.'],
  ['Ajuste cantidades y descuentos.', 'Puede aplicar un descuento a una línea o un descuento general a toda la venta (en «Más datos»).'],
  ['Indique el cliente (opcional).', 'Escriba el nombre o use la lupa para buscarlo. Para facturas conviene registrar el RTN.'],
  ['Elija cómo paga.', 'Efectivo, tarjeta, transferencia, cheque o mixto. En efectivo escriba con cuánto paga y el sistema muestra el cambio.'],
  ['Presione Crear Venta.', 'La venta recibe su número, descuenta las existencias y se imprime el ticket o la factura según la configuración.'],
])}

<h3>Tipo de documento y forma de pago</h3>
${figura(
  captura('venta_tipo_documento.png', [{ n: 1, x: 315, y: 343 }]),
  'Opciones de tipo de documento.',
  ['Factura, Venta, Cotización sin ISV y Cotización con ISV.']
)}
${figura(
  captura('venta_metodo_pago.png', [{ n: 1, x: 1210, y: 362 }]),
  'Opciones de método de pago.',
  ['Efectivo, Tarjeta, Transferencia, Cheque y Mixto.']
)}
${datos(['Forma', 'Cómo se usa'], [
  ['Efectivo', 'Escriba «Paga con» y el sistema calcula el cambio.'],
  ['Tarjeta / Transferencia / Cheque', 'Se registra el total completo con ese método.'],
  ['Mixto', 'Divide el total entre varios métodos (por ejemplo, L 2,000 en efectivo y el resto con tarjeta). El cierre de caja reparte cada parte en su método.'],
  ['Crédito', 'Cambie la condición a Crédito: no se cobra nada ahora, se pide fecha de vencimiento y un teléfono para avisos, y la venta queda en Ventas Crédito.'],
])}

<h3>Buscar repuestos al vender</h3>
${figura(
  captura('venta_buscar_resultados.png', [{ n: 1, x: 225, y: 235 }, { n: 2, x: 570, y: 235 }, { n: 3, x: 840, y: 235 }, { n: 4, x: 1098, y: 235 }, { n: 5, x: 1303, y: 235 }, { n: 6, x: 720, y: 356 }, { n: 7, x: 1239, y: 356 }, { n: 8, x: 1325, y: 356 }]),
  'Buscar Producto, con «FILTRO» escrito y el primer resultado resaltado.',
  ['Texto de búsqueda (todas las palabras deben aparecer). Enter busca.', 'Filtro por <b>vehículo</b> y <b>año</b>.', '<b>Productos</b> o <b>Combos</b>.', 'Con qué precio se agrega el repuesto: <b>Precio 1</b>, <b>2</b> o <b>3</b>.', '<b>Producto Nuevo</b>: crea el repuesto desde aquí mismo.', 'El resultado resaltado. Doble clic, o Enter con la lista seleccionada, lo agrega a la venta. Si el texto es un código de barras exacto y hay un solo resultado, se agrega solo.', '<b>Existencia</b> (verde: hay; rojo: poca o ninguna). Se puede ordenar tocando el encabezado.', 'Lápiz para editar el repuesto sin salir de la venta.']
)}
<p>Las flechas ↑ ↓ mueven la selección y la tecla Esc cierra la ventana. En un celular o tableta, al buscar se baja el teclado para ver los resultados.</p>
${aviso('Por defecto, un repuesto que no tiene existencia NO se puede agregar a una venta: el sistema muestra un mensaje y no lo deja seleccionar. En una cotización sí se puede, porque no descuenta existencias. Solo si el administrador activó «Permitir vender un producto sin existencia (con clave)» en Configuración y existe clave especial, se podrá agregar pidiendo esa clave.', 'Sin existencia')}

<h3>Cómo se calcula el ISV: el precio del inventario es el precio final</h3>
<p>El precio que usted guarda en el inventario es lo que paga el cliente. El sistema <b>nunca le suma 15% encima</b>. Lo que hace depende del tipo de documento:</p>
${datos(['Documento', 'Qué se ve en los totales', 'Ejemplo con un repuesto de L 1,150.00'], [
  ['Venta / Cotización sin ISV', 'Solo el total (y los descuentos, si los hay). No hay filas de ISV.', 'Total L 1,150.00'],
  ['Factura / Cotización con ISV', 'Subtotal, Descuentos y rebajas (si hay), ISV 15% y Total a pagar. El ISV se separa del precio.', 'Subtotal L 1,000.00 + ISV L 150.00 = Total L 1,150.00'],
])}
<p>Si cambia el tipo de documento a mitad de la venta, el <b>total no cambia</b>: solo cambia la forma de mostrarlo. En la factura, las columnas se llaman «Precio (c/ISV)» e «Importe (c/ISV)».</p>

<h3>Descuentos y rebajas</h3>
<p>Cada línea puede llevar un descuento en porcentaje, y toda la venta puede llevar un descuento general. Las promociones (por ejemplo precio fijo o combos) también rebajan el precio. Cuando hay cualquier descuento, en los totales aparece la fila <b>Descuentos y rebajas</b> con el monto total que se le rebajó al cliente, y el subtotal se muestra antes del descuento. Esto se ve igual en Venta, Cotización y Factura.</p>

<h3>Más datos y envío</h3>
${figura(
  captura('venta_mas_datos.png', [{ n: 1, x: 190, y: 436 }, { n: 2, x: 388, y: 436 }, { n: 3, x: 578, y: 436 }, { n: 4, x: 837, y: 436 }, { n: 5, x: 714, y: 546 }, { n: 6, x: 714, y: 602 }]),
  'Sección «Más datos» desplegada.',
  ['Descuento global (%) sobre toda la venta.', 'Número de orden de compra exenta.', 'Registro de exonerado.', 'Registro SAG.', 'Observaciones: se imprimen en la factura.', '<b>Es envío</b>: si la mercadería se envía, aquí se anotan nombre, dirección y teléfono del destinatario para imprimir la guía.']
)}

<h3>Ventas en espera, perdidas y facturas</h3>
<ul>
  <li><b>Guardar en Espera:</b> aparta la venta (y reserva las existencias) para continuar después. Útil cuando el cliente va a buscar el dinero o decidir. <b>Ver en Espera</b> lista las guardadas; elija una para retomarla o eliminarla (se liberan las existencias).</li>
  <li><b>Ver Perdidas:</b> el sistema guarda solo cada venta en curso; si se cerró la pestaña o se fue la luz, aquí se recuperan.</li>
  <li><b>Ver Facturas:</b> lista de las ventas del periodo, para abrir una rápidamente.</li>
</ul>
${figura(
  captura('venta_ver_perdidas.png', [{ n: 1, x: 627, y: 363 }, { n: 2, x: 917, y: 363 }]),
  'Facturas Perdidas: ventas que quedaron a medias.',
  ['Cada venta a medias con su tipo, cantidad de productos, total y hora. Tóquela para retomarla.', 'El bote de basura la descarta. Estas ventas no reservan existencias.']
)}
${figura(
  captura('venta_ver_facturas.png', [{ n: 1, x: 130, y: 190 }, { n: 2, x: 160, y: 239 }, { n: 3, x: 586, y: 239 }, { n: 4, x: 230, y: 297 }, { n: 5, x: 712, y: 412 }]),
  'Ver Facturas.',
  ['Rangos rápidos: Hoy, Ayer, Semana, Mes y Trimestre.', 'Fechas Desde y Hasta.', 'Buscador por número, cliente o método.', 'Filtros por estado y por tipo de documento.', 'Lista de ventas. Tocar una abre su detalle.']
)}

<h3>Cotizaciones</h3>
<p>En el selector de documento elija <b>Cotización sin ISV</b> o <b>Cotización con ISV</b> para dar un precio. Con ISV, los totales se muestran desglosados como en una factura; sin ISV, solo el total. No descuenta existencias ni suma a las ventas, y el sistema permite agregar repuestos aunque estén agotados. Más tarde, desde <b>Ver Detalle</b>, el botón <b>Convertir a venta</b> la transforma en venta real (el precio se conserva igual).</p>

<h3>Tabla grande</h3>
<p>La vista <b>Tabla grande</b> pone el carrito a pantalla completa y reduce los controles a una sola barra.</p>
${figura(
  captura('venta_tabla_grande.png', [{ n: 1, x: 78, y: 139 }, { n: 2, x: 212, y: 139 }, { n: 3, x: 400, y: 139 }, { n: 4, x: 700, y: 139 }, { n: 5, x: 1040, y: 139 }, { n: 6, x: 1403, y: 146 }, { n: 7, x: 720, y: 300 }, { n: 8, x: 1240, y: 855 }]),
  'Vista Tabla grande.',
  ['Cliente de la venta y datos del documento.', '<b>Agregar Producto</b>, escáner y promociones.', '<b>Con ISV / Sin ISV</b>.', 'Guardar en Espera, Ver en Espera, Ver Perdidas y Ver Facturas.', '<b>Pendientes de Impresión</b>.', 'Botón para cambiar de vista.', 'Líneas de la venta.', 'Total a pagar y <b>Crear Venta</b> en la barra inferior.']
)}

<h3>Registrar ventas desde el celular o la tableta</h3>
<p>En un celular, las mismas secciones se apilan en una sola columna y toda la pantalla se desplaza junta.</p>
${parMovil([
  ['m_venta_vacia.png', [{ n: 1, x: 300, y: 365 }, { n: 2, x: 345, y: 540 }, { n: 3, x: 520, y: 634 }, { n: 4, x: 390, y: 870 }, { n: 5, x: 160, y: 1457 }], 56],
  ['m_buscar_resultados.png', [{ n: 1, x: 360, y: 478 }, { n: 2, x: 270, y: 594 }, { n: 3, x: 200, y: 710 }, { n: 4, x: 270, y: 830 }, { n: 5, x: 180, y: 932 }, { n: 6, x: 390, y: 1190 }], 56],
])}
<div class="pie-par">Registrar Venta y Buscar Producto en un celular. En Registrar Venta: 1 vendedor, 2 botones de acciones, 3 pendientes de impresión, 4 datos del documento, 5 más datos. En Buscar Producto: 1 búsqueda, 2 vehículo y año, 3 productos o combos, 4 nivel de precio, 5 producto nuevo, 6 resultado.</div>
${parMovil([
  ['m_venta_con_item.png', [{ n: 1, x: 380, y: 427 }, { n: 2, x: 155, y: 980 }, { n: 3, x: 337, y: 1225 }, { n: 4, x: 390, y: 1330 }, { n: 5, x: 380, y: 1505 }], 56],
  ['m_tabla_grande.png', [{ n: 1, x: 137, y: 261 }, { n: 2, x: 447, y: 261 }, { n: 3, x: 382, y: 327 }, { n: 4, x: 739, y: 227 }, { n: 5, x: 696, y: 273 }, { n: 6, x: 402, y: 1565 }], 56],
])}
<div class="pie-par">Izquierda: venta con un repuesto agregado. 1 datos del documento, 2 más datos, 3 Agregar Producto, 4 Con ISV o Sin ISV, 5 línea del repuesto. Derecha: Tabla grande. 1 cliente, 2 Con ISV y Sin ISV, 3 barra de atajos que se desliza hacia los lados (Guardar en Espera, Ver en Espera, Pendientes de Impresión…), 4 contador de pendientes, 5 cambiar de vista, 6 total y Crear Venta.</div>
${consejo('En «Tabla grande» del celular, la barra de atajos se desliza hacia los lados: pase el dedo sobre ella para llegar a Ver Facturas, Ver Perdidas y Limpiar Venta. En la ventana ampliada «Productos en la venta» esos mismos atajos aparecen debajo del título.')}

<h3>Ver detalle, reimprimir y anular</h3>
<p>En <b>Ventas ▸ Ver Detalle</b> escriba el número del documento y presione Buscar. El detalle abre al instante y muestra los datos del documento, las líneas y los totales.</p>
${figura(
  captura('venta_detalle_cargada.png', [{ n: 1, x: 181, y: 177 }, { n: 2, x: 447, y: 192 }, { n: 3, x: 627, y: 192 }, { n: 4, x: 718, y: 277 }, { n: 5, x: 718, y: 476 }, { n: 6, x: 1305, y: 391 }, { n: 7, x: 718, y: 638 }, { n: 8, x: 400, y: 728 }]),
  'Detalle de una factura.',
  ['Número de documento a buscar.', 'Filtro por tipo de documento.', '<b>Buscar</b> y <b>Limpiar</b>.', 'Tipo, número, fecha, quién atendió, cliente, documento del cliente, condición, método de pago y estado.', 'Productos de la venta con cantidad, precio e importe.', 'Con ISV / Sin ISV.', 'Subtotal, ISV y total.', 'Acciones: <b>Reimprimir</b>, <b>Descargar PDF</b>, <b>Generar guía de envío</b>, <b>Duplicar venta</b> y <b>Anular Venta</b>.']
)}
<ul>
  <li><b>Reimprimir</b> el ticket o la factura (como copia o como original).</li>
  <li><b>Duplicar</b> la venta para repetirla.</li>
  <li><b>Convertir a venta</b> si es una cotización.</li>
  <li><b>Anular</b> la venta (según permisos): devuelve las existencias al lote del que salieron, cancela el crédito si no tiene abonos y deja constancia del motivo.</li>
</ul>
${cuidado('Una venta anulada no se puede reactivar. Si anuló por error, registre una venta nueva.')}
<p>En el celular esta pantalla se desplaza completa, sin dejar los controles de búsqueda fijos arriba.</p>
${parMovil([['m_detalle_venta.png', [{ n: 1, x: 386, y: 363 }, { n: 2, x: 386, y: 480 }, { n: 3, x: 127, y: 582 }, { n: 4, x: 386, y: 918 }], 56]])}
<div class="pie-par">Detalle de Venta en el celular. 1 número de documento, 2 tipo, 3 Buscar y Limpiar, 4 datos de la venta (más abajo siguen los productos, los totales y los botones).</div>

<h3>Imprimir</h3>
<p>Según la configuración, al crear la venta se muestra la vista previa o se imprime directo. Si el equipo no tiene impresora (por ejemplo el celular o el navegador), el sistema puede pedirle a la <b>PC principal</b> que imprima: el ticket sale en la caja sin que nadie haga nada. En <b>Pendientes de Impresión</b> quedan los tickets que no se pudieron imprimir. Todo esto se explica en el capítulo 13.</p>
${figura(
  captura('venta_pendientes_impresion.png', [{ n: 1, x: 640, y: 318 }, { n: 2, x: 891, y: 327 }]),
  'Pendientes de Impresión.',
  ['Cada venta con su cliente, documento, total y hora.', 'Imprime esa venta desde este equipo. Conviene abrir la lista en la PC que tiene la impresora.']
)}
`;

const cap8 = `
<p>Las compras se registran en <b>Compras ▸ Registrar Compra</b>. Sirven para aumentar existencias, actualizar costos y llevar las cuentas por pagar a proveedores.</p>
${figura(
  captura('compra_con_item.png', [{ n: 1, x: 580, y: 134 }, { n: 2, x: 573, y: 208 }, { n: 3, x: 1305, y: 304 }, { n: 4, x: 772, y: 392 }, { n: 5, x: 790, y: 456 }, { n: 6, x: 718, y: 837 }]),
  'Registrar Compra con un repuesto agregado.',
  ['<b>Limpiar Compra</b>, <b>Ver Compras</b>, <b>Ver Detalle</b> y <b>Compras en Espera</b>.', 'Fecha, <b>proveedor</b>, número de factura del proveedor, condición (contado o crédito) y método de pago. «Más datos» muestra los campos adicionales.', '<b>Agregar Producto</b>: abre el buscador (con el mismo filtro por vehículo y año).', 'Cantidad, costo unitario y descuento de cada línea.', '<b>Margen %</b> y <b>precio de venta</b>: si el costo cambió, puede ajustar el precio de venta ahí mismo y se aplica al repuesto al registrar la compra.', 'Subtotal, ISV y total a pagar.']
)}
${figura(
  captura('compra_buscar_producto.png', [{ n: 1, x: 188, y: 222 }, { n: 2, x: 1193, y: 291 }, { n: 3, x: 712, y: 336 }]),
  'Buscar Producto dentro de una compra.',
  ['Búsqueda (con filtro por vehículo y año).', 'En compras la columna de precio muestra el <b>costo</b> del repuesto.', 'Doble clic o Enter para agregarlo.']
)}
<h3>Registrar una compra</h3>
${pasos([
  ['Elija el proveedor y escriba el número de factura del proveedor.', 'La condición Crédito pide fecha de vencimiento y crea la cuenta por pagar.'],
  ['Agregue los repuestos.', 'Cantidad, costo unitario y descuento. Puede crear un repuesto nuevo desde el mismo buscador.'],
  ['Revise el precio de venta (opcional).', 'Si el costo cambió, puede ajustar el precio de venta ahí mismo.'],
  ['Registre la compra.', 'Las existencias suben y cada línea queda como un lote con su costo para el cálculo de utilidades.'],
])}
<ul>
  <li><b>Compras en espera:</b> guarda el borrador para continuar después.</li>
  <li><b>Ver Compras:</b> lista las compras registradas.</li>
</ul>

<h3>Ver compras y ver detalle</h3>
${figura(
  captura('compra_ver_compras.png', [{ n: 1, x: 49, y: 183 }, { n: 2, x: 103, y: 231 }, { n: 3, x: 515, y: 231 }, { n: 4, x: 736, y: 231 }]),
  'Ver Compras.',
  ['Rangos rápidos: Hoy, Ayer, 7 días y Este mes.', 'Fechas Desde y Hasta.', 'Buscador por proveedor, factura o número.', 'Filtros por estado y por condición (contado o crédito). Debajo se ve cuántas compras hay y el total.']
)}
${figura(
  captura('compra_detalle_cargada.png', [{ n: 1, x: 188, y: 177 }, { n: 2, x: 459, y: 192 }, { n: 3, x: 712, y: 295 }, { n: 4, x: 712, y: 521 }, { n: 5, x: 712, y: 747 }, { n: 6, x: 260, y: 835 }]),
  'Detalle de una compra a crédito.',
  ['Número de documento o de factura de la compra.', '<b>Buscar</b> y <b>Limpiar</b>.', 'Número de factura del proveedor, número de documento, fecha, quién la registró, proveedor, RTN, condición, vencimiento y estado.', 'Productos con cantidad, costo unitario, descuento e importe.', 'Subtotal, ISV y total a pagar.', '<b>Duplicar compra</b> y <b>Anular Compra</b> (según permisos). Al anular, el sistema resta las existencias que había sumado.']
)}
<p>En el celular esta pantalla se desplaza completa, sin dejar los controles de búsqueda fijos arriba.</p>

<h3>Hacer pedido</h3>
${figura(
  captura('compra_pedido.png', [{ n: 1, x: 176, y: 206 }, { n: 2, x: 510, y: 206 }, { n: 3, x: 1305, y: 300 }, { n: 4, x: 714, y: 488 }]),
  'Hacer Pedido.',
  ['Proveedor (opcional).', 'Observaciones (opcionales).', '<b>Agregar Producto</b> del inventario.', '<b>Generar PDF del Pedido</b>: arma la lista para enviar al proveedor. No registra ninguna compra.']
)}
${aviso('Si vendió un repuesto sin existencias («venta anticipada»), al registrar la compra del mismo repuesto el sistema le ofrece completar ese pendiente y corrige el costo real de aquella venta.', 'Pendientes de reposición')}
`;

module.exports = { cap5, cap6, cap7, cap8 };
