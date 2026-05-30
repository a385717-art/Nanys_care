import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nanys_care/features/citas/data/citas_repository.dart';

class DetalleCitaScreen extends StatefulWidget {
  final Map<String, dynamic> cita;
  final VoidCallback onStateChanged;

  const DetalleCitaScreen({super.key, required this.cita, required this.onStateChanged});

  @override
  State<DetalleCitaScreen> createState() => _DetalleCitaScreenState();
}

class _DetalleCitaScreenState extends State<DetalleCitaScreen> {
  final _citasRepo = CitasRepository(); 
  bool _loading = false;

  // Colores de la marca Nanys Care
  final Color _primaryColor = const Color(0xFF6B4EFF);
  final Color _primaryLight = const Color(0xFFEDEAFF);

  Future<void> _modificarEstadoCita(String nuevoEstado) async {
    setState(() => _loading = true);
    try {
      final citaId = widget.cita['id'];

      // Llamamos al Repositorio en lugar de Supabase directo
      // Esto asegura que los CORREOS de la US10 se envíen automáticamente
      if (nuevoEstado == 'aceptada') {
        await _citasRepo.aceptarCita(citaId);
      } else if (nuevoEstado == 'rechazada') {
        await _citasRepo.rechazarCita(citaId);
      } else if (nuevoEstado == 'completada') {
        await _citasRepo.completarCita(citaId);
      } else if (nuevoEstado == 'cancelada') {
        await _citasRepo.cancelarCita(citaId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Estado actualizado a: ${nuevoEstado.toUpperCase()}'), 
            backgroundColor: nuevoEstado == 'rechazada' ? Colors.red : Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onStateChanged();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Helper para el color del badge de estado
  Color _getStatusColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente': return Colors.orange;
      case 'aceptada': return _primaryColor;
      case 'completada': return const Color(0xFF00BFA5); // Verde Nanys Care
      case 'rechazada':
      case 'cancelada': return Colors.red;
      default: return Colors.grey;
    }
  }

  // Helper para formatear fecha si viene en formato ISO
  String _formatFecha(String fechaStr) {
    try {
      final date = DateTime.parse(fechaStr);
      return DateFormat('EEEE d MMM yyyy', 'es').format(date);
    } catch (e) {
      return fechaStr; // Si falla, devuelve el string original
    }
  }

  @override
  Widget build(BuildContext context) {
    final estadoActual = widget.cita['estado'] as String;
    final statusColor = _getStatusColor(estadoActual);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Fondo gris muy claro
      appBar: AppBar(
        title: const Text('Detalle de la Reserva', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: _primaryColor))
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tarjeta Principal de Información
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Badge de Estado
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Estado actual:', style: TextStyle(color: Colors.grey, fontSize: 14)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        estadoActual.toUpperCase(),
                                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Divider(height: 1, color: Color(0xFFEEEEEE)),
                                ),
                                // Lista de Detalles
                                _InfoRow(
                                  icon: Icons.calendar_today_rounded,
                                  title: 'Fecha del servicio',
                                  value: _formatFecha(widget.cita['fecha'].toString()),
                                  iconColor: _primaryColor,
                                ),
                                const SizedBox(height: 20),
                                _InfoRow(
                                  icon: Icons.access_time_filled_rounded,
                                  title: 'Horario pautado',
                                  value: '${widget.cita['hora_inicio']} a ${widget.cita['hora_fin']}',
                                  iconColor: Colors.blue,
                                ),
                                const SizedBox(height: 20),
                                _InfoRow(
                                  icon: Icons.monetization_on_rounded,
                                  title: 'Tarifa total estimada',
                                  value: '\$${widget.cita['tarifa_total'] ?? widget.cita['costo_total']} MXN',
                                  iconColor: const Color(0xFF00BFA5),
                                  isPrice: true,
                                ),
                              ],
                            ),
                          ),
                          
                          // Notas adicionales (Si existen)
                          if (widget.cita['notas'] != null && widget.cita['notas'].toString().trim().isNotEmpty) ...[
                            const SizedBox(height: 24),
                            const Text('Notas del Tutor', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _primaryLight.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: _primaryLight),
                              ),
                              child: Text(
                                widget.cita['notas'].toString(),
                                style: const TextStyle(color: Colors.black87, height: 1.5),
                              ),
                            ),
                          ]
                        ],
                      ),
                    ),
                  ),

                  // Área de Botones Fija al fondo
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (estadoActual == 'pendiente') ...[
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _modificarEstadoCita('rechazada'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      side: const BorderSide(color: Colors.red),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                    child: const Text('Rechazar', style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _modificarEstadoCita('aceptada'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _primaryColor,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      elevation: 0,
                                    ),
                                    child: const Text('Aceptar Cita', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            )
                          ] else if (estadoActual == 'aceptada') ...[
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _modificarEstadoCita('completada'),
                                icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                                label: const Text('Marcar como Completada', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00BFA5), // Verde Nanys Care
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  elevation: 0,
                                ),
                              ),
                            )
                          ] else ...[
                            // Si está completada, rechazada o cancelada, mostramos un botón para volver
                            SizedBox(
                              width: double.infinity,
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                child: const Text('Volver a la agenda', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              ),
                            )
                          ]
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// Widget auxiliar para las filas de información en la tarjeta
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color iconColor;
  final bool isPrice;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.iconColor,
    this.isPrice = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 4),
              Text(
                value, 
                style: TextStyle(
                  fontSize: isPrice ? 18 : 15, 
                  fontWeight: isPrice ? FontWeight.w800 : FontWeight.w600,
                  color: isPrice ? iconColor : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}