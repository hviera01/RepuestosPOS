const fs = require('fs');
const path = require('path');
const A = require('./capitulos_a');
const B = require('./capitulos_b');
const C = require('./capitulos_c');
const D = require('./capitulos_d');
const E = require('./capitulos_e');

const capitulos = [
  ['Bienvenida', A.cap1, 'que es sistema autoparts equipos requisitos windows android navegador'],
  ['Primeros pasos', A.cap2, 'ingresar entrar login iniciar sesion menu pestanas inicio salir cerrar sesion'],
  ['Configuración del negocio', A.cap3, 'configurar negocio datos logo rtn cai color impresora factura clave especial numeracion'],
  ['Usuarios, roles y permisos', A.cap4, 'usuario empleado cajero rol permiso clave especial contrasena encargado administrador'],
  ['Inventario y vehículos compatibles', B.cap5, 'producto repuesto inventario existencia stock precio categoria vehiculo ajuste historial promocion'],
  ['Clientes y proveedores', B.cap6, 'cliente proveedor registrar datos dni rtn'],
  ['Ventas', B.cap7, 'venta vender factura cotizacion cobrar pago credito descuento anular reimprimir carrito'],
  ['Compras', B.cap8, 'compra comprar proveedor costo pedido factura proveedor'],
  ['Créditos y cobros', C.cap9, 'credito abono deuda cobrar cuenta por cobrar pagar unir facturas saldo'],
  ['Sucursales y traslados', C.cap10, 'sucursal traslado mover mercaderia bodega transferir'],
  ['Caja, ingresos y egresos', C.cap11, 'caja abrir cerrar cierre corte efectivo gasto egreso ingreso arqueo billetes'],
  ['Reportes', C.cap12, 'reporte informe ventas compras utilidad ganancia resumen del dia financiero estadistica'],
  ['Impresión e impresión remota', D.capImpresion, 'imprimir impresora ticket recibo papel remota pc principal pendientes termica'],
  ['Escanear con el celular', D.capEscaner, 'escanear codigo de barras lector camara celular qr'],
  ['Varios equipos, internet y actualizaciones', C.cap14, 'varios equipos internet conexion actualizar version sin conflicto'],
  ['Instalación, seguridad y respaldo', D.capInstalacion, 'instalar descargar apk exe seguridad respaldo primer ingreso'],
  ['Problemas frecuentes y buenas prácticas', C.cap15, 'problema error falla no funciona solucion ayuda'],
  ['Glosario', E.capGlosario, 'significado palabras definicion glosario termino'],
];

const slug = (t) => t.toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '').replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
const quitarTags = (h) => h.replace(/<[^>]+>/g, ' ').replace(/&nbsp;/g, ' ').replace(/&amp;/g, '&').replace(/\s+/g, ' ').trim();
const imgWeb = (h) => h.replace(/src="capturas\/([^"]+)\.png"/g, 'src="img/$1.webp" loading="lazy"');

const articulos = [];
capitulos.forEach(([titulo, html, claves], i) => {
  const n = i + 1;
  const partes = html.split(/<h3>/);
  const intro = partes.shift();
  if (quitarTags(intro).length > 40) {
    articulos.push({ id: `c${n}-intro`, cap: n, capTitulo: titulo, titulo: `${titulo}: introducción`, claves, html: imgWeb(intro) });
  }
  for (const p of partes) {
    const m = p.match(/^(.*?)<\/h3>([\s\S]*)$/);
    if (!m) continue;
    const t = quitarTags(m[1]);
    articulos.push({ id: `c${n}-${slug(t)}`, cap: n, capTitulo: titulo, titulo: t, claves, html: imgWeb(m[2]) });
  }
});
for (const a of articulos) a.texto = quitarTags(a.html);

const buscar = (cap, sub) => {
  const r = articulos.find((a) => a.cap === cap && slug(a.titulo).includes(slug(sub)));
  if (!r) throw new Error('No hay artículo ' + cap + ' ' + sub);
  return r.id;
};

const G = (id, titulo, palabras, pasos, ver, img, basico = false, nota = '') => ({
  id, titulo, palabras, pasos, ver: ver.map(([c, s]) => buscar(c, s)), img: img ? `img/${img}.webp` : '', basico, nota,
});

const guias = [
  G('crear-usuario', 'Crear un usuario', 'nuevo usuario empleado cajero vendedor agregar persona rol encargado permisos',
    ['Abra el menú ▸ <b>Usuarios</b> (solo el administrador la ve).', 'Presione <b>Nuevo Usuario</b>.', 'Escriba el <b>código de acceso</b> (con él entra la persona), el <b>nombre completo</b> y una <b>contraseña</b>.', 'Elija el <b>rol</b>: Administrador, Semi Administrador, Empleado o Encargado.', 'Con el rol <b>Encargado</b> marque las pantallas que podrá ver y, más abajo, las acciones que podrá hacer (anular, crear, editar…).', 'Presione <b>Guardar</b>.'],
    [[4, 'crear un usuario'], [4, 'roles']], 'usuario_encargado', true),
  G('editar-usuario', 'Editar un usuario o cambiar su contraseña', 'editar usuario modificar cambiar contrasena clave password cambiar rol permisos olvido',
    ['Menú ▸ <b>Usuarios</b>.', 'Busque a la persona por nombre o código y toque su fila.', 'Cambie lo que necesite: nombre, rol, pantallas y acciones permitidas.', 'Para cambiar la contraseña escriba la nueva en <b>Nueva contraseña (opcional)</b>; si lo deja vacío no cambia.', 'Presione <b>Guardar</b>.'],
    [[4, 'crear un usuario']], 'usuarios_lista', true),
  G('desactivar-usuario', 'Desactivar o eliminar a un usuario', 'desactivar usuario eliminar borrar quitar despedir ya no trabaja bloquear',
    ['Menú ▸ <b>Usuarios</b> y toque la fila de la persona.', 'Apague el interruptor <b>Estado</b> (queda Inactivo y ya no puede ingresar; se conserva su historial).', 'Presione <b>Guardar</b>.', 'Solo si de verdad quiere borrarlo, use el bote de basura de abajo a la izquierda.'],
    [[4, 'crear un usuario']], 'usuario_nuevo'),
  G('crear-producto', 'Crear un producto (repuesto) nuevo', 'crear producto nuevo repuesto agregar articulo inventario registrar alta precio existencia',
    ['Menú ▸ <b>Mantenedor ▸ Inventario</b> y presione <b>Nuevo Producto</b>.', 'Escriba el <b>nombre</b>. El código se genera solo si lo deja vacío.', 'Elija la <b>categoría</b> (se baja con el desplazamiento de la ventana).', 'Escriba la <b>existencia inicial</b>, el <b>precio de compra</b> y el <b>precio de venta</b>.', 'Opcional: foto, ubicación física, descripción y vehículos compatibles.', 'Presione <b>Guardar</b>.'],
    [[5, 'crear un repuesto']], 'producto_vehiculos', true),
  G('vehiculos-compatibles', 'Agregar vehículos compatibles a un producto', 'vehiculo compatible marca modelo ano toyota hilux carro compatibilidad nombre automatico',
    ['En la ficha del producto deje encendido <b>Vehículos compatibles</b>.', 'Presione <b>Agregar vehículo</b>.', 'Escriba marca, modelo, año desde y año hasta (hasta vacío = en adelante).', 'Con <b>Armar el nombre automáticamente</b> encendido, el nombre se completa solo (por ejemplo «… TOYOTA HILUX 05-15»).', 'Guarde el producto.'],
    [[5, 'crear un repuesto']], 'producto_vehiculos'),
  G('editar-producto', 'Editar un producto o cambiar su precio', 'editar producto modificar cambiar precio nombre repuesto actualizar costo',
    ['Menú ▸ <b>Mantenedor ▸ Inventario</b>.', 'Busque el producto (escriba y presione Enter).', 'En su fila toque los tres puntos ▸ <b>Editar producto</b>.', 'Cambie los datos y presione <b>Guardar</b>.', 'Si cambia un precio, el sistema puede pedir la <b>clave especial</b> (según la configuración).'],
    [[5, 'menú de cada repuesto']], 'inv_menu_fila', true),
  G('buscar-producto', 'Buscar un producto en el inventario', 'buscar producto repuesto encontrar inventario codigo barras vehiculo ano filtro',
    ['Menú ▸ <b>Mantenedor ▸ Inventario</b>.', 'Escriba lo que busca (nombre, código o parte del nombre) y presione <b>Enter</b>. Todas las palabras deben aparecer.', 'Para buscar por carro: escriba el vehículo (por ejemplo «toyota hilux») y el año, y presione Enter.', 'También puede escanear el código de barras con el icono del lector.', 'Para ver todo, cambie la vista a <b>Mostrar todos</b>.'],
    [[5, 'buscar un repuesto']], 'inventario_resultados'),
  G('ajustar-existencia', 'Sumar o restar existencias (ajustar inventario)', 'ajustar existencia stock inventario sumar restar ingreso salida cantidad unidades corregir',
    ['Menú ▸ <b>Mantenedor ▸ Inventario</b> y busque el producto.', 'Tres puntos de su fila ▸ <b>Ajustar existencia</b>.', 'Elija <b>Ingreso</b> (suma) o <b>Salida</b> (resta).', 'Escriba la cantidad y, en un ingreso, el costo unitario. Opcional: el motivo.', 'Presione <b>Guardar</b> (puede pedir la clave especial).'],
    [[5, 'ajustar existencias']], 'inv_ajustar', true),
  G('historial-existencia', 'Ver el historial de existencia de un producto', 'historial existencia movimientos producto kardex stock cuando salio entro',
    ['Inventario ▸ busque el producto.', 'Tres puntos ▸ <b>Historial de existencia</b>.', 'Use las pestañas: Movimientos, Ventas, Compras, Traslados, Ajustes manuales o Lotes de costo.', 'Filtre por fechas con <b>Desde</b> y <b>Hasta</b>.'],
    [[5, 'historial de existencia']], 'inv_historial'),
  G('hacer-venta', 'Hacer una venta', 'venta vender factura cobrar cliente carrito crear venta registrar agregar producto efectivo tarjeta',
    ['Menú ▸ <b>Ventas ▸ Registrar Venta</b>.', 'Elija el <b>tipo de documento</b> (Factura, Venta o Cotización) y, si quiere, escriba el cliente.', 'Presione <b>Agregar Producto</b>, escriba lo que busca, presione Enter y haga <b>doble clic</b> en el repuesto (o selecciónelo y Enter).', 'Revise cantidad, precio y descuento de cada línea.', 'Elija el <b>método de pago</b> (efectivo, tarjeta, transferencia, cheque o mixto).', 'Presione <b>Crear Venta</b>. Se imprime el ticket según su configuración.'],
    [[7, 'registrar una venta paso a paso'], [7, 'buscar repuestos']], 'venta_con_items', true),
  G('venta-credito', 'Hacer una venta a crédito', 'venta credito fiado a plazo abono deuda cliente vencimiento',
    ['En Registrar Venta arme la venta como siempre.', 'Cambie la <b>Condición</b> de Contado a <b>Crédito</b>.', 'Escriba el cliente, la fecha de vencimiento y un teléfono para avisos.', 'Presione <b>Crear Venta</b>: no se cobra nada ahora y la venta queda en <b>Créditos ▸ Ventas Crédito</b>.'],
    [[7, 'forma de pago'], [9, 'cobrar un abono']], 'venta_metodo_pago'),
  G('cotizacion', 'Hacer una cotización', 'cotizacion cotizar presupuesto precio sin vender proforma',
    ['Registrar Venta ▸ en <b>Tipo de documento</b> elija <b>Cotización sin ISV</b> o <b>Cotización con ISV</b>.', 'Agregue los productos (se pueden agregar aunque no tengan existencia).', 'Registre: no descuenta existencias ni suma a las ventas.', 'Más tarde, en <b>Ver Detalle</b>, use <b>Convertir a venta</b> si el cliente acepta.'],
    [[7, 'cotizaciones']], 'venta_tipo_documento'),
  G('venta-mixta', 'Cobrar una venta con dos formas de pago (mixto)', 'pago mixto dividir efectivo tarjeta transferencia dos metodos',
    ['En Registrar Venta cambie el <b>Método de pago</b> a <b>Mixto</b>.', 'Reparta el total entre los métodos (por ejemplo parte en efectivo y el resto con tarjeta).', 'Presione <b>Crear Venta</b>. El cierre de caja reparte cada parte en su método.'],
    [[7, 'forma de pago']], 'venta_metodo_pago'),
  G('guardar-espera', 'Guardar una venta en espera y retomarla', 'espera guardar venta apartar retomar pendiente perdida recuperar',
    ['En Registrar Venta presione <b>Guardar en Espera</b> (aparta las existencias).', 'Para retomarla use <b>Ver en Espera</b> y elíjala.', 'Si se cerró la pestaña o se fue la luz, use <b>Ver Perdidas</b> para recuperar la venta en curso.'],
    [[7, 'ventas en espera']], 'venta_ver_perdidas'),
  G('anular-venta', 'Anular una venta', 'anular venta cancelar eliminar devolver factura error',
    ['Menú ▸ <b>Ventas ▸ Ver Detalle</b>.', 'Escriba el número del documento y presione <b>Buscar</b>.', 'Presione <b>Anular Venta</b> y escriba el motivo (su usuario necesita el permiso).', 'Se devuelven las existencias y, si era a crédito sin abonos, se cancela el crédito.', 'Una venta anulada no se puede reactivar: si fue un error, registre una nueva.'],
    [[7, 'ver detalle']], 'venta_detalle_cargada'),
  G('reimprimir-venta', 'Reimprimir un ticket o una factura', 'reimprimir imprimir otra vez copia ticket factura venta pdf',
    ['Menú ▸ <b>Ventas ▸ Ver Detalle</b>.', 'Busque el documento por su número.', 'Presione <b>Reimprimir</b> (original o copia) o <b>Descargar PDF</b>.', 'Desde un celular, el ticket se manda a la caja principal para que lo imprima.'],
    [[7, 'ver detalle'], [13, 'imprimir en la caja principal']], 'venta_detalle_cargada'),
  G('registrar-compra', 'Registrar una compra a un proveedor', 'compra comprar proveedor registrar factura costo mercaderia entrada ingreso inventario',
    ['Menú ▸ <b>Compras ▸ Registrar Compra</b>.', 'Elija el proveedor y escriba el número de factura del proveedor.', 'Elija la condición: Contado o Crédito (con vencimiento).', 'Presione <b>Agregar Producto</b> y agregue cada repuesto con su cantidad y costo.', 'Si el costo cambió, ajuste el precio de venta en la misma línea.', 'Registre la compra: las existencias suben y queda el lote de costo.'],
    [[8, 'registrar una compra']], 'compra_con_item', true),
  G('pedido-proveedor', 'Hacer un pedido para un proveedor', 'pedido proveedor pedir lista pdf comprar orden',
    ['Menú ▸ <b>Compras ▸ Hacer Pedido</b>.', 'Elija el proveedor (opcional) y agregue los productos con <b>Agregar Producto</b>.', 'Presione <b>Generar PDF del Pedido</b>. No registra ninguna compra.'],
    [[8, 'hacer pedido']], 'compra_pedido'),
  G('cobrar-abono', 'Cobrar un abono a un cliente', 'abono cobrar pago cliente credito deuda saldo recibo pagar',
    ['Menú ▸ <b>Créditos ▸ Ventas Crédito</b>.', 'Busque al cliente o la factura.', 'Tres puntos del crédito ▸ <b>Registrar abono</b>.', 'Escriba el monto, la fecha y el método de pago.', 'Presione <b>Registrar Abono</b> y, si quiere, imprima el recibo.'],
    [[9, 'cobrar un abono']], 'credito_abono', true),
  G('pagar-proveedor', 'Pagar a un proveedor (abono)', 'pagar proveedor abono compras credito deuda abono general factura',
    ['Menú ▸ <b>Créditos ▸ Compras Crédito</b>.', 'Para una factura: tres puntos ▸ abonar. Para pagar varias a la vez: <b>Abono General</b> (se reparte entre las facturas más antiguas).', 'Escriba monto y método de pago y registre.'],
    [[9, 'compras crédito']], 'compras_credito'),
  G('unir-facturas', 'Unir varias facturas de crédito en una', 'unir facturas credito juntar fusionar cliente saldo',
    ['<b>Créditos ▸ Ventas Crédito</b>.', 'Marque con la casilla dos o más créditos <b>del mismo cliente</b> con saldo pendiente.', 'Presione <b>Unir Facturas</b> y confirme.', 'Para ver o imprimir las originales: tres puntos ▸ <b>Ver facturas unidas</b>.'],
    [[9, 'unir facturas']], 'ventas_credito'),
  G('abrir-caja', 'Abrir la caja', 'abrir caja apertura turno fondo inicial efectivo empezar',
    ['Menú ▸ <b>Reportes ▸ Caja</b> (pestaña <b>Mi caja</b>).', 'Escriba el <b>fondo inicial</b> (puede ser 0).', 'Elija el periodo que se cuenta (lo normal es «Desde ahora»).', 'Presione <b>Abrir caja</b>. Solo puede haber una abierta por persona.'],
    [[11, 'abrir la caja']], 'caja', true),
  G('cerrar-caja', 'Cerrar la caja (contar el dinero)', 'cerrar caja cierre corte contar dinero billetes diferencia faltante sobrante arqueo',
    ['Reportes ▸ <b>Caja</b> ▸ <b>Cerrar caja</b>.', 'Cuente los billetes (o use <b>Escribir total</b>).', 'Revise la <b>diferencia</b> contra el efectivo esperado; si hay diferencia, escriba la nota.', 'Presione <b>Cerrar caja</b> y elija <b>PDF</b> o <b>Ticket</b> para el reporte.'],
    [[11, 'cerrar la caja']], 'caja_cerrar_lleno', true),
  G('cambiar-caja', 'Cambiar el fondo o el periodo de una caja abierta', 'caja fondo periodo cambiar editar fecha efectivo abierta corregir',
    ['Reportes ▸ Caja ▸ <b>Fondo y periodo</b>.', 'Cambie el fondo, desde/hasta o qué entra en el efectivo.', '<b>Guardar cambios</b> (a quien no es administrador se le puede pedir la clave especial).'],
    [[11, 'con la caja abierta']], 'caja_fondo_periodo'),
  G('registrar-gasto', 'Registrar un gasto (egreso)', 'gasto egreso pagar luz agua alquiler planilla flete servicio salida dinero comprobante',
    ['Menú ▸ <b>Reportes ▸ Ingresos-Egresos</b>.', 'En <b>Registrar egreso</b> llene fecha, monto, categoría y concepto.', 'Opcional: a quién se pagó y número de comprobante. Elija el método de pago.', 'Deje <b>Pagado</b> encendido si ya se pagó (cuenta en la caja y los reportes).', 'Presione <b>Registrar egreso</b>.'],
    [[11, 'ingresos y egresos']], 'ingresos_egresos', true),
  G('reporte-ventas', 'Ver las ventas (reporte de ventas)', 'reporte ventas ver ventas del dia mes semana total vendido informe listado excel pdf',
    ['Menú ▸ <b>Reportes ▸ Reporte de Ventas</b>.', 'Elija el rango: Hoy, Ayer, Semana, Mes o Trimestre (o fechas exactas).', 'Filtre por método de pago, estado, tipo de documento o usuario si quiere.', 'Para guardar: <b>Descargar Excel</b> o <b>Descargar PDF</b>.'],
    [[12, 'reporte de ventas']], 'reporte_ventas', true),
  G('resumen-dia', 'Ver el resumen del día', 'resumen del dia reporte hoy todo lo que paso ventas dinero entro salio ticket pdf',
    ['Menú ▸ <b>Reportes ▸ Resumen del Día</b>.', 'Elija Hoy, Ayer, 7 días, Este mes o fechas exactas.', 'Mire los indicadores y las tarjetas (formas de pago, horas, usuarios, productos más vendidos…).', 'Al final está la lista de todo lo que se hizo, con buscador.', 'Use <b>PDF</b> o <b>Ticket</b> para sacarlo.'],
    [[12, 'resumen del día']], 'resumen_dia', true),
  G('reporte-financiero', 'Ver la utilidad y los reportes financieros', 'utilidad ganancia financiero reporte margen costo balance flujo efectivo cuentas por cobrar pagar',
    ['Menú ▸ <b>Reportes ▸ Reporte Financiero</b> (solo administrador).', 'Elija el rango y presione <b>Generar</b>.', 'Recorra las pestañas: Utilidad, Flujo de Efectivo, Ranking de Productos, Balance General…', '<b>Descargar PDF completo</b> para tener todo junto.'],
    [[12, 'reporte financiero']], 'reporte_financiero'),
  G('crear-cliente', 'Crear un cliente', 'cliente nuevo crear agregar registrar comprador dni telefono',
    ['Menú ▸ <b>Clientes</b> ▸ <b>Nuevo Cliente</b>.', 'Escriba el DNI o RTN (opcional), el nombre y, si quiere, dirección y teléfono.', 'Presione <b>Guardar</b>.', 'Para ver sus créditos y compras: tres puntos de su fila ▸ <b>Ver detalle</b>.'],
    [[6, 'clientes']], 'cliente_nuevo'),
  G('editar-cliente', 'Editar o eliminar un cliente o un proveedor', 'editar cliente eliminar borrar quitar proveedor modificar cambiar datos telefono direccion',
    ['Menú ▸ <b>Clientes</b> (o <b>Proveedores</b>) y busque a la persona o empresa.', 'En su fila toque los tres puntos.', 'Elija <b>Editar</b> para cambiar sus datos y presione <b>Guardar</b>, o <b>Eliminar</b> para borrarlo (su usuario necesita el permiso).', 'Para ver sus créditos y compras, en clientes use <b>Ver detalle</b>.'],
    [[6, 'clientes']], 'cliente_menu'),
  G('crear-proveedor', 'Crear un proveedor', 'proveedor nuevo crear agregar registrar empresa rtn',
    ['Menú ▸ <b>Proveedores</b> ▸ <b>Nuevo Proveedor</b>.', 'Escriba RTN (opcional), razón social, correo y teléfono.', 'Presione <b>Guardar</b>.'],
    [[6, 'proveedores']], 'proveedor_nuevo'),
  G('hacer-traslado', 'Hacer un traslado entre sucursales', 'traslado mover mercaderia sucursal bodega transferir enviar recibir',
    ['Menú ▸ <b>Traslados ▸ Registrar Traslado</b>.', 'Elija la sucursal de origen y la de destino.', 'Elija el estado: Pendiente, Enviado o Entregado.', 'Presione <b>Agregar</b> y busque los productos con su cantidad.', 'Presione <b>Registrar Traslado</b>: descuenta las existencias e imprime el comprobante.'],
    [[10, 'registrar un traslado']], 'traslado_con_item'),
  G('crear-promocion', 'Crear una promoción o descuento', 'promocion descuento oferta rebaja precio fijo combo regalo porcentaje',
    ['Menú ▸ <b>Mantenedor ▸ Descuentos y Promociones</b> ▸ <b>Nueva Promoción</b>.', 'Escriba el nombre y elija el tipo (% Descuento, Precio Fijo, Combo por Cantidad, Combo de Productos o Regalo).', 'Escriba el valor y elija los productos.', 'Defina la vigencia, la condición (contado o crédito) y los métodos de pago.', 'Guarde. En Registrar Venta se ven con el icono de etiqueta.'],
    [[5, 'descuentos y promociones']], 'promocion_nueva'),
  G('configurar-negocio', 'Poner los datos del negocio, el logo y el CAI', 'configuracion negocio datos nombre rtn cai logo direccion telefono rango fecha limite factura',
    ['Menú ▸ <b>Mantenedor ▸ Configuración</b> (administrador).', 'Suba el logo y escriba nombre, RTN, dirección, teléfono y correo.', 'Escriba el CAI, el rango autorizado y la fecha límite de emisión.', 'Presione <b>Guardar cambios</b>.'],
    [[3, 'datos del negocio']], 'configuracion'),
  G('cambiar-color', 'Cambiar el color del sistema o el documento por defecto', 'color tema cambiar apariencia rgb factura venta documento por defecto',
    ['Configuración ▸ tarjeta <b>Apariencia y documento por defecto</b>.', 'Toque uno de los colores o <b>Elegir otro color (RGB)</b>.', 'Abajo elija si cada venta empieza como <b>Factura</b> o <b>Venta</b>.'],
    [[3, 'apariencia']], 'config_4'),
  G('vender-sin-existencia', 'Vender un producto que no tiene existencia', 'sin existencia agotado vender cero stock no deja agregar clave especial venta anticipada',
    ['Por defecto el sistema no lo permite. Si necesita hacerlo, un administrador debe encender «Permitir vender un producto sin existencia (con clave)» en Configuración y tener una clave especial.', 'Después, al agregarlo a la venta se pide la clave especial.', 'Cuando llegue la compra del repuesto, el sistema completa esa venta anticipada y corrige el costo.'],
    [[4, 'cómo funciona la clave especial']], 'config_1'),
  G('imprimir-celular', 'Imprimir un ticket desde el celular o la tableta', 'imprimir celular tableta tablet telefono caja principal ticket remota navegador android iphone',
    ['Al crear la venta desde el navegador del celular, la orden se manda sola a la caja principal.', 'Para otros tickets (recibo de abono, cierre de caja, resumen): abra la vista previa y presione <b>Imprimir en la caja principal</b>.', 'La PC de la caja debe estar encendida, con el sistema abierto y la impresora lista.', 'Si no está conectada, el sistema lo avisa y la venta queda en <b>Pendientes de Impresión</b>.'],
    [[13, 'imprimir en la caja principal'], [13, 'la impresión remota']], 'web_vista_previa_ticket', true),
  G('pc-principal', 'Elegir la PC que imprime (PC principal)', 'pc principal impresora estrella dispositivos caja imprime remota elegir marcar',
    ['Menú ▸ <b>Mantenedor ▸ Dispositivos</b>.', 'Toque la <b>estrella</b> de la computadora que tiene la impresora conectada.', 'Tocar la estrella llena la quita.', 'Deje esa PC encendida y con el sistema abierto.'],
    [[13, 'elegir y configurar la pc principal']], 'dispositivos'),
  G('configurar-impresora', 'Configurar la impresora de tickets', 'impresora configurar termica ticket ancho 58 80 prueba directo star papel',
    ['En la PC de la caja instale la impresora en Windows.', 'Configuración ▸ <b>Impresoras</b>: elija la impresora, el ancho (58 u 80 mm) y si imprime directo.', 'Presione <b>Imprimir ticket de prueba</b>.', 'Si saca papel de más sin cortar o el texto sale raro, active <b>Impresora especial</b>.'],
    [[13, 'configurar la impresora']], 'config_3'),
  G('ticket-no-sale', 'El ticket no sale o sale mal', 'ticket no sale imprime papel blanco cortado pendiente impresora error problema falla',
    ['Revise que la impresora esté encendida, con papel y conectada.', 'Si dijo «se envió a la caja principal»: la PC principal debe tener el sistema abierto.', 'Abra <b>Registrar Venta ▸ Pendientes de Impresión</b> e imprima desde ahí.', 'Haga un ticket de prueba en Configuración ▸ Impresoras.', 'Papel en blanco sin cortar: active «Impresora especial». Cortado de los lados: revise 58 u 80 mm.'],
    [[13, 'si algo falla'], [17, 'buenas prácticas']], 'venta_pendientes_impresion', true),
  G('escanear-celular', 'Usar el celular como lector de códigos de barras', 'escanear lector codigo de barras celular camara qr',
    ['En la PC, Registrar Venta ▸ <b>Escanear con celular</b>.', 'Apunte la cámara del celular al código QR.', 'Escanee las etiquetas: cada código agrega el repuesto a la venta.', 'Al terminar, finalice el escaneo.'],
    [[14, 'introducción']], 'venta_escanear_celular'),
  G('refrescar-web', 'La web no muestra lo último (refrescar)', 'refrescar actualizar web version vieja recargar navegador limpiar cache ctrl f5',
    ['Presione el botón de <b>refrescar</b> de la barra superior (junto a cerrar sesión). Hace lo mismo que Ctrl+F5 y limpia lo guardado en el navegador.', 'Si en el celular sigue igual, cierre y vuelva a abrir el navegador.'],
    [[15, 'actualizaciones automáticas']], 'inicio_panel'),
];

const basicos = guias.filter((g) => g.basico).map((g) => g.id);

const datos = {
  capitulos: capitulos.map(([t], i) => ({ n: i + 1, titulo: t })),
  articulos: articulos.map(({ id, cap, capTitulo, titulo, claves, html, texto }) => ({ id, cap, capTitulo, titulo, claves, html, texto })),
  guias,
  basicos,
};

const salida = path.join(__dirname, '..', '..', 'web', 'manual');
fs.mkdirSync(salida, { recursive: true });
fs.writeFileSync(path.join(salida, 'datos.js'), 'window.MANUAL = ' + JSON.stringify(datos) + ';');
console.log('artículos', articulos.length, 'guías', guias.length, 'KB', Math.round(fs.statSync(path.join(salida, 'datos.js')).size / 1024));
