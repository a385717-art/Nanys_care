// lib/features/profile/presentation/screens/role_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../data/profile_repository.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});
  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  final _repo   = ProfileRepository();
  String? _role;
  bool _loading = false;

  Future<void> _confirm() async {
    if (_role == null) return;
    setState(() => _loading = true);
    try {
      await _repo.setRole(_role!);
      if (!mounted) return;
      context.go(_role == 'cuidador' ? AppRoutes.cuidadorProfile : AppRoutes.tutorProfile);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar. Intenta de nuevo.')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              Text('Como usaras\nNanys Care?',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('Elige tu rol en la plataforma.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
              const SizedBox(height: 40),
              _RoleCard(
                title: 'Soy tutor / padre',
                subtitle: 'Busco cuidadores de confianza para mis hijos.',
                icon: Icons.family_restroom, color: const Color(0xFF6B4EFF),
                selected: _role == 'tutor', onTap: () => setState(() => _role = 'tutor'),
              ),
              const SizedBox(height: 16),
              _RoleCard(
                title: 'Soy cuidador / ninera',
                subtitle: 'Ofrezco mis servicios de cuidado infantil profesional.',
                icon: Icons.favorite, color: const Color(0xFFFF7BAC),
                selected: _role == 'cuidador', onTap: () => setState(() => _role = 'cuidador'),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: (_role == null || _loading) ? null : _confirm,
                child: _loading
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Continuar'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.title, required this.subtitle, required this.icon,
      required this.color, required this.selected, required this.onTap});
  final String title, subtitle;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? color : const Color(0xFFE0E0E0), width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(width: 56, height: 56,
                decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 28)),
            const SizedBox(width: 16),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            )),
            Icon(selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected ? color : Colors.grey),
          ],
        ),
      ),
    );
  }
}