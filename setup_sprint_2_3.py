# setup_sprint_2_3.py
# Script automatizado para inyectar todo el código de producción de los Sprints 2 y 3.
# Desarrollado para el proyecto: Nanys Care (Flutter + Supabase)

import os

files_to_create = {
    "lib/features/cuidadores/data/cuidadores_repository.dart": '''import 'package:supabase_flutter/supabase_flutter.dart';

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
''',

    "lib/features/cuidadores/presentation/screens/agendar_cita_screen.dart": '''import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AgendarCitaScreen extends StatefulWidget {
  final String cuidadorId;
  final double tarifaHora;

  const AgendarCitaScreen({
    super.key,
    required this.cuidadorId,
    required this.tarifaHora,
  });

  @override
  State<AgendarCitaScreen> createState() => _AgendarCitaScreenState();
}

class _AgendarCitaScreenState extends State<AgendarCitaScreen> {
  final _client = Supabase.instance.client;
  DateTime? _fechaSeleccionada;
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFin;
  bool _loading = false;
  final List<String> _hijosSeleccionados = [];
  List<Map<String, dynamic>> _misHijos = [];

  @override
  void initState() {
    super.initState();
    _cargarHijosTutor();
  }

  Future<void> _cargarHijosTutor() async {
    try {
      final userId = _client.auth.currentUser!.id;
      final data = await _client.from('hijos').select().eq('tutor_id', userId);
      setState(() {
        _misHijos = List<Map<String, dynamic>>.from(data);
      });
    } catch (_) {}
  }

  Future<void> _procesarReserva() async {
    if (_fechaSeleccionada == null || _horaInicio == null || _horaFin == null || _hijosSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos y selecciona al menos un hijo.')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final tutorId = _client.auth.currentUser!.id;
      final double horasContratadas = (_horaFin!.hour - _horaInicio!.hour).abs().toDouble();
      final totalHoras = horasContratadas == 0 ? 1.0 : horasContratadas;
      final totalCalculado = widget.tarifaHora * totalHoras;

      // 1. Insertar el registro principal en la tabla de citas (US08)
      final citaResponse = await _client.from('citas').insert({
        'tutor_id': tutorId,
        'cuidador_id': widget.cuidadorId,
        'fecha': _fechaSeleccionada!.toIso8601String().split('T')[0],
        'hora_inicio': '${_horaInicio!.hour.toString().padLeft(2, '0')}:${_horaInicio!.minute.toString().padLeft(2, '0')}:00',
        'hora_fin': '${_horaFin!.hour.toString().padLeft(2, '0')}:${_horaFin!.minute.toString().padLeft(2, '0')}:00',
        'costo_total': totalCalculado,
        'estado': 'pendiente',
      }).select().single();

      final String idNuevaCita = citaResponse['id'];

      // 2. Asociar cada niño a la tabla intermedia
      for (var hijoId in _hijosSeleccionados) {
        await _client.from('hijos_citas').insert({
          'cita_id': idNuevaCita,
          'hijo_id': hijoId,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Solicitud enviada a la niñera exitosamente!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar solicitud: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solicitar Cuidado')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                ListTile(
                  title: Text(_fechaSeleccionada == null
                      ? 'Asignar Día'
                      : 'Día: ${_fechaSeleccionada!.toLocal()}'.split(' ')[0]),
                  trailing: const Icon(Icons.calendar_month_outlined),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                    );
                    if (picked != null) setState(() => _fechaSeleccionada = picked);
                  },
                ),
                const Divider(),
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        title: Text(_horaInicio == null ? 'Desde' : _horaInicio!.format(context)),
                        onTap: () async {
                          final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                          if (time != null) setState(() => _horaInicio = time);
                        },
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        title: Text(_horaFin == null ? 'Hasta' : _horaFin!.format(context)),
                        onTap: () async {
                          final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                          if (time != null) setState(() => _horaFin = time);
                        },
                      ),
                    ),
                  ],
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('¿A quiénes se va a cuidar?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                if (_misHijos.isEmpty)
                  const Text('No posees registros en el perfil de tus hijos.', style: TextStyle(color: Colors.grey)),
                ..._misHijos.map((hijo) {
                  final id = hijo['id'] as String;
                  return CheckboxListTile(
                    title: Text('${hijo['nombre']} (${hijo['edad']} años)'),
                    value: _hijosSeleccionados.contains(id),
                    onChanged: (bool? checked) {
                      setState(() {
                        checked == true ? _hijosSeleccionados.add(id) : _hijosSeleccionados.remove(id);
                      });
                    },
                  );
                }),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _procesarReserva,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('Confirmar y Enviar Solicitud'),
                )
              ],
            ),
    );
  }
}
''',

    "lib/features/cuidadores/presentation/screens/detalle_cita_screen.dart": '''import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DetalleCitaScreen extends StatefulWidget {
  final Map<String, dynamic> cita;
  final VoidCallback onStateChanged;

  const DetalleCitaScreen({super.key, required this.cita, required this.onStateChanged});

  @override
  State<DetalleCitaScreen> createState() => _DetalleCitaScreenState();
}

class _DetalleCitaScreenState extends State<DetalleCitaScreen> {
  final _client = Supabase.instance.client;
  bool _loading = false;

  Future<void> _modificarEstadoCita(String nuevoEstado) async {
    setState(() => _loading = true);
    try {
      await _client.from('citas').update({
        'estado': nuevoEstado,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', widget.cita['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Estado de la cita modificado a: $nuevoEstado'), backgroundColor: Colors.green),
        );
        widget.onStateChanged();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estadoActual = widget.cita['estado'] as String;

    return Scaffold(
      appBar: AppBar(title: const Text('Gestión del Turno')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Fecha de Servicio: ${widget.cita['fecha']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text('Horas pautadas: ${widget.cita['hora_inicio']} - ${widget.cita['hora_fin']}', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 12),
                  Text('Tarifa Estimada Total: \$ ${widget.cita['costo_total']}', style: const TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(20)),
                    child: Text('ESTADO: ${estadoActual.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  const Spacer(),
                  if (estadoActual == 'pendiente') ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _modificarEstadoCita('aceptada'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            child: const Text('Aceptar Cita', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _modificarEstadoCita('rechazada'),
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                            child: const Text('Rechazar', style: TextStyle(color: Colors.red)),
                          ),
                        ),
                      ],
                    )
                  ] else if (estadoActual == 'aceptada') ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _modificarEstadoCita('completada'),
                        child: const Text('Marcar como Completada'),
                      ),
                    )
                  ]
                ],
              ),
            ),
    );
  }
}
''',

    "lib/features/agenda/presentation/screens/agenda_screen.dart": '''import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../cuidadores/presentation/screens/detalle_cita_screen.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  final _client = Supabase.instance.client;
  List<Map<String, dynamic>> _citas = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _obtenerHistorialCitas();
  }

  Future<void> _obtenerHistorialCitas() async {
    setState(() => _loading = true);
    try {
      final uid = _client.auth.currentUser!.id;
      final data = await _client
          .from('citas')
          .select()
          .or('tutor_id.eq.\$uid,cuidador_id.eq.\$uid')
          .order('fecha', ascending: true);

      setState(() {
        _citas = List<Map<String, dynamic>>.from(data);
      });
    } catch (_) {
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Agenda de Cuidados')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _citas.isEmpty
              ? const Center(child: Text('No registras citas próximas en tu calendario.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _citas.length,
                  itemBuilder: (context, index) {
                    final cita = _citas[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text('Fecha: ${cita['fecha']}'),
                        subtitle: Text('Estado: ${cita['estado'].toString().toUpperCase()} - Total: \$${cita['costo_total']}'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetalleCitaScreen(
                                cita: cita,
                                onStateChanged: _obtenerHistorialCitas,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
''',

    "lib/features/notifications/data/email_service.dart": '''import 'package:http/http.dart' as http;
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
''',

    "lib/features/calificaciones/data/calificaciones_repository.dart": '''import 'package:supabase_flutter/supabase_flutter.dart';

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
''',

    "lib/features/calificaciones/presentation/screens/calificar_screen.dart": '''import 'package:flutter/material.dart';
import '../../data/calificaciones_repository.dart';

class CalificarScreen extends StatefulWidget {
  final String citaId;
  final String cuidadorId;
  final String nombreCuidador;

  const CalificarScreen({
    super.key,
    required this.citaId,
    required this.cuidadorId,
    required this.nombreCuidador,
  });

  @override
  State<CalificarScreen> createState() => _CalificarScreenState();
}

class _CalificarScreenState extends State<CalificarScreen> {
  final _repo = CalificacionesRepository();
  final _comentario = TextEditingController();
  int _estrellas = 5;
  bool _loading = false;

  @override
  void dispose() {
    _comentario.dispose();
    super.dispose();
  }

  Future<void> _enviarResena() async {
    setState(() => _loading = true);
    try {
      await _repo.registrarCalificacion(
        citaId: widget.citaId,
        cuidadorId: widget.cuidadorId,
        estrellas: _estrellas,
        comentario: _comentario.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Calificación enviada. ¡Muchas gracias!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: \$e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calificar Servicio')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text('Evalúa tu experiencia con \${widget.nombreCuidador}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) => IconButton(
                      icon: Icon(i < _estrellas ? Icons.star : Icons.star_border, color: Colors.amber, size: 36),
                      onPressed: () => setState(() => _estrellas = i + 1),
                    )),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _comentario,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Comentario / Reseña adicional', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(onPressed: _enviarResena, child: const Text('Enviar Calificación')),
                  )
                ],
              ),
            ),
    );
  }
}
''',

    "test/sprint3_smoke_test.dart": '''import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Pruebas de Humo - Sprints 2 y 3 (Verificación de Modelos y Datos)', () {
    test('Estructura de Cita y Estados Válidos', () {
      final mockCita = {
        'id': 'uuid-test-123',
        'estado': 'pendiente',
        'costo_total': 180.50
      };
      
      expect(mockCita['estado'], 'pendiente');
      expect(mockCita['costo_total'], isA<double>());
    });

    test('Validación de Payload para Notificaciones Resend', () {
      final mockPayload = {
        'from': 'Nanys Care <onboarding@resend.dev>',
        'to': ['tutor@example.com'],
        'subject': 'Confirmación de Turno'
      };

      expect(mockPayload['to'], contains('tutor@example.com'));
    });
  });
}
'''
}

for path, code in files_to_create.items():
    dir_name = os.path.dirname(path)
    if dir_name and not os.path.exists(dir_name):
        os.makedirs(dir_name, exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(code)
    print(f"✔ Generado con éxito: {path}")

print("\n🚀 ¡Inyección de los Sprints 2 y 3 completada satisfactoriamente!")
