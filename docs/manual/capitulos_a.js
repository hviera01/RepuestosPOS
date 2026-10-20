const H = require('./helpers');
const { pantalla, pantallaSola, campo, btn, chip, kpi, tabla, figura, aviso, consejo, cuidado, pasos, datos } = H;

const cap1 = `
<p><b>Repuestos POS</b> es el sistema con el que su negocio registra ventas, compras, inventario, créditos, traslados entre sucursales y cierres de caja. Funciona en computadoras con Windows, en celulares y tabletas Android y desde el navegador web. Todos los equipos trabajan sobre la misma información: lo que se registra en uno aparece en los demás en pocos segundos.</p>

<h3>Qué puede hacer con el sistema</h3>
<ul>
  <li>Vender con <b>factura</b> o con <b>venta simple</b>, hacer cotizaciones, ventas a crédito y pagos mixtos (parte en efectivo y parte con tarjeta o transferencia).</li>
  <li>Controlar el inventario con existencias, costos por lote, historial de movimientos y fotos de cada repuesto.</li>
  <li>Indicar para qué <b>vehículos y años</b> sirve cada repuesto, y encontrar rápido el repuesto correcto buscando por marca, modelo y año.</li>
  <li>Mover mercadería entre <b>sucursales</b> con traslados que descuentan existencias y se pueden anular.</li>
  <li>Dar seguimiento a las cuentas por cobrar (clientes) y por pagar (proveedores).</li>
  <li>Cerrar la caja, registrar egresos y consultar reportes de ventas, compras, traslados y finanzas.</li>
  <li>Cambiar los colores del sistema y elegir si la venta empieza como factura o como venta simple.</li>
</ul>

<h3>Equipos y requisitos</h3>
${datos(['Equipo', 'Cómo se usa', 'Notas'], [
  ['Computadora con Windows 10 u 11', 'Programa instalado desde el archivo <code>RepuestosPOS.exe</code>', 'Recomendado para la caja principal; es el que conecta la impresora de tickets.'],
  ['Celular o tableta Android', 'Aplicación instalada desde <code>RepuestosPOS.apk</code>', 'Sirve para vender, consultar inventario y escanear códigos de barras con la cámara.'],
  ['Navegador web', 'Dirección web del sistema (la entrega quien le instaló el sistema)', 'Chrome o Edge actualizados. No necesita instalar nada.'],
])}
<p>Todos los equipos necesitan internet. Si la conexión se interrumpe un momento, el sistema vuelve a intentar solo y avisa cuando una operación quedó pendiente (ver capítulo 14).</p>

<h3>Cómo está organizado este manual</h3>
<p>Los capítulos siguen el orden en que normalmente se empieza a trabajar: ingresar, configurar el negocio, crear usuarios, cargar inventario, vender y comprar, y finalmente los reportes. Dentro del sistema, cada pantalla importante tiene un botón de ayuda con el ícono de un birrete: al tocarlo se abre una guía paso a paso sobre esa pantalla.</p>
${consejo('Si es la primera vez que usa el sistema, lea los capítulos 2, 3 y 4 antes de registrar la primera venta. Con eso queda listo el negocio, los usuarios y los permisos.')}
`;

const cap2 = `
<h3>Ingresar al sistema</h3>
<p>Al abrir el programa se muestra una breve pantalla de bienvenida y luego la pantalla de ingreso. Cada persona entra con su <b>documento</b> (el código que le asignó el administrador) y su <b>clave</b>.</p>
${figura(
  pantallaSola({
    titulo: 'Ingreso',
    alto: 70,
    html: `<div style="display:flex;justify-content:center;padding:6mm 0"><div class="tarjeta" style="width:62mm;text-align:center;padding:6mm">
      <div style="width:14mm;height:14mm;border-radius:50%;background:#303846;margin:0 auto 3mm"></div>
      <h5 style="margin:0 0 3mm">Repuestos</h5>
      <div class="campo" style="margin-bottom:2mm;text-align:left"><b>Documento</b>0801199012345</div>
      <div class="campo" style="margin-bottom:3mm;text-align:left"><b>Clave</b>••••••••</div>
      <div class="btn" style="display:block;text-align:center">Ingresar</div>
      <div style="margin-top:3mm;color:#6b7280">Entrar con huella o Face ID</div></div></div>`,
    marcas: [{ n: 1, x: 40, y: 38 }, { n: 2, x: 40, y: 52 }, { n: 3, x: 62, y: 64 }, { n: 4, x: 47, y: 76 }],
  }),
  'Pantalla de ingreso. El color de fondo es el color principal que se elige en Negocio.',
  ['Escriba su documento.', 'Escriba su clave. Si se equivoca varias veces seguidas, la cuenta se bloquea unos minutos por seguridad.', 'Presione Ingresar.', 'En equipos compatibles puede activar la huella o Face ID para entrar sin escribir la clave.']
)}
${aviso('Cada persona debe usar su propio usuario. Así los reportes muestran quién hizo cada venta, compra o ajuste de inventario.')}

<h3>La pantalla principal</h3>
<p>Después de ingresar se muestra el <b>Inicio</b>. A la izquierda está el menú con todos los módulos; arriba, las pestañas abiertas; y en el centro, el resumen del negocio.</p>
${figura(
  pantalla({
    modulo: 'Ventas', sub: 'Registrar Venta', titulo: 'Inicio',
    alto: 78,
    html: `<h5>Inicio</h5>
    <div class="fila">${chip('Inicio')}${chip('Registrar Venta', 'ok')}${chip('Inventario')}</div>
    <div class="rejilla g3" style="margin-bottom:2mm">${kpi('Venta de hoy', 'L 18,450.00')}${kpi('Venta del mes', 'L 412,980.00')}${kpi('Ticket promedio', 'L 615.00')}</div>
    <div class="tarjeta"><b>Ventas de los últimos 7 días</b>
      <div style="display:flex;align-items:flex-end;gap:3mm;height:20mm;margin-top:2mm">
        ${[40, 62, 35, 80, 55, 90, 48].map((h) => `<div style="flex:1;background:#303846;height:${h}%;border-radius:2px 2px 0 0"></div>`).join('')}
      </div></div>`,
    marcas: [{ n: 1, x: 8, y: 30 }, { n: 2, x: 40, y: 28 }, { n: 3, x: 40, y: 45 }, { n: 4, x: 82, y: 6 }],
  }),
  'Pantalla de inicio con el menú, las pestañas y los totales de ventas.',
  ['<b>Menú lateral.</b> Los módulos que no aparecen son los que su usuario no tiene permitidos.', '<b>Pestañas.</b> Cada pantalla se abre en una pestaña propia; puede tener varias a la vez.', '<b>Resumen.</b> Venta del día, del mes y de la semana (visible para administradores).', '<b>Usuario.</b> Desde aquí se cierra la sesión.']
)}

<h3>Trabajar con varias pestañas</h3>
<p>Cada pestaña es independiente: puede dejar una venta a medias en una pestaña, abrir el inventario en otra para consultar una existencia y volver a la venta sin perder nada. Un cuadro de búsqueda abierto en una pestaña no afecta a las demás.</p>
<ul>
  <li>Para abrir una pantalla, toque su nombre en el menú.</li>
  <li>Para cerrar una pestaña, use la <b>x</b> de su etiqueta.</li>
  <li>En el celular el menú se muestra con el botón de las tres rayas.</li>
</ul>

<h3>Cerrar sesión</h3>
<p>Abra el menú de su usuario, arriba a la derecha, y elija <b>Cerrar sesión</b>. Hágalo siempre que otra persona vaya a usar el equipo.</p>
`;

const cap3 = `
<p>Antes de vender, el administrador debe completar los datos del negocio. Todo se hace en <b>Mantenedor ▸ Negocio</b>. Los cambios se guardan al instante y se aplican a todos los equipos.</p>

${figura(
  pantalla({
    modulo: 'Mantenedor', sub: 'Negocio', titulo: 'Negocio', alto: 92,
    html: `<h5>Negocio</h5>
    <div class="tarjeta" style="margin-bottom:2mm"><b>Datos del negocio</b>
      <div class="fila" style="margin-top:1.5mm">${campo('Nombre', 'REPUESTOS EL BUEN FRENO')}${campo('RTN', '08011990123456')}${campo('Teléfono', '2222-3344')}</div>
      <div class="fila">${campo('Dirección', 'Col. Centro, Av. Principal')}${campo('Correo', 'ventas@negocio.hn')}</div>
      <div class="fila">${campo('CAI', 'A1B2C3-D4E5F6-…')}${campo('Rango autorizado', '000-001-01-00000001 a …00005000')}${campo('Fecha límite', '31/12/2026')}</div>
    </div>
    <div class="tarjeta"><b>Apariencia y documento por defecto</b>
      <div class="fila" style="margin-top:1.5mm">
        ${['#303846', '#475569', '#1E3A5F', '#1F5F46', '#7A1F2B', '#A23E1E', '#8A6414', '#5B2A63', '#0E6E78'].map((c, i) => `<span style="width:7mm;height:7mm;border-radius:50%;background:${c};display:inline-block;${i === 0 ? 'outline:2px solid #1a1a1a;outline-offset:1px' : ''}"></span>`).join('')}
      </div>
      <div class="fila">${campo('Color propio', '#RRGGBB')}${btn('Aplicar', 'sec')}${btn('Restablecer', 'sec')}</div>
      <div class="fila">${chip('Factura', 'ok')}${chip('Venta')}<span style="color:#6b7280">Documento que aparece primero al vender</span></div>
    </div>`,
    marcas: [{ n: 1, x: 24, y: 24 }, { n: 2, x: 24, y: 46 }, { n: 3, x: 24, y: 70 }, { n: 4, x: 54, y: 88 }],
  }),
  'Pantalla de Negocio: datos generales, apariencia y documento por defecto.',
  ['<b>Datos generales:</b> nombre, RTN, teléfono, dirección, correo y eslogan. Salen impresos en los tickets y facturas.', '<b>Autorización fiscal:</b> CAI, rango de numeración autorizado y fecha límite de emisión.', '<b>Color principal:</b> toque una muestra o escriba un color propio. Cambia todo el sistema en todos los equipos.', '<b>Documento por defecto:</b> elija si al abrir una venta aparece primero Factura o Venta.']
)}

<h3>Datos del negocio y autorización fiscal</h3>
<p>Llene los campos y presione <b>Guardar</b>. Si el negocio emite facturas con CAI, complete el rango autorizado y la fecha límite; el sistema numera las facturas en orden y respeta ese rango.</p>
<p>Al registrar la primera factura puede indicar con qué número debe continuar la numeración (por ejemplo, para seguir un talonario que ya venía usando) en la tarjeta <b>Factura ▸ Numeración de facturas</b>.</p>

<h3>Logo</h3>
<p>Puede subir el logo a color y el logo en blanco y negro. El de blanco y negro se usa en los tickets térmicos.</p>

<h3>Color del sistema</h3>
<p>El sistema viene en un gris grafito neutro. Para ajustarlo a los colores de su negocio, entre a <b>Negocio ▸ Apariencia y documento por defecto</b> y elija una de las nueve muestras o escriba un código de color propio, por ejemplo <code>#1F5F46</code>. Al cambiarlo, las ventanas abiertas se refrescan en todos los equipos.</p>
${cuidado('Elija un color medio u oscuro. Con colores muy claros el texto blanco de los botones se lee mal.')}

<h3>Documento por defecto: Factura o Venta</h3>
<p>Al abrir <b>Registrar Venta</b>, el sistema propone un tipo de documento. En <b>Negocio</b> usted decide cuál aparece primero:</p>
${datos(['Tipo', 'Qué hace'], [
  ['<b>Factura</b>', 'Cobra el ISV (15%) desglosado y usa la numeración con CAI. Se imprime como factura.'],
  ['<b>Venta</b>', 'Venta simple, sin factura. Se imprime como ticket de venta y tiene su propia numeración.'],
  ['Boleta', 'Documento formal con ISV, igual que la factura en cuanto a impuestos.'],
  ['Cotización', 'No descuenta existencias ni suma a las ventas; sirve para dar un precio al cliente.'],
])}
<p>Aunque haya elegido uno por defecto, en cada venta puede cambiar el tipo antes de registrarla.</p>

<h3>Impresión de tickets y facturas</h3>
<p>En la tarjeta <b>Impresoras</b> y en <b>Factura</b> se configura todo lo relacionado con la impresión:</p>
${datos(['Opción', 'Para qué sirve'], [
  ['Imprimir facturas automáticamente', 'Interruptor general. Apáguelo si todavía no tiene impresora.'],
  ['Imprimir copia además del original', 'Si lo apaga, solo sale la hoja ORIGINAL y se ahorra papel.'],
  ['Mostrar precios con ISV incluido', 'El precio de cada línea del ticket se muestra con el impuesto incluido.'],
  ['Ancho del rollo (58 o 80 mm)', 'Elija el ancho de su impresora térmica.'],
  ['Modo de impresión', '«Preguntar» muestra una vista previa; «Directo» imprime sin preguntar.'],
  ['Impresora térmica de Windows', 'Elija la impresora instalada en el equipo.'],
  ['Impresora de red (IP y puerto)', 'Para impresoras con cable de red; el puerto habitual es 9100.'],
  ['Impresora Bluetooth (Android)', 'Empareje la impresora en el celular y elíjala aquí.'],
  ['Usar driver de Windows', 'Actívelo si su impresora no acepta impresión directa (algunas Star, por ejemplo).'],
  ['PC principal', 'Marque el equipo que tiene la impresora conectada para que imprima los tickets pedidos desde otros equipos.'],
])}
<p>El botón <b>Imprimir ticket de prueba</b> genera un ticket de prueba sin registrar ninguna venta real.</p>

<h3>Clave especial</h3>
<p>La clave especial es una segunda clave, conocida solo por el administrador, que el sistema pide antes de acciones delicadas (ver capítulo 4). Se crea y se cambia en <b>Negocio ▸ Seguridad</b>. Allí mismo se marca cuáles acciones la piden.</p>

<h3>Otros ajustes</h3>
<ul>
  <li><b>Teclado compacto en tableta:</b> usa un teclado propio más pequeño para que no tape la pantalla.</li>
  <li><b>Face ID / huella:</b> permite que cada persona entre sin escribir su clave en su dispositivo.</li>
  <li><b>Dispositivos:</b> lista los equipos que usan el sistema, su versión y su última conexión. Sirve para detectar equipos desactualizados y para marcar la PC principal.</li>
</ul>
`;

const cap4 = `
<p>Los usuarios se crean y se editan en <b>Usuarios</b>. Esta pantalla solo la ve el administrador.</p>

${figura(
  pantalla({
    modulo: 'Usuarios', titulo: 'Usuarios', alto: 80,
    html: `<h5>Usuarios</h5>
    <div class="fila">${campo('Buscar usuario…')}${btn('Nuevo Usuario')}</div>
    ${tabla(['Documento', 'Nombre', 'Rol', 'Estado'], [
      ['0801199012345', 'MARÍA LÓPEZ', 'Administrador', chip('Activo', 'ok')],
      ['0801198811111', 'JOSÉ PÉREZ', 'Encargado', chip('Activo', 'ok')],
      ['0801200122222', 'ANA RIVERA', 'Empleado', chip('Activo', 'ok')],
      ['0801199533333', 'LUIS MEJÍA', 'Empleado', chip('Inactivo', 'mal')],
    ])}
    <div class="tarjeta" style="margin-top:2mm"><b>Nuevo usuario</b>
      <div class="fila" style="margin-top:1.5mm">${campo('Documento')}${campo('Nombre completo')}${campo('Rol', 'Encargado ▾')}</div>
      <div class="fila">${chip('Pantallas permitidas')}${chip('Acciones permitidas')}</div></div>`,
    marcas: [{ n: 1, x: 82, y: 22 }, { n: 2, x: 62, y: 70 }, { n: 3, x: 42, y: 84 }],
  }),
  'Lista de usuarios y formulario para crear uno nuevo.',
  ['Botón para crear un usuario nuevo.', 'El <b>rol</b> define qué puede hacer la persona.', 'Para el rol Encargado (y opcionalmente Empleado) se eligen las pantallas y acciones permitidas.']
)}

<h3>Roles</h3>
${datos(['Rol', 'Qué puede hacer'], [
  ['<b>Administrador</b>', 'Todo: configuración, usuarios, inventario, reportes financieros, anulaciones. Nunca se le piden permisos adicionales.'],
  ['<b>Semi Administrador</b>', 'Casi todo lo operativo. No entra a las pantallas reservadas al administrador (por ejemplo Usuarios o Negocio).'],
  ['<b>Empleado</b>', 'Por defecto: Registrar Venta, Ver Detalle de ventas, Clientes, Proveedores y Créditos. Se puede ajustar pantalla por pantalla.'],
  ['<b>Encargado</b>', 'Rol a la medida: el administrador marca exactamente qué pantallas ve y qué acciones puede hacer.'],
])}

<h3>Pantallas permitidas y acciones permitidas</h3>
<p>Al crear o editar un usuario con rol Encargado aparecen dos listas de casillas:</p>
<ul>
  <li><b>Pantallas permitidas:</b> los módulos que verá en el menú.</li>
  <li><b>Acciones permitidas:</b> botones que podrá usar dentro de esas pantallas.</li>
</ul>
${datos(['Acción', 'Qué controla'], [
  ['Crear clientes / Editar clientes / Eliminar clientes', 'Botones «Nuevo Cliente», «Editar» y «Eliminar» en Clientes.'],
  ['Registrar compras', 'Botón «Registrar Compra».'],
  ['Anular compras', 'Botón «Anular Compra» en el detalle de una compra.'],
  ['Crear productos en Inventario', 'Botón «Nuevo Producto».'],
  ['Eliminar productos en Inventario', 'Eliminar un producto desde su ficha.'],
  ['Anular ventas', 'Botón «Anular Venta» en el detalle de una venta.'],
  ['Anular traslados', 'Botón «Anular» en el detalle de un traslado.'],
])}
${consejo('Cree un usuario Encargado para quien atiende el mostrador: marque «Registrar Venta», «Clientes» y «Ver Detalle», y deje sin marcar las anulaciones. Así vende sin riesgo de anular documentos.')}

<h3>La clave especial</h3>
<p>Algunas acciones delicadas piden la <b>clave especial</b> del negocio aunque el usuario ya haya ingresado. Se activan o desactivan una por una en <b>Negocio ▸ Seguridad</b>:</p>
${datos(['Acción protegida', 'Cuándo se pide la clave'], [
  ['Editar productos en Inventario', 'Solo si cambia un precio (de compra o de venta). Cambiar el nombre o la ubicación no la pide.'],
  ['Cambiar existencias en Inventario', 'Al confirmar un ajuste de existencia.'],
  ['Eliminar créditos', 'Antes de eliminar un crédito.'],
  ['Cambiar el precio de un producto en Ventas', 'Al modificar el precio unitario dentro de una venta.'],
  ['Editar la descripción de un producto en Ventas', 'Al cambiar el texto de una línea de venta.'],
  ['Vender un producto sin existencia', 'Al agregar a una venta un producto que no tiene existencias.'],
])}
${cuidado('La clave especial no debe compartirse con empleados. Si alguien la conoce y no debería, cámbiela en Negocio.')}
<p>Un usuario Encargado al que el administrador le marcó una acción protegida como permitida puede realizarla sin escribir la clave especial.</p>

<h3>Desactivar un usuario</h3>
<p>Cuando alguien deja de trabajar en el negocio no se elimina su usuario (para conservar el historial): se edita y se cambia su estado a <b>Inactivo</b>. Ya no podrá ingresar.</p>
`;

module.exports = { cap1, cap2, cap3, cap4 };
