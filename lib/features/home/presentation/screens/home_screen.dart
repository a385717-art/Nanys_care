// lib/features/home/presentation/screens/home_screen.dart
 
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/router/app_router.dart';
 
import '../../../search/presentation/screens/search_screen.dart';
import '../../../citas/presentation/screens/agenda_screen.dart';
import '../../../citas/presentation/screens/citas_cuidador_screen.dart';
 
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
 
class _HomeScreenState extends State<HomeScreen> {
  final _client = Supabase.instance.client;
  int _tabIndex = 0;
  String? _role;
 
  @override
  void initState() { 
    super.initState(); 
    _loadRole(); 
  }
 
  Future<void> _loadRole() async {
    final data = await _client.from('profiles').select('role')
        .eq('id', _client.auth.currentUser!.id).maybeSingle();
    if (mounted) setState(() => _role = data?['role'] as String?);
  }
 
  String get _email => _client.auth.currentUser?.email ?? '';
 
  @override
  Widget build(BuildContext context) {
    final isCuidador = _role == 'cuidador';
    return Scaffold(
      body: IndexedStack(index: _tabIndex, children: [
        _HomeTab(email: _email, role: _role),
        const AgendaScreen(),
        isCuidador ? const CitasCuidadorScreen() : const SearchScreen(),
        const _PerfilTab(),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Inicio'),
          const NavigationDestination(icon: Icon(Icons.calendar_today_outlined), selectedIcon: Icon(Icons.calendar_today), label: 'Agenda'),
          NavigationDestination(
            icon: Icon(isCuidador ? Icons.assignment_outlined : Icons.search),
            selectedIcon: Icon(isCuidador ? Icons.assignment : Icons.search),
            label: isCuidador ? 'Solicitudes' : 'Buscar'),
          const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
 
class _HomeTab extends StatelessWidget {
  const _HomeTab({required this.email, this.role});
  final String email; 
  final String? role;
 
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isCuidador = role == 'cuidador';
    return SafeArea(child: CustomScrollView(slivers: [
      SliverAppBar(floating: true, backgroundColor: Colors.white,
        title: Row(children: [Icon(Icons.child_care, color: scheme.primary), const SizedBox(width: 8),
          const Text('Nanys Care', style: TextStyle(fontWeight: FontWeight.w700))]),
        actions: [IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {})]),
      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(20), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(isCuidador ? 'Hola, cuidadora!' : 'Hola, tutor!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(email, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          Container(width: double.infinity, padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isCuidador
                    ? [const Color(0xFFFF7BAC), const Color(0xFFFF7BAC).withOpacity(0.7)]
                    : [scheme.primary, scheme.primary.withOpacity(0.7)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              Icon(isCuidador ? Icons.favorite : Icons.family_restroom, color: Colors.white, size: 36),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(isCuidador ? 'Eres cuidadora' : 'Eres tutor',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 4),
                Text(isCuidador ? 'Revisa tus solicitudes y agenda.'
                    : 'Busca cuidadoras y agenda citas.',
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ])),
            ])),
          const SizedBox(height: 24),
          const Text('Accesos rápidos', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 12),
          Row(children: isCuidador ? [
            _QuickAction(icon: Icons.assignment, label: 'Solicitudes', color: const Color(0xFFFF7BAC),
                onTap: () => context.push(AppRoutes.citasCuidador)),
            const SizedBox(width: 12),
            // 🆕 Corregido: .agenda en lugar de .misCitas
            _QuickAction(icon: Icons.calendar_month, label: 'Mi\nagenda', color: const Color(0xFF00BFA5),
                onTap: () => context.push(AppRoutes.agenda)),
            const SizedBox(width: 12),
            _QuickAction(icon: Icons.gavel, label: 'Reglamento', color: Colors.grey,
                onTap: () => context.push(AppRoutes.reglamento)),
          ] : [
            _QuickAction(icon: Icons.search, label: 'Buscar', color: scheme.primary,
                onTap: () => context.push(AppRoutes.search)),
            const SizedBox(width: 12),
            // 🆕 Corregido: .agenda en lugar de .misCitas
            _QuickAction(icon: Icons.calendar_month, label: 'Mi\nagenda', color: const Color(0xFF00BFA5),
                onTap: () => context.push(AppRoutes.agenda)),
            const SizedBox(width: 12),
            _QuickAction(icon: Icons.gavel, label: 'Reglamento', color: Colors.grey,
                onTap: () => context.push(AppRoutes.reglamento)),
          ]),
        ]))),
    ]));
  }
}
 
class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Expanded(child: GestureDetector(onTap: onTap,
    child: Container(padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2))),
      child: Column(children: [Icon(icon, color: color, size: 28), const SizedBox(height: 6),
        Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: color))]))));
}
 
class _PerfilTab extends StatelessWidget {
  const _PerfilTab();
  @override
  Widget build(BuildContext context) {
    final client = Supabase.instance.client;
    return SafeArea(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
      const SizedBox(height: 20),
      CircleAvatar(radius: 44, backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          child: Icon(Icons.person, size: 44, color: Theme.of(context).colorScheme.primary)),
      const SizedBox(height: 12),
      Text(client.auth.currentUser?.email ?? '', style: const TextStyle(color: Colors.grey)),
      const SizedBox(height: 32),
      ListTile(leading: const Icon(Icons.gavel), title: const Text('Reglamento'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
          onTap: () => context.push(AppRoutes.reglamento)),
      const Divider(),
      ListTile(
        leading: const Icon(Icons.logout, color: Colors.red),
        title: const Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
        onTap: () async { await client.auth.signOut(); if (context.mounted) context.go(AppRoutes.login); }),
    ])));
  }
}