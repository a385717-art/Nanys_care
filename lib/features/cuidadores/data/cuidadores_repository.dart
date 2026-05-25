import 'package:supabase_flutter/supabase_flutter.dart';

class CuidadoresRepository {
  final _client = Supabase.instance.client;

  /// Busca niñeras aplicando filtros opcionales de zona geográfica, 
  /// tarifa por hora máxima y años de experiencia mínima. (US06)
  Future<List<Map<String, dynamic>>> buscarCuidadores({
    String? zona,
    double? tarifaMaxima,
    int? experienciaMinima,
  }) async {
    try {
      var query = _client.from('cuidadores').select('*, profiles(*)');

      if (zona != null && zona.isNotEmpty) {
        query = query.ilike('zona', '%$zona%');
      }
      if (tarifaMaxima != null) {
        query = query.lte('tarifa_hora', tarifaMaxima);
      }
      if (experienciaMinima != null) {
        query = query.gte('experiencia_anios', experienciaMinima);
      }

      // Filtrar por disponibilidad activa
      query = query.eq('disponible', true);

      final List<dynamic> response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al filtrar catálogo de cuidadores: $e');
    }
  }
}
