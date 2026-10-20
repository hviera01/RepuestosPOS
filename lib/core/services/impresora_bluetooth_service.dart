import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

class ImpresoraBluetoothService {
  Future<List<BluetoothInfo>> listarEmparejadas() async {
    try {
      return await PrintBluetoothThermal.pairedBluetooths;
    } catch (_) {
      return const [];
    }
  }

  Future<bool> bluetoothEncendido() async {
    try {
      return await PrintBluetoothThermal.bluetoothEnabled;
    } catch (_) {
      return false;
    }
  }

  Future<bool> imprimir({required String macAddress, required List<int> bytes}) async {
    if (macAddress.trim().isEmpty) return false;
    try {
      final conectado = await PrintBluetoothThermal.connect(macPrinterAddress: macAddress.trim());
      if (!conectado) return false;
      return await PrintBluetoothThermal.writeBytes(bytes);
    } catch (_) {
      return false;
    }
  }
}
