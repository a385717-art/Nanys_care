import 'package:supabase_flutter/supabase_flutter.dart';

class CalificacionesRepository {
  final _client = Supabase.instance.client;

  /// Registra una nueva reseña de servicio (US11)
  Future<void> registrarCalificacion({
    required String citaId,
    required String cuidadorId,
    required int estrellas,
    required String comentario,
  }) async {
    try {
      final tutorId = _client.auth.currentUser!.id;
      await _client.from('calificaciones').insert({
        'cita_id': citaId,
        'tutor_id': tutorId,
        'cuidador_id': cuidadorId,
        'estrellas': estrellas,
        'comentario': comentario,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Error de base de datos al calificar cuidador: \$e');
    }
  }
}
