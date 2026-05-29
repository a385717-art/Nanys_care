
// lib/features/citas/data/citas_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../notificaciones/data/email_service.dart';

class CitasRepository {
  final _client = Supabase.instance.client;

  final EmailService _emailService = EmailService();

  String get _userId => _client.auth.currentUser!.id;

  // ─────────────────────────────────────────────────────────────
  // US06 — Buscar cuidadores
  // ─────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> buscarCuidadores({
    String? zona,
    double? tarifaMax,
    int? experienciaMin,
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

    if (tarifaMax != null) {
      q = q.lte('tarifa_hora', tarifaMax);
    }

    if (experienciaMin != null && experienciaMin > 0) {
      q = q.gte('experiencia_anios', experienciaMin);
    }

    final data =
        await q.order('calificacion_promedio', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  // ─────────────────────────────────────────────────────────────
  // US08 — Agendar cita
  // ─────────────────────────────────────────────────────────────

  Future<void> agendarCita({
    required String cuidadorId,
    required String fecha,
    required String horaInicio,
    required String horaFin,
    required double tarifaTotal,
    String? notas,
  }) async {
    await _client.from('citas').insert({
      'tutor_id': _userId,
      'cuidador_id': cuidadorId,
      'fecha': fecha,
      'hora_inicio': horaInicio,
      'hora_fin': horaFin,
      'tarifa_total': tarifaTotal,
      'notas': notas,
      'estado': 'pendiente',
    });

    // Notificación por correo
    _enviarCorreoNuevaSolicitud(
      cuidadorId,
      fecha,
      '$horaInicio - $horaFin',
    );
  }

  // ─────────────────────────────────────────────────────────────
  // US12 — Agenda del tutor
  // ─────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getCitasTutor() async {
    final citas = List<Map<String, dynamic>>.from(
      await _client
          .from('citas')
          .select(
            'id, cuidador_id, fecha, hora_inicio, '
            'hora_fin, tarifa_total, estado, notas',
          )
          .eq('tutor_id', _userId)
          .order('fecha', ascending: true),
    );

    if (citas.isEmpty) return [];

    final cuidadorIds = citas
        .map((c) => c['cuidador_id'] as String)
        .toSet()
        .toList();

    final perfiles = List<Map<String, dynamic>>.from(
      await _client
          .from('cuidadores_perfil')
          .select(
            'id, nombre, avatar_url, tarifa_hora, zona',
          )
          .inFilter('id', cuidadorIds),
    );

    final perfilMap = {
      for (final p in perfiles) p['id'] as String: p,
    };

    return citas.map((c) {
      final perfil = perfilMap[c['cuidador_id']];

      return {
        ...c,
        'cuidador': {
          'nombre': perfil?['nombre'] ?? 'Cuidadora',
          'avatar_url': perfil?['avatar_url'],
          'tarifa_hora': perfil?['tarifa_hora'],
          'zona': perfil?['zona'] ?? '',
        },
      };
    }).toList();
  }

  // ─────────────────────────────────────────────────────────────
  // US09/12 — Citas del cuidador
  // ─────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getCitasCuidador() async {
    final citas = List<Map<String, dynamic>>.from(
      await _client
          .from('citas')
          .select(
            'id, tutor_id, fecha, hora_inicio, '
            'hora_fin, tarifa_total, estado, notas',
          )
          .eq('cuidador_id', _userId)
          .order('fecha', ascending: true),
    );

    if (citas.isEmpty) return [];

    final tutorIds = citas
        .map((c) => c['tutor_id'] as String)
        .toSet()
        .toList();

    final perfiles = List<Map<String, dynamic>>.from(
      await _client
          .from('profiles')
          .select(
            'id, nombre, avatar_url, telefono',
          )
          .inFilter('id', tutorIds),
    );

    final perfilMap = {
      for (final p in perfiles) p['id'] as String: p,
    };

    return citas.map((c) {
      final perfil = perfilMap[c['tutor_id']];

      return {
        ...c,
        'tutor': {
          'nombre': perfil?['nombre'] ?? 'Tutor',
          'avatar_url': perfil?['avatar_url'],
          'telefono': perfil?['telefono'],
        },
      };
    }).toList();
  }

  // ─────────────────────────────────────────────────────────────
  // US09 — Aceptar cita
  // ─────────────────────────────────────────────────────────────

  Future<void> aceptarCita(String citaId) async {
    final cita = await _client
        .from('citas')
        .update({'estado': 'aceptada'})
        .eq('id', citaId)
        .eq('cuidador_id', _userId)
        .select()
        .single();

    _enviarCorreoEstadoCita(
      cita['tutor_id'],
      cita['fecha'],
      '${cita['hora_inicio']} - ${cita['hora_fin']}',
      aprobada: true,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // US09 — Rechazar cita
  // ─────────────────────────────────────────────────────────────

  Future<void> rechazarCita(String citaId) async {
    final cita = await _client
        .from('citas')
        .update({'estado': 'rechazada'})
        .eq('id', citaId)
        .eq('cuidador_id', _userId)
        .select()
        .single();

    _enviarCorreoEstadoCita(
      cita['tutor_id'],
      cita['fecha'],
      '${cita['hora_inicio']} - ${cita['hora_fin']}',
      aprobada: false,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Cancelar cita
  // ─────────────────────────────────────────────────────────────

  Future<void> cancelarCita(String citaId) async {
    await _client
        .from('citas')
        .update({'estado': 'cancelada'})
        .eq('id', citaId)
        .eq('tutor_id', _userId);
  }

  // ─────────────────────────────────────────────────────────────
  // Obtener rol
  // ─────────────────────────────────────────────────────────────

  Future<String?> getUserRole() async {
    final data = await _client
        .from('profiles')
        .select('role')
        .eq('id', _userId)
        .maybeSingle();

    return data?['role'] as String?;
  }

  // ─────────────────────────────────────────────────────────────
  // Completar cita
  // ─────────────────────────────────────────────────────────────

  Future<void> completarCita(String citaId) async {
    await _client
        .from('citas')
        .update({'estado': 'completada'})
        .eq('id', citaId)
        .eq('cuidador_id', _userId);
  }

  // ─────────────────────────────────────────────────────────────
  // Calificar cita
  // ─────────────────────────────────────────────────────────────

  Future<void> calificarCita({
    required String citaId,
    required String cuidadorId,
    required int puntuacion,
    required String comentario,
  }) async {
    await _client.from('calificaciones').insert({
      'cita_id': citaId,
      'tutor_id': _userId,
      'cuidador_id': cuidadorId,
      'puntuacion': puntuacion,
      'comentario': comentario.trim(),
    });
  }

  // ─────────────────────────────────────────────────────────────
  // Verificar si ya existe calificación
  // ─────────────────────────────────────────────────────────────

  Future<bool> existeCalificacion(String citaId) async {
    final res = await _client
        .from('calificaciones')
        .select('id')
        .eq('cita_id', citaId)
        .maybeSingle();

    return res != null;
  }

  // ─────────────────────────────────────────────────────────────
  // Helpers privados
  // ─────────────────────────────────────────────────────────────

  Future<void> _enviarCorreoNuevaSolicitud(
    String cuidadorId,
    String fecha,
    String horario,
  ) async {
    try {
      final perfilCuidador = await _client
          .from('profiles')
          .select('email')
          .eq('id', cuidadorId)
          .maybeSingle();

      final perfilTutor = await _client
          .from('profiles')
          .select('nombre')
          .eq('id', _userId)
          .maybeSingle();

      if (perfilCuidador != null &&
          perfilCuidador['email'] != null) {
        await _emailService.notificarSolicitudEnviada(
          emailCuidador: perfilCuidador['email'],
          nombreTutor:
              perfilTutor?['nombre'] ?? 'Un tutor',
          fecha: fecha,
          hora: horario,
        );
      }
    } catch (e) {
      print(
        'Error al enviar correo de nueva solicitud: $e',
      );
    }
  }

  Future<void> _enviarCorreoEstadoCita(
    String tutorId,
    String fecha,
    String horario, {
    required bool aprobada,
  }) async {
    try {
      final perfilTutor = await _client
          .from('profiles')
          .select('email')
          .eq('id', tutorId)
          .maybeSingle();

      final perfilCuidador = await _client
          .from('profiles')
          .select('nombre')
          .eq('id', _userId)
          .maybeSingle();

      if (perfilTutor != null &&
          perfilTutor['email'] != null) {
        if (aprobada) {
          await _emailService.notificarCitaConfirmada(
            emailTutor: perfilTutor['email'],
            nombreCuidador:
                perfilCuidador?['nombre'] ??
                    'El cuidador',
            fecha: fecha,
            hora: horario,
          );
        } else {
          await _emailService.notificarCitaRechazada(
            emailTutor: perfilTutor['email'],
            fecha: fecha,
          );
        }
      }
    } catch (e) {
      print(
        'Error al enviar correo de actualización de cita: $e',
      );
    }
  }
  Future<Map<String, dynamic>> crearCita({
    required String cuidadorId,
    required DateTime fecha,
    required String horaInicio,
    required String horaFin,
    required double tarifaTotal,
    String? notas,
  }) async {
    final nuevaCita = await _client.from('citas').insert({
      'tutor_id': _userId,
      'cuidador_id': cuidadorId,
      'fecha': fecha.toIso8601String().split('T')[0],
      'hora_inicio': horaInicio,
      'hora_fin': horaFin,
      'tarifa_total': tarifaTotal,
      'notas': notas,
      'estado': 'pendiente',
    }).select().single();

    // correo opcional
    _enviarCorreoNuevaSolicitud(
      cuidadorId,
      fecha.toIso8601String().split('T')[0],
      '$horaInicio - $horaFin',
    );

    return nuevaCita;
  }

}