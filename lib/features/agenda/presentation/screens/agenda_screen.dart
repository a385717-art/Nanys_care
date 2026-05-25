import 'package:flutter/material.dart';
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
