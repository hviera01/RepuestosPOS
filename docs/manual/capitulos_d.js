const H = require('./helpers');
const { pantalla, pantallaSola, campo, btn, chip, kpi, tabla, figura, aviso, consejo, cuidado, pasos, datos } = H;

const caja = (t, s, tipo = '') => `<div style="flex:1;border:1.5px solid ${tipo === 'pri' ? '#303846' : '#b6bcc7'};background:${tipo === 'pri' ? '#303846' : '#fff'};color:${tipo === 'pri' ? '#fff' : '#1a1a1a'};border-radius:8px;padding:3mm;text-align:center;font-size:8.5pt"><b style="display:block;font-size:9.5pt">${t}</b>${s}</div>`;
const flecha = (t = '') => `<div style="flex:0 0 18mm;text-align:center;font-size:7.5pt;color:#6b7280">${t}<div style="font-size:15pt;line-height:1;color:#303846">➜</div></div>`;

const capImpresion = `
<p>El sistema imprime tickets y facturas en impresoras térmicas de 58 o 80 mm, y también puede generar PDF. Lo más importante de entender es que <b>no todos los equipos pueden hablar con una impresora</b>: la computadora de la caja sí, pero un celular o un navegador normalmente no. Para resolverlo existe la <b>impresión remota</b>: cualquier equipo puede pedirle a la <b>PC principal</b> que imprima por él.</p>

<h3>Qué pasa al registrar una venta, según el equipo</h3>
${datos(['Equipo desde el que se vende', 'Qué hace el sistema al registrar'], [
  ['<b>PC con Windows y la impresora configurada</b>', 'Con el modo «Directo» imprime sin preguntar. Con el modo «Preguntar» muestra la vista previa con los botones Imprimir, Descargar y Cerrar. Si la impresora no responde, la orden pasa sola a la PC principal.'],
  ['<b>PC con Windows sin impresora configurada</b>', 'Envía la orden de impresión a la PC principal.'],
  ['<b>Celular o tableta Android</b>', 'Muestra la pregunta «¿Qué quiere hacer con el ticket?» con tres opciones: <b>Bluetooth/red</b> (imprime en la impresora configurada), <b>Impresora del sistema</b> (abre el diálogo de impresión de Android) o <b>Dejar pendiente</b>.'],
  ['<b>Navegador en celular o tableta</b>', 'Envía la orden a la PC principal. Si la PC principal está apagada, la venta queda como pendiente de impresión.'],
  ['<b>Navegador en una PC</b>', 'Abre el diálogo de impresión del navegador con el ticket en PDF, para elegir cualquier impresora instalada en esa PC.'],
  ['<b>iPhone o iPad</b>', 'Imprime en la impresora de red configurada.'],
])}
<p>Si el interruptor <b>Imprimir facturas automáticamente</b> está apagado en Negocio, no se imprime nada al vender; la venta se guarda igual.</p>

<h3>La impresión remota: cómo funciona</h3>
${figura(
  `<div style="display:flex;align-items:center;gap:1mm;margin:2mm 0">${caja('Celular o navegador', 'Registra la venta y pide imprimir')}${flecha('orden')}${caja('Servidor', 'Marca la venta con «imprimir en vivo»')}${flecha('aviso')}${caja('PC principal', 'Detecta la orden y la procesa sola', 'pri')}${flecha('ticket')}${caja('Impresora', 'Sale el ticket en la caja')}</div>`,
  'Recorrido de una orden de impresión remota.',
  ['El celular termina la venta y, en vez de imprimir, deja la orden de impresión en el servidor.', 'La PC principal está siempre escuchando; al ver la orden imprime el ticket sin mostrar ninguna ventana y sin que nadie toque nada.', 'La orden se borra sola al imprimir, para que no se imprima dos veces.']
)}
${pasos([
  ['La PC principal avisa que está viva.', 'Cada 25 segundos manda una señal de presencia al servidor. Si la última señal tiene menos de 40 segundos, el sistema considera que la PC principal está conectada.'],
  ['El otro equipo comprueba esa señal.', 'Al terminar una venta (o un traslado), antes de pedir la impresión revisa si la PC principal está conectada.'],
  ['Si está conectada, envía la orden.', 'Aparece el mensaje «Se envió la orden de impresión a la caja principal». El ticket sale en pocos segundos.'],
  ['Si no está conectada, la venta queda pendiente.', 'Aparece «La venta quedó pendiente de impresión». Nada se pierde: se puede imprimir después desde <b>Pendientes de Impresión</b>.'],
])}
${aviso('La impresión remota solo funciona si la PC principal tiene el sistema abierto y con la sesión iniciada. Si la apaga o cierra el programa, las órdenes se acumulan como pendientes.', 'Condición')}

<h3>Elegir y configurar la PC principal</h3>
<p>Por defecto, <b>cualquier computadora de escritorio</b> que tenga el sistema abierto actúa como PC principal. Si tiene más de una PC y solo una tiene la impresora, márquela para que las demás no intenten imprimir órdenes ajenas.</p>
${figura(
  pantalla({
    modulo: 'Mantenedor', sub: 'Dispositivos', titulo: 'Dispositivos', alto: 66,
    html: `<h5>Dispositivos</h5>
    <p style="color:#6b7280;margin:0 0 2mm">Última versión publicada: v2</p>
    ${tabla(['Dispositivo', 'Plataforma', 'Versión', 'Último usuario', 'Última conexión', ''], [
      ['CAJA-PRINCIPAL', 'windows', 'v2', 'MARÍA LÓPEZ', '20/10/2026 09:12 a.m.', chip('PC principal', 'ok')],
      ['OFICINA-PC', 'windows', 'v2', 'JOSÉ PÉREZ', '20/10/2026 08:40 a.m.', btn('Marcar como PC principal', 'sec')],
      ['SM-A546E', 'android', 'v1', 'ANA RIVERA', '17/10/2026 05:02 p.m.', chip('Desactualizado', 'aviso')],
    ])}`,
    marcas: [{ n: 1, x: 22, y: 20 }, { n: 2, x: 92, y: 42 }, { n: 3, x: 40, y: 56 }],
  }),
  'Pantalla Dispositivos, donde se marca la PC principal.',
  ['La PC principal actual: es la única que imprime las órdenes remotas.', 'Para cambiar de PC principal toque «Marcar como PC principal» en la fila de la computadora que tiene la impresora (puede hacerlo desde cualquier equipo). Tocar la marca de nuevo la quita y vuelve al comportamiento de siempre.', 'Un equipo con versión vieja aparece como desactualizado.']
)}

<h3>Configurar la impresora de la PC principal</h3>
${pasos([
  ['Instale la impresora en Windows.', 'Con su controlador y papel del ancho correcto. Imprima una página de prueba de Windows para confirmar.'],
  ['Abra Mantenedor ▸ Negocio ▸ Impresoras.', 'En «Impresora térmica» elija la impresora instalada.'],
  ['Elija el ancho del rollo.', '58 mm o 80 mm, según su rollo.'],
  ['Elija el modo de impresión.', '«Directo» imprime al instante; «Preguntar» muestra primero la vista previa.'],
  ['Presione «Imprimir ticket de prueba».', 'Sale un ticket marcado como prueba. No se registra ninguna venta ni se gasta numeración.'],
  ['Marque la PC como principal.', 'En Dispositivos, en la fila de esa computadora, si tiene varias.'],
])}
${consejo('Deje la PC de la caja siempre encendida y con el sistema abierto durante el horario de atención. Si el programa se cierra, el celular lo notará en menos de un minuto y dejará las ventas como pendientes.')}

<h3>Pendientes de Impresión</h3>
<p>Dentro de <b>Registrar Venta</b> está el botón <b>Pendientes de Impresión</b>. Muestra las ventas que no se pudieron imprimir, con el tipo de documento, número, cliente y total. Cada fila tiene un botón de impresora que imprime esa venta desde el equipo en el que usted está; por eso conviene abrir esta lista en la PC que tiene la impresora. Cuando se imprime, sale de la lista.</p>
${figura(
  pantallaSola({
    titulo: 'Pendientes de Impresión', alto: 58,
    html: `<h5>Pendientes de Impresión</h5>
    ${tabla(['Fecha', 'Documento', 'Cliente', 'Total', ''], [
      ['20/10/2026 10:41', 'Factura · 00004531', 'TALLER MECÁNICO LÓPEZ', 'L 4,296.40', btn('Imprimir', 'sec')],
      ['20/10/2026 10:55', 'Venta · 0087', 'Sin cliente', 'L 680.00', btn('Imprimir', 'sec')],
    ], [3])}
    <p style="color:#6b7280;margin-top:2mm">Cuando la lista está vacía se muestra «No hay ventas pendientes de impresión».</p>`,
    marcas: [{ n: 1, x: 8, y: 34 }, { n: 2, x: 90, y: 34 }],
  }),
  'Lista de ventas pendientes de impresión.',
  ['Cada fila es una venta ya registrada: lo único que falta es el papel.', 'Imprime esa venta en este equipo. Hágalo desde la PC de la caja.']
)}

<h3>Impresión en Android</h3>
<p>En un celular o tableta Android, al registrar una venta aparece una pregunta con tres opciones:</p>
${figura(
  pantallaSola({
    titulo: 'Registrar Venta', alto: 44,
    html: `<div style="display:flex;justify-content:center;padding:4mm 0"><div class="tarjeta" style="width:92mm;padding:5mm">
      <b style="font-size:10pt">Venta 00004531 registrada</b>
      <p style="margin:2mm 0 4mm">¿Qué quiere hacer con el ticket?</p>
      <div class="fila" style="justify-content:flex-end">${btn('Dejar pendiente', 'sec')}${btn('Impresora del sistema', 'sec')}${btn('Bluetooth/red')}</div></div></div>`,
    marcas: [{ n: 1, x: 36, y: 63 }, { n: 2, x: 60, y: 63 }, { n: 3, x: 86, y: 63 }],
  }),
  'Pregunta de impresión en Android.',
  ['Guarda la venta como pendiente de impresión para sacarla después.', 'Abre el diálogo de impresión de Android, para PDF o impresoras instaladas en el celular.', 'Imprime directo en la impresora térmica Bluetooth o de red que se configuró en Negocio.']
)}
<p>Para usar una impresora Bluetooth: empareje la impresora desde los ajustes Bluetooth del celular y luego elíjala en <b>Negocio ▸ Impresoras ▸ Impresora Bluetooth</b>. Para una impresora de red escriba su IP y el puerto (normalmente 9100).</p>

<h3>Guía de envío</h3>
<p>Cuando una venta se envía a domicilio (botón <b>Más datos</b> ▸ datos de envío), el sistema puede imprimir además una <b>guía de envío</b> con el nombre, dirección y teléfono del destinatario, en tamaño ticket o en tamaño grande. La guía sigue las mismas reglas: se imprime en el equipo si puede, y si no, se pide a la PC principal.</p>

<h3>Traslados y reimpresiones</h3>
<ul>
  <li>El comprobante de un <b>traslado</b> también se imprime en la PC principal cuando se registra desde un celular; sale con las líneas de firma de quien entrega y de quien recibe.</li>
  <li>Desde <b>Ver Detalle</b> de una venta o traslado, el botón de impresión permite reimprimir como <b>copia</b> o como original. Una reimpresión remota también la procesa la PC principal.</li>
  <li>Si el negocio tiene apagada «Imprimir copia además del original», cada venta sale con una sola hoja.</li>
</ul>

<h3>Tipos de impresora y cuál elegir</h3>
${datos(['Tipo', 'Cuándo usarla', 'Observación'], [
  ['Térmica USB en Windows (impresión directa)', 'La caja principal', 'La más rápida: manda el ticket sin pasar por el controlador.'],
  ['Térmica USB en Windows con controlador', 'Impresoras que no aceptan impresión directa', 'Active «Usar driver de Windows» en Negocio. Es el caso de algunas Star y de impresoras con protocolo propio.'],
  ['Térmica de red (IP)', 'Impresora con cable de red compartida entre equipos', 'Funciona también desde iPhone, iPad y Android.'],
  ['Térmica Bluetooth', 'Vender desde el celular en el mostrador o en ruta', 'Solo Android. Emparejar primero.'],
  ['Impresora común o PDF', 'Respaldo, o cotizaciones en hoja carta', 'Se usa el diálogo de impresión de Windows, Android o del navegador.'],
])}

<h3>Si algo falla</h3>
${datos(['Síntoma', 'Qué revisar'], [
  ['«La venta quedó pendiente de impresión»', 'La PC principal está apagada, sin el sistema abierto o sin internet. Ábralo y use Pendientes de Impresión.'],
  ['Envía la orden pero no sale el ticket', 'Revise que la PC principal tenga la impresora encendida, con papel y elegida en Negocio. Haga el ticket de prueba.'],
  ['Sale papel en blanco sin cortar', 'La impresora no entiende la impresión directa. Active «Usar driver de Windows».'],
  ['Sale el ticket cortado o desalineado', 'Ancho de rollo equivocado: cambie entre 58 y 80 mm.'],
  ['Se imprimen dos hojas', 'Es el original y la copia. Apague «Imprimir copia además del original» si no la necesita.'],
  ['Desde el navegador de la PC sale un PDF y no el ticket', 'Es lo esperado: el navegador no puede enviar el ticket directo a una impresora térmica. Elija la impresora en el diálogo, o venda desde el programa de Windows.'],
  ['Varias PC intentan imprimir lo mismo', 'Marque una sola PC principal en Dispositivos.'],
])}
`;

const capEscaner = `
<p>El celular puede usarse como <b>lector de códigos de barras</b> de la computadora, sin cables ni programas extra. Sirve para agregar repuestos a una venta apuntando la cámara a la etiqueta.</p>
${figura(
  pantallaSola({
    titulo: 'Escanear con el celular', alto: 56,
    html: `<div style="display:flex;gap:6mm;align-items:center;padding:4mm 6mm">
      <div style="width:34mm;height:34mm;background:repeating-conic-gradient(#1a1a1a 0% 25%, #fff 0% 50%) 50% / 6mm 6mm;border:2mm solid #fff;outline:1px solid #b6bcc7"></div>
      <div><b style="font-size:10pt">Escanear con el celular</b><p style="margin:1.5mm 0">Abra la cámara del celular, apunte al código QR y entre al enlace.</p>
      <div class="campo lleno"><b>Código</b>K7M2QX</div>
      <div class="fila" style="margin-top:2mm">${chip('Escaneo activo', 'ok')}<span style="color:#6b7280">3 código(s) recibido(s)</span></div>
      <div class="fila">${btn('Escanear con otro celular', 'sec')}${btn('Finalizar escaneo', 'rojo')}</div></div></div>`,
    marcas: [{ n: 1, x: 14, y: 44 }, { n: 2, x: 62, y: 46 }, { n: 3, x: 60, y: 74 }],
  }),
  'Ventana que muestra el código QR para conectar un celular.',
  ['Código QR que apunta a la página del sistema con un código temporal.', 'Código de 6 letras de esta sesión de escaneo.', 'Indica cuántos códigos ha mandado el celular; con «Finalizar escaneo» se corta la conexión.']
)}
${pasos([
  ['En la PC, en Registrar Venta, presione «Escanear con celular».', 'Aparece el código QR.'],
  ['Con el celular, escanee el QR.', 'Se abre directamente la pantalla de la cámara. No necesita usuario ni clave: solo sirve para mandar códigos.'],
  ['Apunte a la etiqueta del repuesto.', 'El código llega a la PC y el repuesto se agrega a la venta al instante.'],
  ['Siga escaneando.', 'Cada código recibido se agrega a la venta.'],
  ['Presione «Finalizar escaneo».', 'La conexión se corta y el celular queda libre.'],
])}
${consejo('Si usa la aplicación en un celular o tableta Android, ya tiene el botón «Escanear» con la cámara dentro del buscador de productos; el QR es para escanear desde el celular y vender en la PC.')}
<p>Si el código escaneado no coincide con ningún repuesto, el sistema prueba variantes válidas del mismo código (por ejemplo, el cero que algunos iPhone agregan al principio, o el código leído al revés) antes de decir que no existe. Si de verdad no existe, puede crearlo en ese momento con los datos del código ya cargados.</p>
`;

const capInstalacion = `
<h3>Instalar en Windows</h3>
${pasos([
  ['Descargue el instalador.', 'Es el archivo <code>RepuestosPOS.exe</code> de la página de versiones del sistema.'],
  ['Ábralo.', 'No necesita permisos de administrador: se instala solo para su usuario de Windows. Es normal que Windows muestre «Windows protegió su PC»: aparece con cualquier programa nuevo que no tenga un certificado comercial de pago. Elija <b>Más información ▸ Ejecutar de todas formas</b>. Solo se hace en la primera instalación; las actualizaciones que la propia aplicación descarga no lo piden.'],
  ['Acepte las opciones.', 'Puede crear un acceso directo en el Escritorio.'],
  ['Ingrese.', 'Con su documento y clave.'],
])}
<h3>Instalar en Android</h3>
${pasos([
  ['Descargue <code>RepuestosPOS.apk</code> en el celular.', 'Desde la página de versiones del sistema.'],
  ['Permita la instalación desde esa fuente.', 'Android lo pedirá la primera vez: active «Permitir de esta fuente».'],
  ['Abra el archivo e instale.', 'Para actualizar más adelante, el mismo proceso instala encima sin perder nada.'],
])}
<h3>Usar desde el navegador</h3>
<p>Abra la dirección web del sistema en Chrome o Edge. Puede instalarla como aplicación desde el menú del navegador («Instalar Repuestos POS»). Es la forma más rápida de consultar desde un equipo ajeno, sin instalar nada.</p>

<h3>Primer ingreso del administrador</h3>
<p>Quien instaló el sistema le entrega un usuario administrador inicial. Al entrar por primera vez:</p>
<ol>
  <li>Cambie la clave del administrador en <b>Usuarios</b>.</li>
  <li>Complete los datos del negocio en <b>Negocio</b> (capítulo 3).</li>
  <li>Cree las sucursales si las usa y los usuarios de su personal.</li>
  <li>Cargue las categorías y los repuestos (a mano o con <b>Importar</b>).</li>
  <li>Haga una venta de prueba y un ticket de prueba para confirmar la impresión.</li>
</ol>

<h3>Seguridad de la información</h3>
<ul>
  <li>Cada persona entra con su usuario y clave; tras varios intentos fallidos la cuenta se bloquea 5 minutos.</li>
  <li>Las claves se guardan protegidas en el servidor y no se pueden ver ni desde el propio sistema.</li>
  <li>La sesión dura 24 horas y se renueva sola mientras el programa está abierto; al cerrar sesión se descarta.</li>
  <li>La clave especial solo la cambia un administrador.</li>
</ul>

<h3>Respaldo de la información</h3>
<p>Todos los datos viven en la nube, no en cada computadora, así que si una PC se daña no se pierde nada: se instala el programa en otra y se entra con el mismo usuario.</p>
${cuidado('El plan gratuito del servicio no incluye copias de seguridad automáticas. Como respaldo propio, exporte con regularidad a Excel el inventario (Inventario ▸ Excel) y los reportes de ventas y compras, y guárdelos en otro lugar. Si el negocio crece, conviene pasar al plan de pago, que sí respalda a diario.', 'Recomendación')}
<p>Además, si el servicio gratuito se pausa por falta de uso, el sistema lo reanuda solo cada pocos días; si aun así un día no conecta, avise a quien administra el sistema.</p>
`;

module.exports = { capImpresion, capEscaner, capInstalacion };
