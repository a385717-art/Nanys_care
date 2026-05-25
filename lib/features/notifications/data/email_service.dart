import 'package:http/http.dart' as http;
import 'dart:convert';

class EmailService {
  final String _apiKey = 're_YOUR_RESEND_API_KEY_HERE';
  final String _baseUrl = 'https://api.resend.com/emails';

  /// Integra de forma directa la API Rest de Resend para notificaciones seguras. (US10)
  Future<bool> enviarCorreo({
    required String para,
    required String asunto,
    required String contenidoHtml,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer \$_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'from': 'Nanys Care <onboarding@resend.dev>',
          'to': [para],
          'subject': asunto,
          'html': contenidoHtml,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<void> notificarConfirmacionReserva(String email, String fecha, String hora) async {
    await enviarCorreo(
      para: email,
      asunto: 'Reserva Confirmada - Nanys Care',
      contenidoHtml: '<h2>¡Tu cita ha sido confirmada con éxito!</h2><p>Día: \$fecha</p><p>Horario: \$hora</p>',
    );
  }
}
