// lib/features/cuidadores/data/cuidadores_repository.dart
// Repositorio para buscar cuidadores desde la vista cuidadores_perfil

import 'package:supabase_flutter/supabase_flutter.dart';

class CuidadoresRepository {
  final _client = Supabase.instance.client;

  /// Busca cuidadores disponibles con filtros opcionales.
  /// Requiere que exista la VIEW "cuidadores_perfil" en Supabase con columnas:
  /// id, nombre, avatar_url, zona, tarifa_hora, experiencia_anios,
  /// calificacion_promedio, total_calificaciones, descripcion, disponible
  Future<List<Map<String, dynamic>>> buscarCuidadores({
    String? zona,
    double? tarifaMaxima,
    int? experienciaMinima,
  }) async {
    var q = _client
        .from('cuidadores_perfil')
        .select(
          'id, nombre, avatar_url, zona, tarifa_hora, '
          'experiencia_anios, calificacion_promedio, '
          'total_calificaciones, descripcion, disponible',
        )
        .eq('disponible', true);

    if (zona != null && zona.trim().isNotEmpty) {
      q = q.ilike('zona', '%${zona.trim()}%');
    }
    if (tarifaMaxima != null) {
      q = q.lte('tarifa_hora', tarifaMaxima);
    }
    if (experienciaMinima != null && experienciaMinima > 0) {
      q = q.gte('experiencia_anios', experienciaMinima);
    }

    final data = await q.order('calificacion_promedio', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }
}