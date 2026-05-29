// lib/features/citas/presentation/screens/agenda_screen.dart
// US12 - Consultar agenda
 
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/citas_repository.dart';
 
class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});
  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}
 
class _AgendaScreenState extends State<AgendaScreen> {
  final _repo = CitasRepository();
  List<Map<String, dynamic>> _citas = [];
  bool _loading = true;
  String? _role;
 
  @override
  void initState() { super.initState(); _init(); }
 
  Future<void> _init() async {
    setState(() => _loading = true);
    try {
      _role = await _repo.getUserRole();
      _citas = _role == 'tutor' ? await _repo.getCitasTutor() : await _repo.getCitasCuidador();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
 
  List<Map<String, dynamic>> get _proximas {
    final hoy = DateTime.now();
    return _citas.where((c) {
      try {
        final f = DateTime.parse(c['fecha'] as String);
        return (c['estado'] == 'aceptada' || c['estado'] == 'pendiente') &&
               !f.isBefore(DateTime(hoy.year, hoy.month, hoy.day));
      } catch (_) { return false; }
    }).toList();
  }
 
  List<Map<String, dynamic>> get _pasadas => _citas.where((c) {
    try {
      final f = DateTime.parse(c['fecha'] as String);
      return f.isBefore(DateTime.now()) || c['estado'] == 'cancelada' || c['estado'] == 'rechazada';
    } catch (_) { return false; }
  }).toList();
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi agenda'),
          actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _init)]),
      body: _loading ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(onRefresh: _init, child: _citas.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.calendar_today, size: 64, color: Colors.grey), const SizedBox(height: 16),
                  const Text('No tienes citas aun', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text(_role == 'tutor' ? 'Busca una cuidadora y agenda.' : 'Las solicitudes apareceran aqui.',
                      textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ]))
              : ListView(padding: const EdgeInsets.all(16), children: [
                  if (_proximas.isNotEmpty) ...[
                    _Header(icon: Icons.upcoming, title: 'Proximas (${_proximas.length})', color: const Color(0xFF6B4EFF)),
                    const SizedBox(height: 10),
                    ..._proximas.map((c) => _AgendaCard(cita: c, role: _role ?? 'tutor')),
                    const SizedBox(height: 20),
                  ],
                  if (_pasadas.isNotEmpty) ...[
                    const _Header(icon: Icons.history, title: 'Historial', color: Colors.grey),
                    const SizedBox(height: 10),
                    ..._pasadas.map((c) => _AgendaCard(cita: c, role: _role ?? 'tutor')),
                  ],
                ])),
    );
  }
}
 
class _Header extends StatelessWidget {
  const _Header({required this.icon, required this.title, required this.color});
  final IconData icon; final String title; final Color color;
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 18, color: color), const SizedBox(width: 8),
    Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
  ]);
}
 
class _AgendaCard extends StatelessWidget {
  const _AgendaCard({required this.cita, required this.role});
  final Map<String, dynamic> cita; final String role;
  Color get _color { switch (cita['estado']) { case 'aceptada': return Colors.green;
    case 'rechazada': return Colors.red; case 'cancelada': return Colors.grey; default: return Colors.orange; } }
  String get _label { switch (cita['estado']) { case 'aceptada': return 'Confirmada';
    case 'rechazada': return 'Rechazada'; case 'cancelada': return 'Cancelada'; default: return 'Pendiente'; } }
  @override
  Widget build(BuildContext context) {
    final otra       = role == 'tutor' ? cita['cuidador'] as Map<String, dynamic>? : cita['tutor'] as Map<String, dynamic>?;
    final otraNombre = otra?['nombre'] ?? (role == 'tutor' ? 'Cuidadora' : 'Tutor');
    final otraAvatar = otra?['avatar_url'] as String?;
    final fecha      = cita['fecha'] as String? ?? '';
    final hI         = (cita['hora_inicio'] as String? ?? '').substring(0, 5);
    final hF         = (cita['hora_fin']    as String? ?? '').substring(0, 5);
    final tarifa     = cita['tarifa_total'];
    String fechaFmt = fecha;
    try { fechaFmt = DateFormat('EEE d MMM').format(DateTime.parse(fecha)); } catch (_) {}
 
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDEAFF)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))]),
      child: IntrinsicHeight(child: Row(children: [
        Container(width: 5, decoration: BoxDecoration(color: _color,
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)))),
        Expanded(child: Padding(padding: const EdgeInsets.all(14), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(radius: 16, backgroundColor: _color.withOpacity(0.12),
                backgroundImage: otraAvatar != null ? NetworkImage(otraAvatar) : null,
                child: otraAvatar == null ? Icon(Icons.person, size: 16, color: _color) : null),
              const SizedBox(width: 8),
              Expanded(child: Text(otraNombre, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
              Text(_label, style: TextStyle(fontSize: 11, color: _color, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.calendar_today, size: 13, color: Colors.grey), const SizedBox(width: 5),
              Text(fechaFmt, style: const TextStyle(fontSize: 12, color: Colors.grey)), const Spacer(),
              const Icon(Icons.access_time, size: 13, color: Colors.grey), const SizedBox(width: 5),
              Text('$hI - $hF', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              if (tarifa != null) ...[const Spacer(),
                const Icon(Icons.attach_money, size: 13, color: Colors.green),
                Text('\$${(tarifa as num).toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green))],
            ]),
          ]),
        )),
      ])),
    );
  }
}
