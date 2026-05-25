import 'package:flutter/material.dart';
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
