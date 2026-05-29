// lib/features/citas/presentation/screens/booking_screen.dart
// US08 - Agendar citas
 
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/router/app_router.dart';
import '../../data/citas_repository.dart';
 
class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key, required this.cuidador});
  final Map<String, dynamic> cuidador;
  @override
  State<BookingScreen> createState() => _BookingScreenState();
}
 
class _BookingScreenState extends State<BookingScreen> {
  final _repo      = CitasRepository();
  final _notasCtrl = TextEditingController();
  DateTime? _fecha;
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFin;
  bool _loading = false;
 
  @override
  void dispose() { _notasCtrl.dispose(); super.dispose(); }
 
  double get _tarifaTotal {
    if (_horaInicio == null || _horaFin == null) return 0;
    final tarifa = (widget.cuidador['tarifa_hora'] as num?)?.toDouble() ?? 0;
    final horas = (_horaFin!.hour + _horaFin!.minute / 60) - (_horaInicio!.hour + _horaInicio!.minute / 60);
    return horas > 0 ? tarifa * horas : 0;
  }
 
  String _timeStr(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, "0")}:${t.minute.toString().padLeft(2, "0")}:00';
 
  Future<void> _pickFecha() async {
    final p = await showDatePicker(context: context,
        initialDate: DateTime.now().add(const Duration(days: 1)),
        firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 60)));
    if (p != null) setState(() => _fecha = p);
  }
 
  Future<void> _pickHora(bool isInicio) async {
    final p = await showTimePicker(context: context,
        initialTime: isInicio ? const TimeOfDay(hour: 8, minute: 0) : const TimeOfDay(hour: 10, minute: 0));
    if (p != null) setState(() { if (isInicio) {
      _horaInicio = p;
    } else {
      _horaFin = p;
    } });
  }
 
  bool get _formValido => _fecha != null && _horaInicio != null && _horaFin != null && _tarifaTotal > 0;
 
  Future<void> _confirmar() async {
    if (!_formValido) return;
    setState(() => _loading = true);
    try {
      await _repo.crearCita(
        cuidadorId: widget.cuidador['id'] as String, fecha: _fecha!,
        horaInicio: _timeStr(_horaInicio!), horaFin: _timeStr(_horaFin!),
        tarifaTotal: _tarifaTotal,
        notas: _notasCtrl.text.trim().isEmpty ? null : _notasCtrl.text.trim());
      if (!mounted) return;
      showDialog(context: context, barrierDismissible: false, builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 64),
          const SizedBox(height: 16),
          const Text('Solicitud enviada!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Tu solicitud fue enviada a ${widget.cuidador["nombre"]}.',
              textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
        ]),
        actions: [ElevatedButton(onPressed: () { Navigator.pop(context); context.go(AppRoutes.home); },
            child: const Text('Ver mi agenda'))],
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
 
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Agendar cita')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: scheme.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14), border: Border.all(color: scheme.primary.withOpacity(0.2))),
            child: Row(children: [
              CircleAvatar(radius: 24, backgroundColor: scheme.primary.withOpacity(0.1),
                backgroundImage: widget.cuidador['avatar_url'] != null
                    ? NetworkImage(widget.cuidador['avatar_url'] as String) : null,
                child: widget.cuidador['avatar_url'] == null ? Icon(Icons.person, color: scheme.primary) : null),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.cuidador['nombre'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                Text('\$${widget.cuidador['tarifa_hora']?.toStringAsFixed(0) ?? "--"}/hr',
                    style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600)),
              ])),
            ]),
          ),
          const SizedBox(height: 24),
          const Text('Fecha', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF6B4EFF))),
          const SizedBox(height: 10),
          _Tile(icon: Icons.calendar_today,
            label: _fecha == null ? 'Selecciona una fecha'
                : DateFormat('EEEE d MMM yyyy').format(_fecha!),
            selected: _fecha != null, onTap: _pickFecha),
          const SizedBox(height: 20),
          const Text('Horario', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF6B4EFF))),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _Tile(icon: Icons.access_time,
              label: _horaInicio == null ? 'Inicio' : _horaInicio!.format(context),
              selected: _horaInicio != null, onTap: () => _pickHora(true))),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('--', style: TextStyle(fontSize: 18, color: Colors.grey))),
            Expanded(child: _Tile(icon: Icons.access_time_filled,
              label: _horaFin == null ? 'Fin' : _horaFin!.format(context),
              selected: _horaFin != null, onTap: () => _pickHora(false))),
          ]),
          if (_tarifaTotal > 0) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.withOpacity(0.3))),
              child: Row(children: [
                const Icon(Icons.receipt_long, color: Colors.green), const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Costo estimado', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Text('\$${_tarifaTotal.toStringAsFixed(2)} MXN',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.green)),
                ])),
              ]),
            ),
          ],
          const SizedBox(height: 20),
          const Text('Notas (opcional)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF6B4EFF))),
          const SizedBox(height: 10),
          TextField(controller: _notasCtrl, maxLines: 3,
              decoration: const InputDecoration(hintText: 'Alergias, codigo de puerta, indicaciones...')),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: (_formValido && !_loading) ? _confirmar : null,
            child: _loading ? const SizedBox(height: 20, width: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Confirmar solicitud')),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}
 
class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.label, required this.selected, required this.onTap});
  final IconData icon; final String label; final bool selected; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFEDEAFF) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: selected ? const Color(0xFF6B4EFF) : const Color(0xFFDDD8FF), width: selected ? 2 : 1)),
      child: Row(children: [
        Icon(icon, size: 18, color: selected ? const Color(0xFF6B4EFF) : Colors.grey),
        const SizedBox(width: 8),
        Flexible(child: Text(label, style: TextStyle(
          color: selected ? const Color(0xFF6B4EFF) : Colors.grey,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal, fontSize: 13))),
      ])));
}
