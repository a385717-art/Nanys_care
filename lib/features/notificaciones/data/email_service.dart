// lib/features/notificaciones/data/email_service.dart
// US10 — Notificaciones por correo (Sprint 3)
// Usa la API de Resend. La clave va en secrets.dart, nunca hardcodeada.

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/secrets.dart';

class EmailService {
  static const _baseUrl = 'https://api.resend.com/emails';

  /// Envía un correo usando la API REST de Resend.
  /// Retorna true si fue exitoso.
  Future<bool> enviarCorreo({
    required String para,
    required String asunto,
    required String contenidoHtml,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer ${AppSecrets.resendApiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'from'   : 'Nanys Care <onboarding@resend.dev>',
          'to'     : [para],
          'subject': asunto,
          'html'   : contenidoHtml,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // ── Plantillas predefinidas ───────────────────────────────────────────────

  Future<void> notificarSolicitudEnviada({
    required String emailCuidador,
    required String nombreTutor,
    required String fecha,
    required String hora,
  }) async {
    await enviarCorreo(
      para: emailCuidador,
      asunto: 'Nueva solicitud de cita — Nanys Care',
      contenidoHtml: '''
        <h2>Tienes una nueva solicitud</h2>
        <p><strong>$nombreTutor</strong> quiere agendar un servicio contigo.</p>
        <p>📅 Fecha: $fecha</p>
        <p>🕐 Horario: $hora</p>
        <p>Ingresa a la app para aceptar o rechazar la solicitud.</p>
      ''',
    );
  }

  Future<void> notificarCitaConfirmada({
    required String emailTutor,
    required String nombreCuidador,
    required String fecha,
    required String hora,
  }) async {
    await enviarCorreo(
      para: emailTutor,
      asunto: 'Cita confirmada — Nanys Care',
      contenidoHtml: '''
        <h2>¡Tu cita fue confirmada!</h2>
        <p><strong>$nombreCuidador</strong> aceptó tu solicitud.</p>
        <p>📅 Fecha: $fecha</p>
        <p>🕐 Horario: $hora</p>
        <p>Te esperamos. Recuerda llegar puntual.</p>
      ''',
    );
  }

  Future<void> notificarCitaRechazada({
    required String emailTutor,
    required String fecha,
  }) async {
    await enviarCorreo(
      para: emailTutor,
      asunto: 'Solicitud rechazada — Nanys Care',
      contenidoHtml: '''
        <h2>Tu solicitud no pudo ser aceptada</h2>
        <p>La cuidadora no pudo aceptar tu solicitud para el <strong>$fecha</strong>.</p>
        <p>Puedes buscar otra cuidadora disponible en la app.</p>
      ''',
    );
  }
}