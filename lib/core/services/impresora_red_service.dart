import 'dart:async';
import 'dart:io';

class ImpresoraRedService {
  static const _timeoutConexion = Duration(seconds: 5);

  Future<bool> imprimir({required String ip, required int puerto, required List<int> bytes}) async {
    if (ip.trim().isEmpty) return false;
    Socket? socket;
    try {
      socket = await Socket.connect(ip.trim(), puerto, timeout: _timeoutConexion);
      socket.add(bytes);
      await socket.flush();
      return true;
    } catch (_) {
      return false;
    } finally {
      unawaited(socket?.close());
    }
  }
}
