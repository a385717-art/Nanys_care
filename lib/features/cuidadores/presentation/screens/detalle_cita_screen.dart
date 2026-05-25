import 'package:flutter/material.dart';
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
