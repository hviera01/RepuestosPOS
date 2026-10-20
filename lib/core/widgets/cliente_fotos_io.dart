import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

http.Client crearClienteFotos() {
  final httpClient = HttpClient()
    ..badCertificateCallback = (cert, host, port) => host == 'res.cloudinary.com';
  return IOClient(httpClient);
}
