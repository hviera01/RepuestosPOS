const H = require('./helpers');
const { captura, parMovil } = require('./captura_helper');
const { datos, figura, aviso, consejo, cuidado, pasos } = H;

const cap9 = `
<p>Los créditos se manejan en <b>Créditos ▸ Ventas Crédito</b> (lo que los clientes le deben) y <b>Créditos ▸ Compras Crédito</b> (lo que usted le debe a sus proveedores).</p>
${figura(
  captura('ventas_credito.png', [{ n: 1, x: 297, y: 168 }, { n: 2, x: 125, y: 243 }, { n: 3, x: 400, y: 243 }, { n: 4, x: 900, y: 235 }, { n: 5, x: 108, y: 291 }, { n: 6, x: 56, y: 404 }, { n: 7, x: 700, y: 404 }, { n: 8, x: 1372, y: 404 }, { n: 9, x: 1198, y: 404 }]),
  'Ventas a Crédito.',
  ['<b>Total pendiente</b>: lo que los clientes deben en este momento.', 'Vista: <b>Deben</b>, Liquidadas o Todas.', 'Buscador por número de factura o por cliente.', '<b>Refrescar</b>, <b>Importar</b> créditos antiguos, <b>Descargar Excel</b>, <b>Descargar PDF</b> y <b>Unir Facturas</b> (se activa al marcar dos o más créditos).', '<b>Registrar Crédito</b>: para un crédito manual, por ejemplo saldos de antes del sistema.', 'Casilla para marcar el crédito (para unir facturas).', 'Fecha, factura, cliente, monto total, saldo pendiente y vencimiento. Si el cliente no tiene teléfono guardado, se avisa en rojo debajo de su nombre.', 'Menú de cada crédito.', '<b>Estado</b>: Debe, y <b>Vencida</b> cuando pasó la fecha de vencimiento y aún hay saldo.']
)}
${figura(
  captura('credito_menu_fila.png', [{ n: 1, x: 1190, y: 439 }, { n: 2, x: 1190, y: 481 }, { n: 3, x: 1190, y: 523 }, { n: 4, x: 1190, y: 565 }, { n: 5, x: 1190, y: 622 }]),
  'Menú de un crédito.',
  ['<b>Registrar abono</b>.', '<b>Ver historial de abonos</b>: todos los pagos del crédito, para editar o eliminar un abono.', '<b>Ver facturas unidas</b>: aparece en los créditos que son la unión de varias facturas.', '<b>Agregar teléfono</b>: guarda el teléfono del cliente para avisarle de saldos vencidos.', '<b>Eliminar</b> el crédito (pide la clave especial si así está configurado).']
)}
<h3>Cobrar un abono</h3>
${figura(
  captura('credito_abono.png', [{ n: 1, x: 712, y: 349 }, { n: 2, x: 712, y: 412 }, { n: 3, x: 712, y: 472 }, { n: 4, x: 712, y: 535 }, { n: 5, x: 712, y: 597 }, { n: 6, x: 712, y: 656 }, { n: 7, x: 850, y: 721 }]),
  'Registrar Abono.',
  ['<b>Monto abonado</b>.', 'Saldo anterior (lo que debía antes de este pago).', '<b>Interés</b> (opcional).', 'Saldo pendiente que queda después del abono.', 'Fecha del abono.', '<b>Método de pago</b>: efectivo, tarjeta, transferencia…', '<b>Registrar Abono</b>: baja el saldo, genera el número de recibo y permite imprimir el recibo.']
)}
${pasos([
  ['Busque el crédito del cliente.', 'Por nombre o por número de factura.'],
  ['Abra el menú del crédito ▸ Registrar abono.', 'Escriba el monto y elija el método de pago.'],
  ['Registre.', 'El saldo baja, se genera el número de recibo y puede imprimir el recibo para el cliente. El recibo sale en impresora térmica con línea de firma, como ORIGINAL y, si está activado en Configuración, también como COPIA. Desde un celular o tableta puede pedirle a la caja principal que lo imprima.'],
])}
<ul>
  <li>Puede <b>editar</b> o <b>eliminar</b> un abono ya registrado desde el historial de abonos; el sistema recalcula los saldos.</li>
  <li>Una venta registrada a crédito aparece aquí automáticamente; no hay que volver a escribirla.</li>
</ul>

<h3>Unir facturas</h3>
<p>Marque dos o más créditos del <b>mismo cliente</b> y presione <b>Unir Facturas</b>. Solo se pueden unir créditos que todavía tienen saldo pendiente. El sistema hace la unión en una sola operación: crea un crédito nuevo con la suma de los saldos y deja las facturas originales como unidas, o no hace nada si algo falla; nunca queda una unión a medias. Desde el menú del crédito unido, <b>Ver facturas unidas</b> muestra las facturas de origen y permite imprimirlas por separado o como un solo documento.</p>

<h3>Compras Crédito</h3>
${figura(
  captura('compras_credito.png', [{ n: 1, x: 324, y: 157 }, { n: 2, x: 121, y: 230 }, { n: 3, x: 1220, y: 222 }, { n: 4, x: 298, y: 278 }, { n: 5, x: 718, y: 430 }]),
  'Compras a Crédito.',
  ['Total pendiente: lo que usted debe a los proveedores.', 'Vista: Deudas, Liquidadas o Todas.', '<b>Resumen de abonos</b>: los pagos hechos a proveedores en un periodo.', '<b>Abono General</b>: un solo pago a un proveedor que el sistema reparte entre sus facturas, empezando por las más antiguas.', 'Lista de facturas por pagar con proveedor, monto, saldo y vencimiento.']
)}
<p>Funciona igual que Ventas Crédito, pero para las facturas que usted debe a los proveedores. El recibo de pago a proveedor también sale en ESC/POS, con línea de firma de quien recibe.</p>
${consejo('Revise las deudas vencidas al empezar el día. En el Reporte Financiero también verá cuánto tiene por cobrar y por pagar en total.')}
`;

const cap10 = `
<p>Si el negocio tiene más de un local, <b>Sucursales</b> y <b>Traslados</b> permiten mover mercadería entre ellos con control. En este sistema las existencias son una sola bolsa: al registrar un traslado, las unidades salen del inventario (igual que una venta) y quedan anotadas hacia la sucursal destino.</p>

<h3>Sucursales</h3>
${figura(
  captura('sucursales_lista.png', [{ n: 1, x: 568, y: 193 }, { n: 2, x: 1324, y: 195 }, { n: 3, x: 1255, y: 309 }]),
  'Lista de sucursales.',
  ['Buscador por nombre o dirección.', '<b>Nueva Sucursal</b> (solo administrador).', 'Cada sucursal con su estado. Las inactivas no aparecen al registrar traslados.']
)}

<h3>Registrar un traslado</h3>
${figura(
  captura('traslado_con_item.png', [{ n: 1, x: 154, y: 215 }, { n: 2, x: 483, y: 215 }, { n: 3, x: 781, y: 215 }, { n: 4, x: 1165, y: 222 }, { n: 5, x: 1332, y: 318 }, { n: 6, x: 175, y: 382 }, { n: 7, x: 1305, y: 382 }, { n: 8, x: 1296, y: 727 }]),
  'Registro de un traslado con un repuesto.',
  ['<b>Sucursal de origen</b>.', '<b>Sucursal de destino</b> (no puede ser la misma que la de origen).', 'Observaciones (opcional).', 'Estado con el que se crea: <b>Pendiente</b>, <b>Enviado</b> o <b>Entregado</b>.', '<b>Agregar</b> repuestos. «Ver más grande» abre la lista en una ventana completa.', 'El repuesto con su código, nombre y ubicación física en bodega (opcional en el comprobante).', 'Cantidad y el bote de basura para quitar la línea.', 'Total de unidades y <b>Registrar Traslado</b>: descuenta las existencias y imprime el comprobante con espacios para las firmas.']
)}
${datos(['Estado', 'Significado'], [
  ['Pendiente', 'Creado pero todavía no salió.'],
  ['Enviado', 'Salió de la sucursal origen.'],
  ['Entregado', 'La sucursal destino confirmó que lo recibió (se registra quién y cuándo).'],
  ['Anulado', 'Se canceló; las unidades vuelven al inventario.'],
])}
<p>Cuando la mercadería sale y llega en el mismo momento puede crear el traslado ya como <b>Entregado</b>. Si no, créelo como Pendiente o Enviado y use los botones <b>Enviar</b> y <b>Confirmar Recepción</b> en el detalle. Si hay un repuesto repetido en varias líneas, el sistema suma las cantidades y nunca deja el inventario en negativo.</p>

<h3>Ver detalle y reimprimir</h3>
<p>En <b>Traslados ▸ Ver Detalle</b> busque por número (puede escribir solo <code>123</code> en lugar de <code>TRAS-000123</code>). Desde el detalle se imprime el comprobante como original o copia y, si su usuario tiene permiso, se <b>anula</b>. Al anular, las unidades regresan al inventario y queda anotado en el historial de cada repuesto.</p>
<h4>Cuando una pantalla ya está abierta</h4>
<p>Si usted toca una pantalla que ya tiene abierta en otra pestaña, el sistema pregunta qué hacer.</p>
${figura(
  captura('traslado_detalle.png', [{ n: 1, x: 546, y: 391 }, { n: 2, x: 727, y: 477 }, { n: 3, x: 868, y: 477 }]),
  'Aviso al abrir una pantalla que ya está abierta.',
  ['«Ver Detalle ya está abierto». Pregunta si quiere seguir trabajando en esa pestaña o abrir una aparte.', '<b>Seguir ahí</b>: lo lleva a la pestaña que ya tenía.', '<b>Abrir pestaña nueva</b>: abre una copia independiente.']
)}

<h3>Reporte de traslados</h3>
<p>En <b>Reportes ▸ Traslados</b> filtre por rango de fechas, estado y sucursal, y exporte a PDF o Excel. En el historial de existencias de cada repuesto aparece cada traslado como «Traslado TRAS-000123 a SUCURSAL 2».</p>
`;

const cap11 = `
<h3>Su caja</h3>
<p>En <b>Reportes ▸ Caja</b> cada cajero maneja <b>su propia caja</b>. Se abre al empezar el turno con el efectivo con el que arranca y se cierra al terminar, contando el dinero. Lo que usted vende, cobra, paga y gasta mientras su caja está abierta se suma a <b>su</b> caja; lo de otro compañero se suma a la de él. La pantalla tiene dos pestañas: <b>Mi caja</b> e <b>Historial de cajas</b>.</p>

<h3>Abrir la caja</h3>
${figura(
  captura('caja.png', [{ n: 1, x: 160, y: 328 }, { n: 2, x: 360, y: 407 }, { n: 3, x: 200, y: 460 }, { n: 4, x: 1377, y: 514 }, { n: 5, x: 700, y: 594 }, { n: 6, x: 700, y: 820 }, { n: 7, x: 1343, y: 889 }], { recorte: 108 }),
  'Abrir caja.',
  ['<b>Fondo inicial en efectivo</b>: el efectivo con el que empieza (el cambio que deja en la gaveta). Puede ser 0.', '<b>Periodo que se cuenta</b>: Desde ahora (lo normal), Hoy, Ayer, Esta semana, Este mes o Desde mi último cierre. Cada botón rápido llena las fechas de abajo.', '<b>Desde</b> y <b>Hasta</b>: fecha y hora exactas, que se pueden cambiar con el reloj. «En vivo (hasta ahora)» significa que la caja sigue contando lo que vaya pasando.', '<b>Contar solo lo que pase desde que abro la caja</b>: encendido, no cuenta lo anterior; apagado, cuenta todo lo del periodo elegido aunque haya pasado antes de abrir.', '<b>Qué se cuenta en el efectivo</b> (solo administrador): ventas en efectivo, abonos de clientes, gastos pagados, pagos a proveedores y compras de contado. Lo que se apaga no entra en el efectivo esperado, aunque se sigue mostrando en el resumen.', 'Notas (opcional).', '<b>Abrir caja</b>. Solo puede tener una caja abierta a la vez.']
)}
${consejo('Abra la caja antes de la primera venta del día. Si la abre después, elija «Hoy» o escoja la hora en que empezó el turno para que cuente las ventas anteriores.')}

<h3>Con la caja abierta</h3>
${figura(
  captura('caja_abierta.png', [{ n: 1, x: 103, y: 231 }, { n: 2, x: 287, y: 231 }, { n: 3, x: 441, y: 231 }, { n: 4, x: 157, y: 286 }, { n: 5, x: 356, y: 420 }, { n: 6, x: 1061, y: 420 }, { n: 7, x: 356, y: 588 }, { n: 8, x: 356, y: 669 }]),
  'Caja abierta con el resumen en vivo.',
  ['<b>Fondo y periodo</b>: cambiar el fondo, las fechas o lo que se cuenta aunque la caja ya esté abierta. A quien no es administrador, el sistema le pide la clave especial si así se configuró.', '<b>Ver movimientos</b>: lista de lo que entró y salió en el periodo.', '<b>Cerrar caja</b>.', 'Desde cuándo cuenta la caja («en vivo»: sigue sumando).', '<b>Efectivo en caja</b>: fondo inicial, ventas en efectivo, abonos de clientes, gastos, pagos a proveedores y compras en efectivo.', '<b>Ventas</b> por forma de pago (efectivo, tarjeta, transferencia, cheque y crédito) y abonos con otros métodos. Lo que no es efectivo no suma a la gaveta; aparece aquí para cuadrar contra el banco o el datáfono.', '<b>Efectivo esperado</b>: fondo + ventas en efectivo + abonos en efectivo − gastos − pagos a proveedores − compras en efectivo. Es lo que debería haber en la gaveta.', 'Interruptores de lo que entra en el efectivo esperado (solo administrador).']
)}
${figura(
  captura('caja_fondo_periodo.png', [{ n: 1, x: 604, y: 246 }, { n: 2, x: 622, y: 322 }, { n: 3, x: 622, y: 383 }, { n: 4, x: 712, y: 584 }, { n: 5, x: 866, y: 817 }]),
  'Fondo y periodo de la caja.',
  ['Fondo inicial.', 'Botones rápidos de periodo.', 'Desde y hasta.', 'Qué entra en el efectivo.', '<b>Guardar cambios</b>.']
)}
<p>El resumen se recalcula solo cuando se registra una venta, un abono o un gasto: no hace falta recargar.</p>

<h3>Cerrar la caja</h3>
${figura(
  captura('caja_cerrar_lleno.png', [{ n: 1, x: 622, y: 400 }, { n: 2, x: 712, y: 448 }, { n: 3, x: 568, y: 515 }, { n: 4, x: 712, y: 580 }, { n: 5, x: 866, y: 656 }]),
  'Cerrar caja escribiendo el total contado.',
  ['<b>Contar billetes</b> (escriba cuántos billetes y monedas de cada denominación tiene, de L 500 a L 0.05; el sistema suma) o <b>Escribir total</b> si ya sabe el monto.', 'Efectivo contado.', '<b>Diferencia</b> contra lo esperado: en verde si cuadra, en rojo si hay faltante o sobrante.', 'Notas: son <b>obligatorias</b> cuando hay diferencia, para explicar qué pasó.', '<b>Cerrar caja</b>.']
)}
<p>Al cerrar, el sistema pregunta cómo desea el reporte: <b>PDF</b> o <b>Ticket</b>. El ticket sale en impresora térmica; desde un celular o tableta se puede pedir que lo imprima la caja principal. Desde ese momento la caja queda cerrada y puede abrir una nueva cuando empiece el siguiente turno.</p>
${cuidado('Cuente el dinero con calma y escriba lo que realmente hay, aunque no coincida. Una diferencia anotada con su motivo es normal; una caja «cuadrada» a la fuerza esconde errores.')}

<h3>Historial de cajas</h3>
${figura(
  captura('caja_historial.png', [{ n: 1, x: 712, y: 228 }, { n: 2, x: 712, y: 304 }, { n: 3, x: 712, y: 385 }, { n: 4, x: 1380, y: 297 }]),
  'Historial de cajas.',
  ['Rango de fechas (Hoy, Ayer, 7 días, 30 días o fechas exactas) y cuántas cajas hay.', 'Una caja que sigue <b>abierta</b>.', 'Una caja cerrada, con desde cuándo hasta cuándo se contó.', 'Total vendido y, si la hay, la diferencia (en rojo cuando falta dinero).']
)}
<p>El administrador ve las cajas de todos los cajeros; cada cajero ve las suyas. Al tocar una caja se abre su detalle completo y desde ahí se puede reimprimir el corte (ticket o PDF). Si una caja se cerró por error, la <b>última</b> caja cerrada de ese cajero se puede <b>reabrir</b> mientras no tenga otra abierta; al reabrirla se borra el conteo del cierre y vuelve a quedar abierta.</p>
${aviso('El efectivo estimado que muestra el Reporte Financiero se calcula con las cajas que están abiertas en este momento. Por eso conviene cerrar la caja todos los días.', 'Reporte financiero')}

<h3>Ingresos y egresos</h3>
${figura(
  captura('ingresos_egresos.png', [{ n: 1, x: 196, y: 212 }, { n: 2, x: 196, y: 406 }, { n: 3, x: 316, y: 406 }, { n: 4, x: 317, y: 743 }, { n: 5, x: 688, y: 206 }, { n: 6, x: 664, y: 328 }, { n: 7, x: 900, y: 600 }, { n: 8, x: 270, y: 150 }]),
  'Ingresos y Egresos.',
  ['<b>Registrar egreso</b>: gastos del negocio (alquiler, servicios, planilla, fletes y más).', 'Categoría del gasto.', 'El signo «+» permite crear una <b>categoría nueva</b> en el momento.', '<b>Registrar egreso</b> guarda el gasto. Antes se llenan fecha, monto, concepto, a quién se pagó, número de comprobante y método de pago. El interruptor <b>Pagado</b> decide si cuenta en la caja y en los reportes; apagado, el gasto queda pendiente.', 'Filtros de fecha, búsqueda, tipo, método, categoría y estado.', 'Totales del periodo: ingresos, pagos a proveedores, gastos del negocio, gastos de casa y utilidad.', 'Libro de movimientos: ventas de contado, abonos a créditos, compras de contado, pagos a proveedores y egresos, todo en una lista por fecha.', 'Exportar a Excel o PDF.']
)}
${aviso('Registre los egresos el mismo día. Si un gasto no se anota, el cierre de caja y la utilidad del reporte financiero quedan más altos de lo real.')}
`;

const cap12 = `
<p>Los reportes están en el módulo <b>Reportes</b>. Se calculan en el servidor y se actualizan solos cuando se registra una venta, aunque la pantalla ya esté abierta. Todos los de lista se pueden exportar a PDF o Excel. Todos abren por defecto en el día de <b>hoy</b>.</p>

<h3>Reporte de Ventas</h3>
${figura(
  captura('reporte_ventas.png', [{ n: 1, x: 316, y: 168 }, { n: 2, x: 200, y: 235 }, { n: 3, x: 230, y: 285 }, { n: 4, x: 570, y: 285 }, { n: 5, x: 850, y: 285 }, { n: 6, x: 1130, y: 285 }, { n: 7, x: 500, y: 342 }, { n: 8, x: 720, y: 550 }]),
  'Reporte de Ventas de hoy.',
  ['<b>Total facturado</b> del periodo y filtros aplicados.', 'Rangos rápidos: Hoy, Ayer, Semana, Mes y Trimestre.', 'Fechas Desde y Hasta.', 'Buscador por documento, cliente o método.', '<b>Buscar</b> y <b>Limpiar</b>.', '<b>Descargar Excel</b> y <b>Descargar PDF</b>.', 'Filtros por método de pago, condición, estado, tipo de documento y usuario.', 'Cada venta con su fecha, tipo, documento, cliente, total, pago, condición, usuario y estado. Las cotizaciones y las anuladas se distinguen y no suman al total.']
)}
<p>El <b>Reporte de Compras</b> funciona igual, con filtro por proveedor, condición y usuario. El <b>Reporte de Traslados</b> filtra por rango de fechas, estado y sucursal.</p>
${figura(
  captura('reporte_compras.png', [{ n: 1, x: 333, y: 155 }, { n: 2, x: 116, y: 222 }, { n: 3, x: 532, y: 271 }, { n: 4, x: 785, y: 271 }]),
  'Reporte de Compras.',
  ['Total del periodo.', 'Rangos rápidos y fechas.', 'Filtro por proveedor.', 'Buscador por factura o proveedor.']
)}

<h3>Reporte Financiero</h3>
${figura(
  captura('reporte_financiero.png', [{ n: 1, x: 492, y: 143 }, { n: 2, x: 799, y: 143 }, { n: 3, x: 67, y: 208 }, { n: 4, x: 537, y: 293 }, { n: 5, x: 356, y: 445 }, { n: 6, x: 718, y: 765 }]),
  'Reporte Financiero, pestaña Utilidad.',
  ['Fechas y botón <b>Generar</b>.', '<b>Descargar PDF completo</b>: todo el reporte en un solo PDF (se arma sin congelar la pantalla).', 'Rangos rápidos.', 'Pestañas: Utilidad, Flujo de Efectivo, Comparación Mensual, Ranking de Productos, Sin Movimiento, Ventas por Usuario, Abonos a Proveedores, Recomendación de Pago, Balance General e Inteligencia de Negocios.', '<b>Utilidad</b>: ventas con ISV menos el costo de ventas dan la utilidad bruta; a esa se le restan los gastos (egresos) y queda la utilidad neta.', '<b>Ganancia por Venta</b>: cada venta con su costo, su ganancia y su margen.']
)}
<h4>Cómo leer la utilidad</h4>
<p>La <b>utilidad bruta</b> usa el costo real de cada repuesto vendido, tomado del lote del que salió (primero que entra, primero que sale). La <b>utilidad neta</b> resta además los egresos registrados. Por eso es importante registrar todas las compras con su costo correcto y anotar los gastos.</p>

<h3>Resumen del Día</h3>
<p>El <b>Resumen del Día</b> reúne en una sola pantalla todo lo que pasó en un periodo: cuánto se vendió, cuánto dinero entró y salió, qué se compró, qué gastos hubo y todo lo que se hizo en el sistema.</p>
${figura(
  captura('resumen_dia.png', [{ n: 1, x: 1196, y: 136 }, { n: 2, x: 49, y: 183 }, { n: 3, x: 175, y: 250 }, { n: 4, x: 175, y: 421 }, { n: 5, x: 898, y: 421 }]),
  'Resumen del Día de hoy.',
  ['<b>PDF</b> y <b>Ticket</b>: el resumen completo en PDF o un ticket para la impresora térmica. A su lado, el botón de actualizar.', 'Periodo: Hoy, Ayer, 7 días, Este mes o fechas exactas. El administrador puede además elegir un usuario.', 'Indicadores: ventas del periodo, cantidad de ventas, ticket promedio, utilidad bruta, lo que entró y salió en efectivo, neto en efectivo e ISV cobrado.', 'Ventas por forma de pago.', 'Ventas por hora.']
)}
<p>Más abajo siguen: ventas por tipo de documento, ventas por usuario, compras y pagos (de contado y a crédito), gastos y otros (egresos por categoría, traslados, ventas anuladas y cotizaciones), productos más vendidos y mejores clientes. Al final está <b>Todo lo que se hizo</b>: la lista de cada operación del periodo (ventas, abonos, compras, pagos, egresos, traslados…) con un buscador y botones para filtrar por tipo.</p>
${parMovil([['m_resumen.png', [{ n: 1, x: 545, y: 265 }, { n: 2, x: 94, y: 355 }, { n: 3, x: 392, y: 623 }, { n: 4, x: 392, y: 1192 }], 56]])}
<div class="pie-par">Resumen del Día en un celular. 1: PDF, Ticket y actualizar. 2: periodo. 3: indicadores, de dos en dos. 4: ventas por forma de pago; debajo siguen las demás tarjetas.</div>
${consejo('En ventas con muchos meses de datos, elija rangos de un mes o menos: los reportes cargan más rápido y son más fáciles de revisar.')}
`;

const cap13 = `
<p>El sistema imprime tickets en impresoras térmicas de 58 o 80 mm y también genera PDF. La configuración está en <b>Configuración</b> (capítulo 3); el funcionamiento detallado, incluida la impresión remota, está en el capítulo 13.</p>
`;

const cap14 = `
<h3>Varios equipos trabajando a la vez</h3>
<p>Puede haber varias cajas, el administrador consultando reportes desde su celular y un encargado en otra sucursal, todos al mismo tiempo. El sistema está preparado para eso:</p>
<ul>
  <li>Dos personas pueden vender el mismo repuesto a la vez sin que se descuente mal: el servidor procesa cada venta, compra, traslado y ajuste de inventario bloqueando las existencias de cada repuesto en un orden fijo, así que una operación espera a la otra en lugar de pisarla.</li>
  <li>La numeración de documentos nunca se repite, aunque dos cajas registren en el mismo segundo.</li>
  <li>Una orden de impresión remota se imprime una sola vez: la PC principal la «reclama» en una sola operación en el servidor, y si otra computadora quisiera tomarla, ya no está disponible.</li>
  <li>Unir facturas, abonos y anulaciones se hacen completos o no se hacen: no quedan operaciones a medias.</li>
  <li>Los cambios (precios, clientes, existencias) aparecen en los demás equipos en pocos segundos, sin refrescar.</li>
</ul>
${aviso('Lo único que se escribe «a ciegas» es la importación de inventario desde Excel, que sí reemplaza la existencia con el número del archivo. Úsela cuando nadie esté vendiendo.', 'Importar inventario')}

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
  ['Navegador web', 'Se actualiza al recargar la página. Si sigue viendo la versión anterior, use el botón de refrescar de la barra superior (hace lo mismo que Ctrl+F5 y limpia lo guardado en el navegador).'],
])}
<p>En <b>Mantenedor ▸ Dispositivos</b> el administrador ve la versión de cada equipo y cuáles están desactualizados.</p>
${consejo('Si un equipo no actualiza, descargue el instalador más reciente de la página de versiones del sistema e instálelo encima: se conservan todos los datos, que están en la nube.')}
`;

const cap15 = `
${datos(['Problema', 'Causa probable', 'Qué hacer'], [
  ['No puedo ingresar', 'Código o contraseña incorrectos, o cuenta bloqueada por intentos fallidos', 'Espere 5 minutos y reintente. Si olvidó la contraseña, el administrador puede cambiarla en Usuarios.'],
  ['No veo un módulo del menú', 'Su usuario no tiene esa pantalla permitida', 'Pídale al administrador que la marque en su usuario.'],
  ['Un botón (anular, crear…) no aparece', 'Esa acción no está permitida para su usuario', 'Pídale al administrador que la active en «Acciones permitidas».'],
  ['El sistema pide una clave especial', 'La acción está protegida', 'Pida la clave al administrador. No se comparte.'],
  ['No encuentro un repuesto', 'La búsqueda exige todas las palabras escritas', 'Escriba menos palabras o use solo el código; revise que el repuesto esté activo.'],
  ['El repuesto no sale al filtrar por vehículo', 'No tiene ese vehículo registrado', 'Abra su ficha y agregue el vehículo y los años en «Vehículos compatibles».'],
  ['Dice «Ya existe un producto con ese código»', 'Otro repuesto usa ese código', 'Use otro código o busque el repuesto existente.'],
  ['No me deja agregar un repuesto a la venta: «no tiene existencia disponible»', 'Por defecto el sistema no vende lo que no tiene en existencia', 'Registre la compra o un ajuste de ingreso. Si necesita venderlo igual, el administrador debe activar «Permitir vender un producto sin existencia» y la clave especial.'],
  ['No puedo abrir mi caja: ya hay una caja abierta', 'Quedó una caja abierta de un día anterior', 'Entre a Caja ▸ Mi caja, ciérrela con su conteo y luego abra la nueva.'],
  ['Al cerrar la caja pide una nota', 'Hay diferencia entre lo esperado y lo contado', 'Escriba el motivo de la diferencia; es obligatorio para dejar constancia.'],
  ['Falta una venta en el reporte', 'Otro rango de fechas, o la venta se guardó en espera / es una cotización', 'Revise «Ver en Espera» y el tipo de documento. Las cotizaciones y anuladas no suman.'],
  ['El ticket sale en blanco o sin cortar', 'La impresora no entiende la impresión directa', 'Active «Impresora especial» en Configuración ▸ Impresoras.'],
  ['El ticket sale cortado de los lados', 'Ancho de rollo mal configurado', 'Revise 58 u 80 mm en Configuración ▸ Impresoras.'],
  ['La venta dice «se envió a la caja principal» pero no sale', 'La PC principal está apagada, sin impresora o sin el sistema abierto', 'Ábralo en esa PC. Las órdenes quedan en Pendientes de Impresión.'],
  ['Los colores se ven mal', 'Color principal demasiado claro', 'Elija otro en Configuración ▸ Apariencia, o use «Restablecer».'],
  ['El sistema se ve lento', 'Conexión a internet débil', 'Compruebe la señal del equipo; las listas guardadas se muestran igual, y las operaciones se reintentan solas.'],
  ['En la web veo una versión vieja', 'El navegador guardó archivos anteriores', 'Use el botón de refrescar de la barra superior.'],
  ['La versión de un equipo no cambia', 'Instalador viejo guardado en Descargas', 'Use la actualización dentro del programa o descargue el instalador más reciente.'],
])}
<h3>Buenas prácticas</h3>
<ul>
  <li>Un usuario por persona, y desactive a quien ya no trabaja en el negocio.</li>
  <li>Registre las compras el mismo día, con el costo real: de eso depende la utilidad.</li>
  <li>Haga el cierre de caja todos los días y anote los egresos.</li>
  <li>Use siempre <b>Ver Detalle</b> antes de repetir una operación que pareció no completarse.</li>
  <li>Registre los vehículos compatibles al crear cada repuesto: ahorra mucho tiempo al buscar.</li>
  <li>Cambie la clave especial si sospecha que alguien la conoce.</li>
  <li>Deje la PC de la caja encendida y con el sistema abierto durante el horario de atención.</li>
</ul>
`;

module.exports = { cap9, cap10, cap11, cap12, cap13, cap14, cap15 };
