// lib/features/citas/presentation/screens/detalle_cita_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DetalleCitaScreen extends StatelessWidget {
  final Map<String, dynamic> cita;
  final VoidCallback onStateChanged;

  const DetalleCitaScreen({
    super.key,
    required this.cita,
    required this.onStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tutor = cita['tutor'] as Map<String, dynamic>?;
    final nombre = tutor?['nombre'] ?? 'Tutor';
    final fecha = cita['fecha'] as String? ?? '';
    final hI = (cita['hora_inicio'] as String? ?? '').substring(0, 5);
    final hF = (cita['hora_fin'] as String? ?? '').substring(0, 5);
    final tarifa = cita['tarifa_total'];
    final notas = cita['notas'] as String? ?? 'Sin notas adicionales.';
    final estado = cita['estado'] as String? ?? 'pendiente';

    String fechaFmt = fecha;
    try {
      fechaFmt = DateFormat('EEE d MMM yyyy').format(DateTime.parse(fecha));
    } catch (_) {}

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de la Solicitud')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Solicitante: $nombre', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('Fecha: $fechaFmt'),
            Text('Horario: $hI - $hF'),
            if (tarifa != null) Text('Tarifa: \$$tarifa MXN', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            const Divider(height: 30),
            const Text('Notas del Tutor:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(notas, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),
            Text('Estado actual: ${estado.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}