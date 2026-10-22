const H = require('./helpers');
const { captura, parMovil } = require('./captura_helper');
const { datos, figura, aviso, consejo, cuidado, pasos } = H;

const cap1 = `
<p><b>Autoparts</b> es el sistema con el que el negocio registra ventas, compras, inventario, créditos, traslados entre sucursales y cierres de caja. Funciona en computadoras con Windows, en celulares y tabletas Android y desde el navegador web. Todos los equipos trabajan sobre la misma información: lo que se registra en uno aparece en los demás en pocos segundos.</p>

<h3>Qué puede hacer con el sistema</h3>
<ul>
  <li>Vender con <b>factura</b> o con <b>venta simple</b>, hacer cotizaciones (con o sin ISV), ventas a crédito y pagos mixtos (parte en efectivo y parte con tarjeta o transferencia).</li>
  <li>Controlar el inventario con existencias, costos por lote, historial de movimientos y fotos de cada repuesto.</li>
  <li>Indicar para qué <b>vehículos y años</b> sirve cada repuesto y encontrarlo rápido buscando por marca, modelo y año.</li>
  <li>Mover mercadería entre <b>sucursales</b> con traslados que descuentan existencias y se pueden anular.</li>
  <li>Dar seguimiento a las cuentas por cobrar (clientes) y por pagar (proveedores).</li>
  <li>Abrir y cerrar la caja de cada cajero, con conteo de billetes, y registrar los egresos del negocio.</li>
  <li>Consultar reportes de ventas, compras, traslados y finanzas, y un <b>Resumen del Día</b> con todo lo que pasó en un periodo.</li>
  <li>Imprimir tickets en impresora térmica, también desde un celular o tableta pidiéndole a la caja principal que imprima.</li>
</ul>

<h3>Equipos y requisitos</h3>
${datos(['Equipo', 'Cómo se usa', 'Notas'], [
  ['Computadora con Windows 10 u 11', 'Programa instalado desde el archivo <code>RepuestosPOS.exe</code>', 'Es el recomendado para la caja principal: es el que conecta la impresora de tickets.'],
  ['Celular o tableta Android', 'Aplicación instalada desde <code>RepuestosPOS.apk</code>', 'Sirve para vender, consultar inventario y escanear códigos de barras con la cámara.'],
  ['Navegador web', 'Dirección web del sistema (la entrega quien instaló el sistema)', 'Chrome, Edge o Safari actualizados. No necesita instalar nada.'],
])}
<p>Todos los equipos necesitan internet. Si la conexión se interrumpe un momento, el sistema vuelve a intentar solo y avisa cuando una operación quedó pendiente (ver capítulo 15).</p>

<h3>Cómo está organizado este manual</h3>
<p>Los capítulos siguen el orden en que normalmente se empieza a trabajar: ingresar, configurar el negocio, crear usuarios, cargar inventario, vender y comprar, y por último los reportes. Al final hay una tabla de problemas frecuentes y un glosario con las palabras que usa el sistema.</p>
<p>Todas las imágenes de este manual son capturas reales del sistema. Los números rojos señalan la parte de la pantalla que se explica debajo de cada imagen.</p>
${consejo('Si es la primera vez que usa el sistema, lea los capítulos 2, 3 y 4 antes de registrar la primera venta. Con eso quedan listos el negocio, los usuarios y los permisos.')}
`;

const cap2 = `
<h3>Ingresar al sistema</h3>
<p>Al abrir el programa aparece primero una pantalla negra con el logo y la barra «Cargando el sistema…», y enseguida la pantalla de ingreso. Cada persona entra con su <b>código de acceso</b> (el que le asignó el administrador) y su <b>contraseña</b>.</p>
${figura(
  captura('00_login.png', [{ n: 1, x: 1115, y: 423 }, { n: 2, x: 1115, y: 489 }, { n: 3, x: 1296, y: 489 }, { n: 4, x: 1115, y: 567 }]),
  'Pantalla de ingreso en computadora.',
  ['Escriba su <b>código de acceso</b>.', 'Escriba su <b>contraseña</b>. Si se equivoca varias veces seguidas, la cuenta se bloquea 5 minutos por seguridad.', 'El ojo muestra u oculta la contraseña mientras la escribe.', 'Presione <b>Ingresar</b> (o Enter).']
)}
<p>En celulares y tabletas la misma pantalla se acomoda en una sola columna. En equipos compatibles, el celular puede recordar la huella o Face ID para entrar sin escribir la contraseña.</p>
${parMovil([['m_login.png', [{ n: 1, x: 390, y: 968 }, { n: 2, x: 390, y: 1112 }, { n: 3, x: 390, y: 1250 }], 52], ['m_inicio.png', [{ n: 1, x: 64, y: 64 }, { n: 2, x: 668, y: 64 }, { n: 3, x: 390, y: 470 }], 52]])}
<div class="pie-par">Ingreso (izquierda) e inicio (derecha) en un celular. 1: código de acceso. 2: contraseña. 3: botón Ingresar. En el inicio: 1: botón del menú. 2: refrescar y cerrar sesión. 3: venta del día.</div>
${aviso('Cada persona debe usar su propio usuario. Así los reportes muestran quién hizo cada venta, compra o ajuste de inventario.')}

<h3>La pantalla principal</h3>
<p>Después de ingresar se muestra el <b>Inicio</b>: arriba el saludo y la <b>venta de hoy</b> y <b>del mes</b>; en el centro un acceso directo por cada módulo al que su usuario tiene permiso; y abajo, solo para el administrador, el <b>Panel del dueño</b> con las ventas de la semana y el ticket promedio.</p>
${figura(
  captura('inicio_panel.png', [{ n: 1, x: 32, y: 32 }, { n: 2, x: 50, y: 89 }, { n: 3, x: 1360, y: 32 }, { n: 4, x: 1408, y: 32 }, { n: 5, x: 720, y: 240 }, { n: 6, x: 240, y: 700 }], { recorte: 0 }),
  'Inicio, desplazado hacia abajo para ver los módulos y el Panel del dueño.',
  ['<b>Menú.</b> Abre la lista de módulos. Los que no aparecen son los que su usuario no tiene permitidos.', '<b>Pestañas.</b> Cada pantalla se abre en una pestaña propia; puede tener varias a la vez.', '<b>Refrescar.</b> Solo en la versión web: vuelve a cargar el sistema y limpia lo guardado en el navegador, como Ctrl+F5.', '<b>Cerrar sesión.</b>', '<b>Módulos.</b> Un recuadro por módulo, con la cantidad de opciones que tiene.', '<b>Panel del dueño</b> (solo administrador): ventas de la semana, ticket promedio y la gráfica de los últimos 7 días.']
)}
<h3>El menú</h3>
${figura(
  captura('02_menu.png', [{ n: 1, x: 150, y: 38 }, { n: 2, x: 150, y: 207 }, { n: 3, x: 150, y: 254 }, { n: 4, x: 262, y: 38 }]),
  'Menú abierto, con el módulo Ventas desplegado.',
  ['Título del menú.', 'Módulo. Los que tienen varias pantallas se despliegan al tocarlos.', 'Pantalla dentro del módulo: al tocarla se abre en una pestaña nueva.', 'Cierra el menú.']
)}

<h3>Trabajar con varias pestañas</h3>
<p>Cada pestaña es independiente: puede dejar una venta a medias en una pestaña, abrir el inventario en otra para consultar una existencia y volver a la venta sin perder nada. Lo que escribe o busca en una pestaña no se refleja en las demás, aunque sean del mismo módulo.</p>
<ul>
  <li>Para abrir una pantalla, toque su nombre en el menú.</li>
  <li>Para cerrar una pestaña, use la <b>x</b> de su etiqueta.</li>
  <li>Una ventana que se abre dentro de una pestaña (por ejemplo, Buscar Producto) solo afecta a esa pestaña; las demás se pueden seguir usando.</li>
  <li>En el celular el menú se abre con el botón de las tres rayas.</li>
</ul>

<h3>Cerrar sesión</h3>
<p>Use el botón de salir, arriba a la derecha. Hágalo siempre que otra persona vaya a usar el equipo.</p>
`;

const cap3 = `
<p>Antes de vender, el administrador debe completar los datos del negocio. Todo se hace en <b>Mantenedor ▸ Configuración</b>. La pantalla es larga: se recorre hacia abajo y cada bloque es una tarjeta. Los cambios se aplican a todos los equipos.</p>

<h3>Datos del negocio y logo</h3>
${figura(
  captura('configuracion.png', [{ n: 1, x: 113, y: 382 }, { n: 2, x: 1361, y: 498 }, { n: 3, x: 380, y: 582 }, { n: 4, x: 1060, y: 644 }, { n: 5, x: 1060, y: 728 }]),
  'Primera tarjeta de Configuración: datos del negocio.',
  ['<b>Logo.</b> Suba solo el logo normal: el sistema lo convierte solo a blanco y negro cuando hace falta para el ticket. «Cambiar logo» lo reemplaza y «Quitar logo» lo borra.', 'Interruptores para incluir el logo en el <b>ticket impreso</b> y en la <b>factura en PDF</b>.', 'Nombre, RTN, dirección y teléfono. Salen impresos en los tickets y facturas.', 'Correo y <b>CAI</b> (código de autorización de impresión).', '<b>Rango autorizado</b> de facturas (prefijo, desde y hasta) y, más abajo, la <b>fecha límite de emisión</b>.']
)}
<p>Después de llenar los datos presione <b>Guardar cambios</b>, al final de la tarjeta. Si el negocio emite facturas con CAI, complete el rango y la fecha límite: el sistema numera las facturas en orden y respeta ese rango. Las ventas simples (sin facturar) <b>no</b> imprimen CAI, rango ni fecha límite; eso sale solo en las facturas.</p>

<h3>Acceso de permisos especiales (clave especial)</h3>
${figura(
  captura('config_1.png', [{ n: 1, x: 180, y: 452 }, { n: 2, x: 380, y: 452 }, { n: 3, x: 128, y: 495 }, { n: 4, x: 1361, y: 604 }], { recorte: 134 }),
  'Tarjeta de permisos especiales.',
  ['Escriba aquí la <b>clave especial</b>.', '<b>Guardar clave</b> la crea o la cambia; <b>Quitar clave</b> la elimina.', 'Indica si ya hay una clave activa.', 'Cada interruptor marca una acción para la que se pedirá la clave. Apagado significa que no se pide.']
)}
<p>La clave especial es una segunda clave, conocida solo por el administrador, que el sistema pide antes de acciones delicadas. Los interruptores cubren estas acciones: editar productos y cambiar existencias en Inventario, eliminar créditos, cambiar el precio o la descripción de un producto dentro de una venta, vender un producto sin existencia, registrar, editar y anular compras, crear y eliminar productos, crear, editar y eliminar clientes, anular ventas, anular traslados y editar el fondo inicial de una caja abierta. El detalle de a quién se le pide y a quién no está en el capítulo 4.</p>

<h3>Impresoras</h3>
${figura(
  captura('config_3.png', [{ n: 1, x: 400, y: 437 }, { n: 2, x: 380, y: 570 }, { n: 3, x: 1060, y: 570 }, { n: 4, x: 1361, y: 700 }, { n: 5, x: 1361, y: 806 }], { recorte: 134 }),
  'Tarjeta de impresoras (vista en el navegador).',
  ['<b>Ancho del ticket:</b> 58 mm (32 columnas) u 80 mm (48 columnas). Afecta la impresión real y la vista previa.', '<b>Impresora térmica (recibos).</b> En el programa de Windows se elige aquí la impresora instalada. En el navegador la lista no está disponible, y la pantalla lo explica.', '<b>Impresora de etiquetas</b> (opcional): si no se elige, las etiquetas salen por la impresora de recibos.', '<b>Imprimir directo, sin preguntar:</b> al confirmar una venta se imprime sin mostrar vista previa.', '<b>Impresora especial</b> (Star u otra que no imprime bien directo): se manda el ticket por el controlador de Windows. Actívelo solo si la impresora saca papel de más sin cortar o el texto sale raro.']
)}
${figura(
  captura('config_4.png', [{ n: 1, x: 300, y: 270 }, { n: 2, x: 720, y: 421 }], { recorte: 134 }),
  'Parte final de la tarjeta de impresoras.',
  ['<b>Impresora térmica de red</b>: para vender desde el celular con una impresora conectada por WiFi, se escribe aquí su dirección IP. No está disponible en la versión web.', '<b>Imprimir ticket de prueba</b>: genera un ticket sin registrar ninguna venta. Úselo para comprobar la impresora.']
)}

<h3>Apariencia y documento por defecto</h3>
${figura(
  captura('config_4.png', [{ n: 1, x: 160, y: 582 }, { n: 2, x: 147, y: 634 }, { n: 3, x: 302, y: 634 }, { n: 4, x: 150, y: 747 }], { recorte: 460 }),
  'Colores del sistema y documento que aparece primero al vender.',
  ['Nueve colores listos para elegir. El marcado con la palomita es el actual.', '<b>Elegir otro color (RGB)</b> abre una ventana con muestras, tres barras (rojo, verde y azul) y un campo para escribir un código como <code>#1F5F46</code>.', '<b>Restablecer</b> vuelve al color original.', '<b>Factura</b> o <b>Venta</b>: el documento con el que empieza cada venta nueva. Siempre se puede cambiar dentro de la venta.']
)}
<p>El color se aplica a todo el sistema y en todos los equipos; al cambiarlo, las ventanas abiertas se refrescan. Elija un color medio u oscuro: con colores muy claros el texto blanco de los botones se lee mal.</p>
${datos(['Documento', 'Qué hace'], [
  ['<b>Factura</b>', 'Muestra el ISV (15%) desglosado y usa la numeración con CAI. El precio del inventario ya es el precio final: en la factura el sistema separa el ISV de ese precio, no se lo suma encima.'],
  ['<b>Venta</b>', 'Venta simple, sin factura y sin ISV. Se imprime como ticket de venta y tiene su propia numeración.'],
  ['<b>Cotización sin ISV</b>', 'Da un precio al cliente sin desglosar impuesto. No descuenta existencias ni suma a las ventas.'],
  ['<b>Cotización con ISV</b>', 'Igual que la anterior, pero el precio se muestra desglosado con ISV, como una factura.'],
])}

<h3>Factura: qué se imprime y numeración</h3>
${figura(
  captura('config_5.png', [{ n: 1, x: 1361, y: 429 }, { n: 2, x: 1361, y: 513 }, { n: 3, x: 1361, y: 581 }, { n: 4, x: 1361, y: 649 }, { n: 5, x: 170, y: 772 }, { n: 6, x: 1347, y: 772 }], { recorte: 330 }),
  'Tarjeta Factura.',
  ['<b>Imprimir facturas automáticamente</b>: interruptor general. Apagado, al confirmar una venta no se intenta imprimir nada, sin importar lo demás.', '<b>Imprimir copia además del original</b>: apagado, cada venta sale solo con la hoja ORIGINAL y se ahorra papel.', '<b>Imprimir copia del recibo de abono</b>: encendido, cada recibo de abono (de clientes y de proveedores) sale primero como ORIGINAL y después como COPIA, ambos con línea de firma. Apagado, sale solo el original.', '<b>Mostrar precios con ISV incluido</b>: el precio de cada línea del ticket se muestra con el impuesto incluido. El total y el desglose de ISV no cambian.', '<b>Numeración de facturas</b>: el número que le toca a la próxima factura. Sirve para continuar un talonario físico o para volver a empezar desde 1 después de vaciar los datos de prueba.', '<b>Guardar</b> aplica el número.']
)}

<h3>Otras pantallas del Mantenedor</h3>
<ul>
  <li><b>Dispositivos</b> lista los equipos que usan el sistema, su versión y su última conexión, y permite marcar la PC principal (capítulo 13).</li>
  <li><b>Face ID / huella</b> permite que cada persona entre sin escribir su contraseña en su propio dispositivo.</li>
</ul>
`;

const cap4 = `
<p>Los usuarios se crean y se editan en <b>Usuarios</b>. Esta pantalla solo la ve el administrador.</p>
${figura(
  captura('usuarios_lista.png', [{ n: 1, x: 570, y: 206 }, { n: 2, x: 1190, y: 206 }, { n: 3, x: 1336, y: 206 }, { n: 4, x: 1278, y: 322 }]),
  'Lista de usuarios.',
  ['Buscador por nombre o por código de acceso.', '<b>Refrescar</b> vuelve a cargar la lista.', '<b>Nuevo Usuario</b> abre el formulario.', 'Cada fila muestra nombre, código, rol y estado. Al tocarla se abre para editar.']
)}

<h3>Crear un usuario</h3>
${figura(
  captura('usuario_encargado.png', [{ n: 1, x: 385, y: 256 }, { n: 2, x: 1054, y: 256 }, { n: 3, x: 385, y: 318 }, { n: 4, x: 1054, y: 318 }, { n: 5, x: 220, y: 384 }]),
  'Formulario de Nuevo Usuario con el rol Encargado.',
  ['<b>Código de acceso</b>: con él entra la persona al sistema.', '<b>Nombre completo</b>: es el que aparece en ventas, recibos y reportes.', '<b>Contraseña.</b> Al editar un usuario existente el campo dice «Nueva contraseña (opcional)»: se llena solo si se quiere cambiarla.', '<b>Rol</b>: Administrador, Semi Administrador, Empleado o Encargado.', 'Con el rol Encargado (y para ajustar un Empleado) aparece la lista de <b>pantallas permitidas</b>, una casilla por pantalla del menú.']
)}
${figura(
  captura('usuario_encargado2.png', [{ n: 1, x: 140, y: 440 }, { n: 2, x: 86, y: 490 }, { n: 3, x: 86, y: 700 }]),
  'La lista de acciones permitidas, más abajo en el mismo formulario.',
  ['<b>Acciones permitidas</b>: los botones de crear, editar, eliminar o anular que la persona podrá usar.', 'Acciones que normalmente piden la clave especial (editar productos, cambiar existencias, eliminar créditos…). Si se marcan, esa persona las hace sin escribir la clave.', 'Permisos de compras, productos, clientes, ventas y traslados.']
)}
<p>Para <b>desactivar</b> a alguien que ya no trabaja en el negocio no se elimina su usuario (para conservar el historial): se abre y se apaga el interruptor <b>Estado</b>. Ya no podrá ingresar. El botón del bote de basura, abajo a la izquierda del formulario, elimina el usuario.</p>

<h3>Roles</h3>
${datos(['Rol', 'Qué puede hacer'], [
  ['<b>Administrador</b>', 'Todo: configuración, usuarios, inventario, reportes financieros, anulaciones. Nunca se le pide la clave especial.'],
  ['<b>Semi Administrador</b>', 'Casi todo lo operativo. No entra a las pantallas reservadas al administrador (por ejemplo Usuarios o Configuración).'],
  ['<b>Empleado</b>', 'Por defecto: Registrar Venta, Ver Detalle de ventas, Clientes, Proveedores y Créditos. Se puede ajustar pantalla por pantalla.'],
  ['<b>Encargado</b>', 'Rol a la medida: el administrador marca exactamente qué pantallas ve y qué acciones puede hacer.'],
])}

<h3>Cómo funciona la clave especial</h3>
<p>La clave especial se crea en <b>Configuración ▸ Acceso de permisos especiales</b>, donde también se enciende o apaga, una por una, cada acción que la pide. Cuando alguien intenta una acción protegida:</p>
${datos(['Quién', 'Qué pasa'], [
  ['Administrador', 'Nunca se le pide.'],
  ['Encargado', 'Si el administrador le marcó esa acción en «Acciones permitidas», la hace sin clave. Si no, se le pide la clave.'],
  ['Empleado y Semi Administrador', 'Si la acción está encendida en Configuración y existe una clave especial, se les pide. Si está apagada, la hacen directo.'],
])}
${cuidado('La clave especial no debe compartirse con los empleados. Si alguien la conoce y no debería, cámbiela en Configuración.')}
<p>Por defecto el sistema <b>no</b> deja vender un repuesto sin existencia: muestra un aviso y no lo agrega. Solo si el administrador activa «Permitir vender un producto sin existencia (con clave)» y existe una clave especial, se podrá agregar pidiendo la clave.</p>
${consejo('Cree un usuario Encargado para quien atiende el mostrador: marque «Registrar Venta», «Clientes» y «Ver Detalle» y deje sin marcar las anulaciones. Así vende sin riesgo de anular documentos.')}
`;

module.exports = { cap1, cap2, cap3, cap4 };
