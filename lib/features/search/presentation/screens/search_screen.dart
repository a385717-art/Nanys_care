// lib/features/search/presentation/screens/search_screen.dart
// US06 - Busqueda con filtros | US07 - Solicitudes por zona
 
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../citas/data/citas_repository.dart';
 
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}
 
class _SearchScreenState extends State<SearchScreen> {
  final _repo     = CitasRepository();
  final _zonaCtrl = TextEditingController();
  double _tarifaMax = 200;
  int _expMin = 0;
  List<Map<String, dynamic>> _resultados = [];
  bool _loading = false;
  bool _searched = false;
 
  @override
  void initState() { super.initState(); _buscar(); }
 
  @override
  void dispose() { _zonaCtrl.dispose(); super.dispose(); }
 
  Future<void> _buscar() async {
    setState(() { _loading = true; _searched = true; });
    try {
      final res = await _repo.buscarCuidadores(
        zona: _zonaCtrl.text.trim().isEmpty ? null : _zonaCtrl.text.trim(),
        tarifaMax: _tarifaMax >= 200 ? null : _tarifaMax,
        experienciaMin: _expMin == 0 ? null : _expMin,
      );
      setState(() => _resultados = res);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
 
  void _showFiltros() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(builder: (ctx, setModal) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('Filtros', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const Spacer(),
            TextButton(onPressed: () => setModal(() { _zonaCtrl.clear(); _tarifaMax = 200; _expMin = 0; }),
                child: const Text('Limpiar')),
          ]),
          const SizedBox(height: 16),
          TextField(controller: _zonaCtrl,
            decoration: const InputDecoration(labelText: 'Zona / Colonia', prefixIcon: Icon(Icons.location_on_outlined))),
          const SizedBox(height: 20),
          Row(children: [
            const Text('Tarifa maxima:', style: TextStyle(fontWeight: FontWeight.w500)), const Spacer(),
            Text(_tarifaMax >= 200 ? 'Sin limite' : '\$${_tarifaMax.toInt()}/hr',
                style: const TextStyle(color: Color(0xFF6B4EFF), fontWeight: FontWeight.w600)),
          ]),
          Slider(value: _tarifaMax, min: 50, max: 200, divisions: 15,
            activeColor: const Color(0xFF6B4EFF), onChanged: (v) => setModal(() => _tarifaMax = v)),
          const SizedBox(height: 8),
          Row(children: [
            const Text('Experiencia minima:', style: TextStyle(fontWeight: FontWeight.w500)), const Spacer(),
            Text(_expMin == 0 ? 'Cualquiera' : '$_expMin+ anos',
                style: const TextStyle(color: Color(0xFF6B4EFF), fontWeight: FontWeight.w600)),
          ]),
          Slider(value: _expMin.toDouble(), min: 0, max: 10, divisions: 10,
            activeColor: const Color(0xFF6B4EFF), onChanged: (v) => setModal(() => _expMin = v.toInt())),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () { Navigator.pop(context); _buscar(); }, child: const Text('Aplicar filtros')),
          const SizedBox(height: 8),
        ]),
      )),
    );
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buscar cuidadoras'),
        actions: [IconButton(icon: const Icon(Icons.tune), onPressed: _showFiltros)]),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: _zonaCtrl,
            decoration: InputDecoration(
              hintText: 'Buscar por zona o colonia...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(icon: const Icon(Icons.arrow_forward), onPressed: _buscar)),
            onSubmitted: (_) => _buscar()),
        ),
        const SizedBox(height: 12),
        if (_expMin > 0 || _tarifaMax < 200)
          SizedBox(height: 36, child: ListView(
            scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              if (_tarifaMax < 200) _FilterChip(label: 'Max \$${_tarifaMax.toInt()}/hr',
                  onRemove: () { setState(() => _tarifaMax = 200); _buscar(); }),
              if (_expMin > 0) _FilterChip(label: '$_expMin+ anos exp.',
                  onRemove: () { setState(() => _expMin = 0); _buscar(); }),
            ],
          )),
        const SizedBox(height: 8),
        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _resultados.isEmpty && _searched
                ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.search_off, size: 56, color: Colors.grey), SizedBox(height: 16),
                    Text('No se encontraron cuidadoras', style: TextStyle(color: Colors.grey)),
                  ]))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _resultados.length,
                    itemBuilder: (_, i) => _CuidadorCard(
                      cuidador: _resultados[i],
                      onTap: () => context.push(AppRoutes.cuidadorDetail, extra: _resultados[i])))),
      ]),
    );
  }
}
 
class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.onRemove});
  final String label; final VoidCallback onRemove;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(right: 8),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: const Color(0xFFEDEAFF), borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B4EFF))),
      const SizedBox(width: 4),
      GestureDetector(onTap: onRemove, child: const Icon(Icons.close, size: 14, color: Color(0xFF6B4EFF))),
    ]));
}
 
class _CuidadorCard extends StatelessWidget {
  const _CuidadorCard({required this.cuidador, required this.onTap});
  final Map<String, dynamic> cuidador; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final nombre    = cuidador['nombre'] ?? 'Sin nombre';
    final zona      = cuidador['zona'] ?? '';
    final tarifa    = cuidador['tarifa_hora'];
    final exp       = cuidador['experiencia_anios'] ?? 0;
    final cal       = cuidador['calificacion_promedio'] ?? 0;
    final avatarUrl = cuidador['avatar_url'] as String?;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEDEAFF)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Row(children: [
          CircleAvatar(radius: 30, backgroundColor: const Color(0xFFEDEAFF),
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null ? const Icon(Icons.person, color: Color(0xFF6B4EFF), size: 30) : null),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(nombre, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Row(children: [const Icon(Icons.location_on, size: 13, color: Colors.grey), const SizedBox(width: 2),
              Text(zona, style: const TextStyle(fontSize: 12, color: Colors.grey))]),
            const SizedBox(height: 6),
            Row(children: [
              _Badge(icon: Icons.work, text: '$exp anos'),
              const SizedBox(width: 8),
              _Badge(icon: Icons.star, text: '$cal', color: Colors.amber),
            ]),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('\$${tarifa?.toStringAsFixed(0) ?? "--"}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF6B4EFF))),
            const Text('/hr', style: TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 8),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ]),
        ]),
      ),
    );
  }
}
 
class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.text, this.color});
  final IconData icon; final String text; final Color? color;
  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFF6B4EFF);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: c), const SizedBox(width: 3),
        Text(text, style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.w600)),
      ]));
  }
}
