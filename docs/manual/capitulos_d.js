const H = require('./helpers');
const { captura, parMovil } = require('./captura_helper');
const { datos, figura, aviso, consejo, cuidado, pasos } = H;

const caja = (t, s, tipo = '') => `<div style="flex:1;border:1.5px solid ${tipo === 'pri' ? '#303846' : '#b6bcc7'};background:${tipo === 'pri' ? '#303846' : '#fff'};color:${tipo === 'pri' ? '#fff' : '#1a1a1a'};border-radius:8px;padding:3mm;text-align:center;font-size:8.5pt"><b style="display:block;font-size:9.5pt">${t}</b>${s}</div>`;
const flecha = (t = '') => `<div style="flex:0 0 18mm;text-align:center;font-size:7.5pt;color:#6b7280">${t}<div style="font-size:15pt;line-height:1;color:#303846">➜</div></div>`;

const capImpresion = `
<p>El sistema imprime tickets y facturas en impresoras térmicas de 58 o 80 mm, y también puede generar PDF. Los tickets salen en <b>ESC/POS directo</b>: el sistema le manda a la impresora las instrucciones de impresión ya armadas, con el texto partido en líneas del ancho justo del rollo, de modo que nada sale cortado. Lo más importante de entender es que <b>no todos los equipos pueden hablar con una impresora</b>: la computadora de la caja sí, pero un celular o un navegador normalmente no. Para resolverlo existe la <b>impresión remota</b>: cualquier equipo puede pedirle a la <b>PC principal</b> que imprima por él.</p>

<h3>Qué se imprime en ESC/POS</h3>
${datos(['Documento', 'Detalle'], [
  ['Factura y venta', 'La factura lleva RTN, CAI, rango autorizado y fecha límite; la venta simple no lleva CAI, rango ni fecha límite. El logo sale en blanco y negro, más pequeño y sin rayas. Con el interruptor «Imprimir copia además del original» sale también la hoja COPIA.'],
  ['Recibo de abono (clientes y proveedores)', 'Con línea de firma. Sale ORIGINAL y, si está activo «Imprimir copia del recibo de abono», también COPIA.'],
  ['Cierre de caja y Resumen del Día', 'Ticket con todos los totales del periodo.'],
  ['Listado de inventario', 'Cada repuesto con los datos que usted elija; los nombres se parten en varias líneas.'],
  ['Facturas de «Unir Facturas»', 'La factura unificada o cada factura original por separado.'],
  ['Traslado', 'Comprobante con líneas de firma de quien entrega y de quien recibe.'],
  ['Guía de envío', 'En tamaño ticket o en tamaño grande, con los datos del destinatario.'],
])}

<h3>Qué pasa al registrar una venta, según el equipo</h3>
${datos(['Equipo desde el que se vende', 'Qué hace el sistema al registrar'], [
  ['<b>PC con Windows y la impresora configurada</b>', 'Con «Imprimir directo, sin preguntar» imprime al instante. Sin él, muestra la vista previa con el botón para imprimir. Si la impresora no responde, la orden pasa sola a la PC principal.'],
  ['<b>PC con Windows sin impresora configurada</b>', 'Envía la orden de impresión a la PC principal.'],
  ['<b>Celular o tableta Android</b>', 'Pregunta qué hacer con el ticket: <b>Bluetooth/red</b> (imprime en la impresora configurada), <b>Impresora del sistema</b> (abre el diálogo de impresión de Android) o <b>Dejar pendiente</b>.'],
  ['<b>Navegador en celular o tableta</b>', 'Envía la orden a la PC principal. Si la PC principal está apagada, la venta queda como pendiente de impresión.'],
  ['<b>Navegador en una PC</b>', 'Abre el diálogo de impresión del navegador con el ticket en PDF, para elegir cualquier impresora instalada en esa PC. También se puede pedir la impresión en la caja principal.'],
  ['<b>iPhone o iPad</b>', 'Imprime en la impresora de red configurada.'],
])}
<p>Si el interruptor <b>Imprimir facturas automáticamente</b> está apagado en Configuración, no se imprime nada al vender; la venta se guarda igual.</p>

<h3>Imprimir en la caja principal desde el navegador</h3>
<p>Los tickets que no son una venta (recibos de abono, cierre de caja, Resumen del Día, inventario, facturas unidas) también se pueden imprimir desde un celular o tableta. Al abrir la vista previa en el navegador aparecen estos botones:</p>
${figura(
  captura('web_vista_previa_ticket.png', [{ n: 1, x: 714, y: 407 }, { n: 2, x: 714, y: 537 }, { n: 3, x: 714, y: 579 }, { n: 4, x: 714, y: 620 }]),
  'Vista previa de un ticket en el navegador.',
  ['<b>Imprimir en [nombre de la impresora]</b>: intenta imprimir en la impresora configurada desde este equipo.', '<b>Imprimir en la caja principal</b>: manda el ticket ya armado a la PC principal, que lo imprime sola. Si la PC principal no está conectada, el sistema lo avisa y no manda nada.', '<b>Descargar PDF</b>.', '<b>Ver / imprimir</b>: abre el PDF en el diálogo de impresión del navegador.']
)}

<h3>La impresión remota: cómo funciona</h3>
${figura(
  `<div style="display:flex;align-items:center;gap:1mm;margin:2mm 0">${caja('Celular o navegador', 'Registra la venta y pide imprimir')}${flecha('orden')}${caja('Servidor', 'Guarda la orden de impresión')}${flecha('aviso')}${caja('PC principal', 'Reclama la orden y la procesa sola', 'pri')}${flecha('ticket')}${caja('Impresora', 'Sale el ticket en la caja')}</div>`,
  'Recorrido de una orden de impresión remota.',
  ['El celular termina la venta y, en vez de imprimir, deja la orden de impresión en el servidor.', 'La PC principal está siempre escuchando y además revisa cada 6 segundos si hay órdenes pendientes. Al ver una, la <b>reclama</b>: en una sola operación del servidor la marca como tomada. Si hubiera dos computadoras escuchando, solo una logra tomarla.', 'El ticket sale en la caja sin mostrar ninguna ventana. Una orden se imprime una sola vez.']
)}
${pasos([
  ['La PC principal avisa que está viva.', 'Cada 25 segundos manda una señal de presencia al servidor, y comprueba si esta PC sigue siendo la marcada como principal. Si la última señal tiene menos de 40 segundos, el sistema considera que la PC principal está conectada.'],
  ['El otro equipo comprueba esa señal.', 'Al terminar una venta (o al pedir imprimir un ticket), antes de pedir la impresión revisa si la PC principal está conectada.'],
  ['Si está conectada, envía la orden.', 'Aparece el mensaje «Se envió la orden de impresión a la caja principal». El ticket sale en pocos segundos.'],
  ['Si no está conectada, la venta queda pendiente.', 'Aparece «La venta quedó pendiente de impresión». Nada se pierde: se puede imprimir después desde <b>Pendientes de Impresión</b>.'],
])}
${aviso('La impresión remota solo funciona si la PC principal tiene el sistema abierto y con la sesión iniciada. Si la apaga o cierra el programa, las órdenes se acumulan como pendientes.', 'Condición')}

<h3>Elegir y configurar la PC principal</h3>
<p>Si no hay ninguna PC marcada, <b>cualquier computadora de escritorio</b> que tenga el sistema abierto actúa como PC principal. Si tiene más de una PC y solo una tiene la impresora, márquela con la estrella para que las demás no intenten imprimir órdenes ajenas.</p>
${figura(
  captura('dispositivos.png', [{ n: 1, x: 255, y: 150 }, { n: 2, x: 700, y: 205 }, { n: 3, x: 1372, y: 785 }, { n: 4, x: 1372, y: 330 }, { n: 5, x: 600, y: 785 }]),
  'Mantenedor ▸ Dispositivos.',
  ['Última versión publicada del sistema.', 'Explicación en pantalla: cada equipo actualiza su fila solo al iniciar sesión. Con la estrella se marca la PC que tiene la impresora conectada.', 'La estrella llena marca la <b>PC principal</b> actual (aquí, la fila de una computadora con Windows).', 'Estrella vacía: toque para marcar ese equipo como principal. Tocar la estrella llena la quita.', 'Plataforma y versión de cada equipo. Un equipo con versión vieja se nota enseguida.']
)}

<h3>Configurar la impresora de la PC principal</h3>
${pasos([
  ['Instale la impresora en Windows.', 'Con su controlador y papel del ancho correcto. Imprima una página de prueba de Windows para confirmar.'],
  ['Abra Mantenedor ▸ Configuración ▸ Impresoras.', 'En «Impresora térmica (recibos)» elija la impresora instalada.'],
  ['Elija el ancho del rollo.', '58 mm (32 columnas) u 80 mm (48 columnas).'],
  ['Active «Imprimir directo, sin preguntar»', 'si quiere que el ticket salga al confirmar la venta sin vista previa.'],
  ['Presione «Imprimir ticket de prueba».', 'Sale un ticket marcado como prueba. No se registra ninguna venta ni se gasta numeración.'],
  ['Marque la PC como principal.', 'En Dispositivos, con la estrella en la fila de esa computadora.'],
])}
<p>Si su impresora saca papel de más sin cortar, o el texto sale raro o incompleto (pasa con algunas Star), active <b>Impresora especial</b>: el ticket se manda por el programa oficial de la impresora instalado en Windows.</p>
${consejo('Deje la PC de la caja siempre encendida y con el sistema abierto durante el horario de atención. Si el programa se cierra, el celular lo notará en menos de un minuto y dejará las ventas como pendientes.')}

<h3>Pendientes de Impresión</h3>
<p>Dentro de <b>Registrar Venta</b> está el botón <b>Pendientes de Impresión</b>, con un contador cuando hay ventas sin imprimir. Muestra cada venta con su cliente, documento, total y hora. El botón de impresora de cada fila imprime esa venta desde el equipo en el que usted está; por eso conviene abrir esta lista en la PC que tiene la impresora. Cuando se imprime, sale de la lista (ver la imagen del capítulo 7).</p>

<h3>Impresión en Android</h3>
<p>En un celular o tableta Android, al registrar una venta aparece una pregunta con tres opciones: <b>Dejar pendiente</b>, <b>Impresora del sistema</b> (abre el diálogo de impresión de Android, para PDF o impresoras instaladas en el celular) y <b>Bluetooth/red</b> (imprime directo en la impresora térmica configurada). Para una impresora Bluetooth: empareje la impresora desde los ajustes Bluetooth del celular y luego elíjala en Configuración. Para una impresora de red escriba su IP y el puerto (normalmente 9100) en «Impresora térmica de red».</p>

<h3>Guía de envío</h3>
<p>Cuando una venta se envía a domicilio (<b>Más datos ▸ Es envío</b>), el sistema puede imprimir además una <b>guía de envío</b> con el nombre, dirección y teléfono del destinatario, en tamaño ticket o en tamaño grande. La guía sigue las mismas reglas: se imprime en el equipo si puede, y si no, se pide a la PC principal. También se puede generar desde Ver Detalle.</p>

<h3>Traslados y reimpresiones</h3>
<ul>
  <li>El comprobante de un <b>traslado</b> también se imprime en la PC principal cuando se registra desde un celular.</li>
  <li>Desde <b>Ver Detalle</b> de una venta o traslado, el botón Reimprimir permite sacar una <b>copia</b> o el original. Una reimpresión remota también la procesa la PC principal.</li>
  <li>Si el negocio tiene apagada «Imprimir copia además del original», cada venta sale con una sola hoja.</li>
</ul>

<h3>Tipos de impresora y cuál elegir</h3>
${datos(['Tipo', 'Cuándo usarla', 'Observación'], [
  ['Térmica USB en Windows (impresión directa)', 'La caja principal', 'La más rápida: manda el ticket sin pasar por el controlador.'],
  ['Térmica USB en Windows con controlador (Impresora especial)', 'Impresoras que no aceptan impresión directa', 'Es el caso de algunas Star y de impresoras con protocolo propio.'],
  ['Térmica de red (IP)', 'Impresora con cable de red compartida entre equipos', 'Funciona también desde iPhone, iPad y Android.'],
  ['Térmica Bluetooth', 'Vender desde el celular en el mostrador o en ruta', 'Solo Android. Emparejar primero.'],
  ['Impresora común o PDF', 'Respaldo, o cotizaciones en hoja carta', 'Se usa el diálogo de impresión de Windows, Android o del navegador.'],
])}

<h3>Si algo falla</h3>
${datos(['Síntoma', 'Qué revisar'], [
  ['«La venta quedó pendiente de impresión»', 'La PC principal está apagada, sin el sistema abierto o sin internet. Ábralo y use Pendientes de Impresión.'],
  ['Envía la orden pero no sale el ticket', 'Revise que la PC principal tenga la impresora encendida, con papel y elegida en Configuración. Haga el ticket de prueba. Si la orden no sale ni llega a Pendientes, avise: puede haber un problema de conexión de esa PC.'],
  ['Sale papel en blanco sin cortar', 'La impresora no entiende la impresión directa. Active «Impresora especial».'],
  ['Sale el ticket cortado o desalineado', 'Ancho de rollo equivocado: cambie entre 58 y 80 mm.'],
  ['Se imprimen dos hojas', 'Es el original y la copia. Apague «Imprimir copia además del original» si no la necesita.'],
  ['Desde el navegador de la PC sale un PDF y no el ticket', 'Es lo esperado: el navegador no puede enviar el ticket directo a una impresora térmica. Elija la impresora en el diálogo, use «Imprimir en la caja principal», o venda desde el programa de Windows.'],
  ['Varias PC intentan imprimir lo mismo', 'Marque una sola PC principal en Dispositivos.'],
])}
`;

const capEscaner = `
<p>El celular puede usarse como <b>lector de códigos de barras</b> de la computadora, sin cables ni programas extra. Sirve para agregar repuestos a una venta apuntando la cámara a la etiqueta.</p>
${figura(
  captura('venta_escanear_celular.png', [{ n: 1, x: 712, y: 373 }, { n: 2, x: 712, y: 539 }, { n: 3, x: 712, y: 678 }]),
  'Ventana «Escanear con el celular» en Registrar Venta.',
  ['Explicación: apunte la cámara del celular a este código QR (no hace falta ninguna app: se abre directo en el navegador). La ventana se cierra sola apenas el celular se conecte.', 'Código QR que apunta a la página del sistema con un código temporal.', 'Código de 6 letras de esta sesión de escaneo.']
)}
${pasos([
  ['En la PC, en Registrar Venta, presione «Escanear con celular».', 'Aparece el código QR.'],
  ['Con el celular, escanee el QR.', 'Se abre directamente la pantalla de la cámara. No necesita usuario ni clave: solo sirve para mandar códigos.'],
  ['Apunte a la etiqueta del repuesto.', 'El código llega a la PC y el repuesto se agrega a la venta al instante.'],
  ['Siga escaneando.', 'Cada código recibido se agrega a la venta. El botón de la PC cambia a «Escaneo activo» mientras el celular está conectado.'],
  ['Al terminar, finalice el escaneo.', 'La conexión se corta y el celular queda libre.'],
])}
${consejo('Si usa la aplicación en un celular o tableta Android, ya tiene el botón «Escanear» con la cámara dentro del buscador de productos; el QR es para escanear desde el celular y vender en la PC.')}
<p>Si el código escaneado no coincide con ningún repuesto, el sistema prueba variantes válidas del mismo código (por ejemplo, el cero que algunos iPhone agregan al principio, o el código leído al revés) antes de decir que no existe. Si de verdad no existe, puede crearlo en ese momento con los datos del código ya cargados.</p>
`;

const capInstalacion = `
<h3>Instalar en Windows</h3>
${pasos([
  ['Descargue el instalador.', 'Es el archivo <code>RepuestosPOS.exe</code> de la página de versiones del sistema.'],
  ['Ábralo.', 'No necesita permisos de administrador: se instala solo para su usuario de Windows. Es normal que Windows muestre «Windows protegió su PC»: aparece con cualquier programa nuevo que no tenga un certificado comercial de pago. Elija <b>Más información ▸ Ejecutar de todas formas</b>. Solo se hace en la primera instalación; las actualizaciones que la propia aplicación descarga no lo piden.'],
  ['Acepte las opciones.', 'Puede crear un acceso directo en el Escritorio. El programa se llama <b>Autoparts</b>.'],
  ['Ingrese.', 'Con su código de acceso y contraseña.'],
])}
<h3>Instalar en Android</h3>
${pasos([
  ['Descargue <code>RepuestosPOS.apk</code> en el celular.', 'Desde la página de versiones del sistema.'],
  ['Permita la instalación desde esa fuente.', 'Android lo pedirá la primera vez: active «Permitir de esta fuente».'],
  ['Abra el archivo e instale.', 'La aplicación se instala con el nombre <b>Autoparts</b>. Para actualizar más adelante, el mismo proceso instala encima sin perder nada.'],
])}
<h3>Usar desde el navegador</h3>
<p>Abra la dirección web del sistema en Chrome, Edge o Safari. Se puede agregar a la pantalla de inicio del celular como aplicación (en iPhone: Compartir ▸ Agregar a pantalla de inicio; el icono se llama «Autoparts»). Es la forma más rápida de consultar desde un equipo ajeno, sin instalar nada. Si la web se ve distinta a la última versión, use el botón de refrescar de la barra superior.</p>

<h3>Primer ingreso del administrador</h3>
<p>Quien instaló el sistema le entrega un usuario administrador inicial. Al entrar por primera vez:</p>
<ol>
  <li>Cambie la contraseña del administrador en <b>Usuarios</b>.</li>
  <li>Complete los datos del negocio en <b>Configuración</b> (capítulo 3).</li>
  <li>Cree las sucursales si las usa y los usuarios de su personal.</li>
  <li>Cargue las categorías y los repuestos (a mano o con <b>Importar</b>).</li>
  <li>Haga una venta de prueba y un ticket de prueba para confirmar la impresión.</li>
</ol>

<h3>Seguridad de la información</h3>
<ul>
  <li>Cada persona entra con su usuario y contraseña; tras varios intentos fallidos la cuenta se bloquea 5 minutos.</li>
  <li>Las contraseñas se guardan protegidas en el servidor y no se pueden ver ni desde el propio sistema.</li>
  <li>La sesión dura 24 horas y se renueva sola mientras el programa está abierto; al cerrar sesión se descarta.</li>
  <li>La clave especial solo la cambia un administrador.</li>
</ul>

<h3>Respaldo de la información</h3>
<p>Todos los datos viven en la nube, no en cada computadora, así que si una PC se daña no se pierde nada: se instala el programa en otra y se entra con el mismo usuario.</p>
${cuidado('El plan gratuito del servicio no incluye copias de seguridad automáticas. Como respaldo propio, exporte con regularidad a Excel el inventario (Inventario ▸ Excel) y los reportes de ventas y compras, y guárdelos en otro lugar. Si el negocio crece, conviene pasar al plan de pago, que sí respalda a diario.', 'Recomendación')}
<p>Además, si el servicio gratuito se pausa por falta de uso, el sistema lo reanuda solo cada pocos días; si aun así un día no conecta, avise a quien administra el sistema.</p>
`;

module.exports = { capImpresion, capEscaner, capInstalacion };
