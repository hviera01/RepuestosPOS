import 'dart:typed_data';
import 'package:http/http.dart' as http;

class RemoveBgService {
  static const _apiKey = 'ZAXf2NGiNNAwYcCd8Ghu4TUt';

  Future<Uint8List> quitarFondo(String imagenUrl) async {
    final res = await http.post(
      Uri.parse('https://api.remove.bg/v1.0/removebg'),
      headers: {'X-Api-Key': _apiKey},
      body: {
        'image_url': imagenUrl,
        'size': 'preview',
        'format': 'png',
      },
    );
    if (res.statusCode != 200) {
      throw Exception('remove.bg respondió ${res.statusCode}: ${res.body}');
    }
    return res.bodyBytes;
  }
}
