// lib/features/search/presentation/screens/cuidador_detail_screen.dart
 
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
 
class CuidadorDetailScreen extends StatelessWidget {
  const CuidadorDetailScreen({super.key, required this.cuidador});
  final Map<String, dynamic> cuidador;
 
  @override
  Widget build(BuildContext context) {
    final scheme      = Theme.of(context).colorScheme;
    final nombre      = cuidador['nombre'] ?? 'Sin nombre';
    final zona        = cuidador['zona'] ?? '';
    final tarifa      = cuidador['tarifa_hora'];
    final exp         = cuidador['experiencia_anios'] ?? 0;
    final cal         = cuidador['calificacion_promedio'] ?? 0;
    final totalCal    = cuidador['total_calificaciones'] ?? 0;
    final descripcion = cuidador['descripcion'] ?? '';
    final avatarUrl   = cuidador['avatar_url'] as String?;
 
    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 240, pinned: true, backgroundColor: scheme.primary,
          leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => context.pop()),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(gradient: LinearGradient(
                colors: [scheme.primary, scheme.primary.withOpacity(0.7)],
                begin: Alignment.topLeft, end: Alignment.bottomRight)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const SizedBox(height: 48),
                CircleAvatar(radius: 48, backgroundColor: Colors.white.withOpacity(0.2),
                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null ? const Icon(Icons.person, size: 48, color: Colors.white) : null),
                const SizedBox(height: 12),
                Text(nombre, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.white70), const SizedBox(width: 4),
                  Text(zona, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ]),
              ]),
            ),
          ),
        ),
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _StatCard(icon: Icons.attach_money, label: 'Tarifa/hr',
                  value: '\$${tarifa?.toStringAsFixed(0) ?? "--"}', color: scheme.primary),
              const SizedBox(width: 12),
              _StatCard(icon: Icons.work, label: 'Experiencia',
                  value: '$exp anos', color: const Color(0xFF00BFA5)),
              const SizedBox(width: 12),
              _StatCard(icon: Icons.star, label: '$totalCal resenas',
                  value: '$cal', color: Colors.amber),
            ]),
            const SizedBox(height: 24),
            const Text('Sobre mi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(descripcion.isEmpty ? 'Sin descripcion disponible.' : descripcion,
                style: const TextStyle(color: Colors.black87, height: 1.5)),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.push(AppRoutes.agendarCita, extra: cuidador),
              icon: const Icon(Icons.calendar_month), label: const Text('Agendar cita'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 52))),
            const SizedBox(height: 32),
          ]),
        )),
      ]),
    );
  }
}
 
class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.label, required this.value, required this.color});
  final IconData icon; final String label, value; final Color color;
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2))),
    child: Column(children: [
      Icon(icon, color: color, size: 22), const SizedBox(height: 6),
      Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
    ])));
}
