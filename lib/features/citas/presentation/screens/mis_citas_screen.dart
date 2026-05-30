import 'package:flutter/material.dart';
import '../../data/citas_repository.dart';
import '../widgets/calificar_modal.dart';

class MisCitasScreen extends StatefulWidget {
  const MisCitasScreen({super.key});

  @override
  State<MisCitasScreen> createState() => _MisCitasScreenState();
}

class _MisCitasScreenState extends State<MisCitasScreen> {
  final _citasRepo = CitasRepository();
  
  // Almacena los futures para evitar llamadas repetidas innecesarias en el ciclo de vida
  late Future<String?> _rolFuture;
  late Future<List<Map<String, dynamic>>> _citasFuture;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  void _cargarDatos() {
    setState(() {
      _rolFuture = _citasRepo.getUserRole();
      _citasFuture = _rolFuture.then((rol) {
        if (rol == 'cuidador') {
          return _citasRepo.getCitasCuidador();
        } else {
          return _citasRepo.getCitasTutor();
        }
      });
    });
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Colors.orange;
      case 'aceptada':
        return Colors.blue;
      case 'completada':
        return Colors.green;
      case 'rechazada':
      case 'cancelada':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Citas', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatos,
          ),
        ],
      ),
      body: FutureBuilder<String?>(
        future: _rolFuture,
        builder: (context, rolSnapshot) {
          if (rolSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final rol = rolSnapshot.data ?? 'tutor';

          return FutureBuilder<List<Map<String, dynamic>>>(
            future: _citasFuture,
            builder: (context, citasSnapshot) {
              if (citasSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (citasSnapshot.hasError) {
                return Center(
                  child: Text('Error al cargar las citas: ${citasSnapshot.error}'),
                );
              }

              final citas = citasSnapshot.data ?? [];

              if (citas.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No tienes ninguna cita agendada.',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: citas.length,
                itemBuilder: (context, index) {
                  final cita = citas[index];
                  
                  // Extraemos los datos dependiendo del rol
                  final esCuidador = rol == 'cuidador';
                  final otroUsuario = esCuidador ? cita['tutor'] : cita['cuidador'];
                  final nombreDisplay = otroUsuario?['nombre'] ?? (esCuidador ? 'Tutor' : 'Cuidadora');
                  final avatarUrl = otroUsuario?['avatar_url'];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.grey[200],
                                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                                child: avatarUrl == null ? const Icon(Icons.person, color: Colors.grey) : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      nombreDisplay,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      esCuidador ? 'Cliente (Tutor)' : 'Servicio de Cuidado',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getEstadoColor(cita['estado']).withAlpha(30),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  cita['estado'].toUpperCase(),
                                  style: TextStyle(
                                    color: _getEstadoColor(cita['estado']),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            children: [
                              const Icon(Icons.calendar_month, size: 18, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text('Fecha: ${cita['fecha']}', style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.access_time_rounded, size: 18, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text('Horario: ${cita['hora_inicio']} - ${cita['hora_fin']}', style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.monetization_on_outlined, size: 18, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text('Total: \$${cita['tarifa_total']}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          if (cita['notas'] != null && cita['notas'].toString().trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Notas: ${cita['notas']}',
                              style: TextStyle(fontSize: 13, color: Colors.grey[700], fontStyle: FontStyle.italic),
                            ),
                          ],
                          
                          // ── LOGICA SPRINT 3: BOTÓN CALIFICAR (Solo para Tutores y Citas Completadas) ──
                          if (!esCuidador && cita['estado'] == 'completada') ...[
                            const Divider(height: 24),
                            FutureBuilder<bool>(
                              future: _citasRepo.existeCalificacion(cita['id']),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const SizedBox(
                                    height: 20, 
                                    child: Center(child: LinearProgressIndicator())
                                  );
                                }
                                
                                final yaCalificado = snapshot.data ?? false;

                                if (yaCalificado) {
                                  return const Align(
                                    alignment: Alignment.centerRight,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.stars_rounded, color: Colors.green, size: 18),
                                        SizedBox(width: 4),
                                        Text(
                                          'Servicio calificado',
                                          style: TextStyle(color: Colors.green, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                return SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.star_outline_rounded),
                                    label: const Text('Calificar Servicio'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.amber[700],
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                        ),
                                        builder: (context) => CalificarModal(
                                          cita: cita,
                                          onCalificado: () {
                                            // Vuelve a consultar Supabase para refrescar la vista
                                            _cargarDatos();
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}