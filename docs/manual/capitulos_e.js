const H = require('./helpers');
const { datos } = H;

const capGlosario = `
<p>Palabras que usa el sistema y lo que significan.</p>
${datos(['Palabra', 'Qué significa'], [
  ['Existencia', 'Cuántas unidades de un repuesto hay disponibles para vender.'],
  ['Lote de costo', 'Grupo de unidades que se compraron juntas a un mismo costo. Al vender, el sistema descuenta del lote más antiguo (el primero que entró es el primero que sale).'],
  ['Precio final', 'El precio que paga el cliente. Es el que se guarda en el inventario; el sistema nunca le suma el ISV encima.'],
  ['ISV', 'Impuesto sobre ventas (15%). En una factura se muestra separado del precio.'],
  ['Subtotal', 'En una factura, el precio sin ISV. En una venta sin ISV no se muestra salvo que haya descuentos.'],
  ['Descuentos y rebajas', 'Lo que se le rebajó al cliente por descuentos en porcentaje, descuento general o promociones.'],
  ['Cotización', 'Precio que se da al cliente sin vender todavía. No descuenta existencias. Puede ser con ISV o sin ISV.'],
  ['Venta en espera', 'Venta guardada para continuarla después; reserva las existencias.'],
  ['Crédito', 'Venta que el cliente pagará después, con abonos. También hay compras a crédito que usted paga al proveedor.'],
  ['Abono', 'Pago parcial (o total) que se le hace a un crédito.'],
  ['Pago mixto', 'Una venta pagada con más de un método, por ejemplo parte en efectivo y parte con tarjeta.'],
  ['Traslado', 'Movimiento de mercadería de una sucursal a otra.'],
  ['Caja', 'El turno de un cajero: se abre con un fondo de efectivo y se cierra contando el dinero.'],
  ['Fondo inicial', 'El efectivo con el que se abre la caja.'],
  ['Efectivo esperado', 'Lo que debería haber en la gaveta según las ventas, abonos y gastos en efectivo.'],
  ['Corte X', 'Resumen de la caja a mitad del turno, sin cerrarla.'],
  ['Corte Z', 'Resumen final al cerrar la caja.'],
  ['Diferencia', 'Efectivo contado menos efectivo esperado. Si es negativa falta dinero; si es positiva sobra.'],
  ['Clave especial', 'Segunda clave, solo del administrador, que se pide antes de acciones delicadas.'],
  ['PC principal', 'La computadora con la impresora conectada, que imprime los tickets pedidos desde otros equipos.'],
  ['Vehículo compatible', 'Marca, modelo y años de los vehículos para los que sirve un repuesto.'],
  ['CAI', 'Código de autorización de impresión que da el SAR para emitir facturas dentro de un rango de numeración y hasta una fecha límite.'],
])}
`;

module.exports = { capGlosario };
