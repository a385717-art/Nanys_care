 // lib/features/citas/presentation/screens/citas_cuidador_screen.dart

// US09 - Aceptar o rechazar citas

 

import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import '../../data/citas_repository.dart';

 

class CitasCuidadorScreen extends StatefulWidget {

  const CitasCuidadorScreen({super.key});

  @override

  State<CitasCuidadorScreen> createState() => _CitasCuidadorScreenState();

}

 

class _CitasCuidadorScreenState extends State<CitasCuidadorScreen> with SingleTickerProviderStateMixin {

  final _repo = CitasRepository();

  late TabController _tabs;

  List<Map<String, dynamic>> _citas = [];

  bool _loading = true;

 

  @override

  void initState() { super.initState(); _tabs = TabController(length: 3, vsync: this); _load(); }

 

  @override

  void dispose() { _tabs.dispose(); super.dispose(); }

 

  Future<void> _load() async {

    setState(() => _loading = true);

    try {

      final data = await _repo.getCitasCuidador();

      setState(() => _citas = data);

    } catch (e) {

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));

    } finally {

      if (mounted) setState(() => _loading = false);

    }

  }

 

  List<Map<String, dynamic>> _filter(String estado) =>

      _citas.where((c) => c['estado'] == estado).toList();

 

  Future<void> _aceptar(String id) async {

    try {

      await _repo.aceptarCita(id); await _load();

      if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(

          const SnackBar(content: Text('Cita aceptada'), backgroundColor: Colors.green));

      }

    } catch (e) {

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));

    }

  }

 

  Future<void> _rechazar(String id) async {

    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(

      title: const Text('Rechazar cita'),

      content: const Text('Segura de rechazar esta solicitud?'),

      actions: [

        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),

        ElevatedButton(onPressed: () => Navigator.pop(context, true),

            style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Rechazar')),

      ],

    ));

    if (ok != true) return;

    try { await _repo.rechazarCita(id); await _load(); }

    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }

  }

 

  @override

  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(title: const Text('Mis solicitudes'), bottom: TabBar(controller: _tabs, tabs: [

        Tab(text: 'Pendientes (${_filter("pendiente").length})'),

        const Tab(text: 'Aceptadas'), const Tab(text: 'Historial'),

      ])),

      body: _loading ? const Center(child: CircularProgressIndicator())

          : RefreshIndicator(onRefresh: _load, child: TabBarView(controller: _tabs, children: [

            _Lista(citas: _filter('pendiente'), emptyMsg: 'No tienes solicitudes pendientes',

                showActions: true, onAceptar: _aceptar, onRechazar: _rechazar),

            _Lista(citas: _filter('aceptada'), emptyMsg: 'No tienes citas aceptadas', showActions: false),

            _Lista(citas: [..._filter('rechazada'), ..._filter('cancelada')],

                emptyMsg: 'Sin historial', showActions: false),

          ])),

    );

  }

}

 

class _Lista extends StatelessWidget {

  const _Lista({required this.citas, required this.emptyMsg, required this.showActions,

      this.onAceptar, this.onRechazar});

  final List<Map<String, dynamic>> citas; final String emptyMsg; final bool showActions;

  final Future<void> Function(String)? onAceptar; final Future<void> Function(String)? onRechazar;

  @override

  Widget build(BuildContext context) {

    if (citas.isEmpty) {

      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [

      const Icon(Icons.event_available, size: 56, color: Colors.grey), const SizedBox(height: 16),

      Text(emptyMsg, style: const TextStyle(color: Colors.grey)),

    ]));

    }

    return ListView.builder(

      padding: const EdgeInsets.all(16), itemCount: citas.length,

      itemBuilder: (_, i) => _Card(cita: citas[i], showActions: showActions,

          onAceptar: onAceptar, onRechazar: onRechazar));

  }

}

 

class _Card extends StatelessWidget {

  const _Card({required this.cita, required this.showActions, this.onAceptar, this.onRechazar});

  final Map<String, dynamic> cita; final bool showActions;

  final Future<void> Function(String)? onAceptar; final Future<void> Function(String)? onRechazar;

 

  Color get _color { switch (cita['estado']) { case 'aceptada': return Colors.green;

    case 'rechazada': return Colors.red; case 'cancelada': return Colors.grey; default: return Colors.orange; } }

  String get _label { switch (cita['estado']) { case 'aceptada': return 'Aceptada';

    case 'rechazada': return 'Rechazada'; case 'cancelada': return 'Cancelada'; default: return 'Pendiente'; } }

 

  @override

  Widget build(BuildContext context) {

    final tutor  = cita['tutor'] as Map<String, dynamic>?;

    final nombre = tutor?['nombre'] ?? 'Tutor';

    final fecha  = cita['fecha'] as String? ?? '';

    final hI     = (cita['hora_inicio'] as String? ?? '').substring(0, 5);

    final hF     = (cita['hora_fin']    as String? ?? '').substring(0, 5);

    final tarifa = cita['tarifa_total'];

    final notas  = cita['notas'] as String?;

    final id     = cita['id'] as String;

    String fechaFmt = fecha;

    try { fechaFmt = DateFormat('EEE d MMM yyyy').format(DateTime.parse(fecha)); } catch (_) {}

 

    return Container(

      margin: const EdgeInsets.only(bottom: 14),

      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),

        border: Border.all(color: const Color(0xFFEDEAFF)),

        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),

      child: Column(children: [

        Container(

          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

          decoration: BoxDecoration(color: _color.withOpacity(0.07),

              borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),

          child: Row(children: [

            CircleAvatar(radius: 18, backgroundColor: _color.withOpacity(0.15),

                child: Icon(Icons.person, color: _color, size: 18)),

            const SizedBox(width: 10),

            Expanded(child: Text(nombre, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),

            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),

              decoration: BoxDecoration(color: _color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),

              child: Text(_label, style: TextStyle(fontSize: 11, color: _color, fontWeight: FontWeight.w600))),

          ]),

        ),

        Padding(padding: const EdgeInsets.all(16), child: Column(children: [

          Row(children: [

            const Icon(Icons.calendar_today, size: 15, color: Colors.grey), const SizedBox(width: 6),

            Text(fechaFmt, style: const TextStyle(fontSize: 13)), const Spacer(),

            const Icon(Icons.access_time, size: 15, color: Colors.grey), const SizedBox(width: 6),

            Text('$hI - $hF', style: const TextStyle(fontSize: 13)),

          ]),

          if (tarifa != null) ...[const SizedBox(height: 8), Row(children: [

            const Icon(Icons.attach_money, size: 15, color: Colors.grey), const SizedBox(width: 6),

            Text('\$${(tarifa as num).toStringAsFixed(2)} MXN',

                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.green)),

          ])],

          if (notas != null && notas.isNotEmpty) ...[const SizedBox(height: 8), Row(children: [

            const Icon(Icons.notes, size: 15, color: Colors.grey), const SizedBox(width: 6),

            Expanded(child: Text(notas, style: const TextStyle(fontSize: 12, color: Colors.grey))),

          ])],

          if (showActions) ...[const SizedBox(height: 14), Row(children: [

            Expanded(child: OutlinedButton(onPressed: () => onRechazar?.call(id),

                style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red),

                    minimumSize: const Size(0, 42)), child: const Text('Rechazar'))),

            const SizedBox(width: 12),

            Expanded(child: ElevatedButton(onPressed: () => onAceptar?.call(id),

                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(0, 42)),

                child: const Text('Aceptar'))),

          ])],

        ])),

      ]),

    );

  }

} 