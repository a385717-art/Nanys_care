// lib/features/profile/presentation/screens/cuidador_profile_screen.dart
// US03 - Perfil con foto y experiencia  |  US04 - Tarifas

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/router/app_router.dart';
import '../../data/profile_repository.dart';

class CuidadorProfileScreen extends StatefulWidget {
  const CuidadorProfileScreen({super.key});
  @override
  State<CuidadorProfileScreen> createState() => _CuidadorProfileScreenState();
}

class _CuidadorProfileScreenState extends State<CuidadorProfileScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _repo        = ProfileRepository();
  final _nombre      = TextEditingController();
  final _telefono    = TextEditingController();
  final _descripcion = TextEditingController();
  final _zona        = TextEditingController();
  final _tarifa      = TextEditingController();
  int _anios = 0;
  File? _avatarFile;
  bool _loading = false;

  @override
  void dispose() {
    _nombre.dispose(); _telefono.dispose(); _descripcion.dispose();
    _zona.dispose(); _tarifa.dispose(); super.dispose();
  }

  Future<void> _pickImage() async {
    final p = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 600);
    if (p != null) setState(() => _avatarFile = File(p.path));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      String? avatarUrl;
      if (_avatarFile != null) avatarUrl = await _repo.uploadAvatar(_avatarFile!);
      await _repo.saveCuidadorProfile(
        nombre: _nombre.text.trim(), telefono: _telefono.text.trim(),
        descripcion: _descripcion.text.trim(), experienciaAnios: _anios,
        tarifaHora: double.parse(_tarifa.text), zona: _zona.text.trim(),
        avatarUrl: avatarUrl,
      );
      if (!mounted) return;
      context.go(AppRoutes.home);
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
      appBar: AppBar(
        title: const Text('Mi perfil de cuidadora'),
        automaticallyImplyLeading: false,
        actions: [TextButton(onPressed: () => context.go(AppRoutes.home), child: const Text('Omitir'))],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(children: [
                  CircleAvatar(radius: 52,
                    backgroundColor: scheme.primary.withOpacity(0.1),
                    backgroundImage: _avatarFile != null ? FileImage(_avatarFile!) : null,
                    child: _avatarFile == null ? Icon(Icons.person, size: 52, color: scheme.primary) : null),
                  Positioned(bottom: 0, right: 0,
                    child: Container(padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt, size: 16, color: Colors.white))),
                ]),
              ),
            ),
            const SizedBox(height: 8),
            const Center(child: Text('Toca para agregar foto', style: TextStyle(color: Colors.grey, fontSize: 13))),
            const SizedBox(height: 28),
            const _Label('Informacion personal'),
            const SizedBox(height: 12),
            TextFormField(controller: _nombre,
              decoration: const InputDecoration(labelText: 'Nombre completo', prefixIcon: Icon(Icons.person_outline)),
              validator: (v) => (v == null || v.isEmpty) ? 'Ingresa tu nombre' : null),
            const SizedBox(height: 14),
            TextFormField(controller: _telefono,
              decoration: const InputDecoration(labelText: 'Telefono', prefixIcon: Icon(Icons.phone_outlined)),
              keyboardType: TextInputType.phone,
              validator: (v) => (v == null || v.isEmpty) ? 'Ingresa tu telefono' : null),
            const SizedBox(height: 14),
            TextFormField(controller: _zona,
              decoration: const InputDecoration(labelText: 'Zona / Colonia donde trabajas', prefixIcon: Icon(Icons.location_on_outlined)),
              validator: (v) => (v == null || v.isEmpty) ? 'Ingresa tu zona' : null),
            const SizedBox(height: 28),
            const _Label('Experiencia y tarifa'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDDD8FF))),
              child: Row(children: [
                const Icon(Icons.work_history_outlined, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(child: Text('Anos de experiencia', style: TextStyle(color: Colors.grey.shade700))),
                _Btn(icon: Icons.remove, onTap: () { if (_anios > 0) setState(() => _anios--); }),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('$_anios', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
                _Btn(icon: Icons.add, onTap: () => setState(() => _anios++)),
              ]),
            ),
            const SizedBox(height: 14),
            TextFormField(controller: _tarifa,
              decoration: const InputDecoration(labelText: 'Tarifa por hora (MXN)', prefixIcon: Icon(Icons.attach_money), hintText: 'Ej: 80'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
              validator: (v) {
                if (v == null || v.isEmpty) return 'Ingresa tu tarifa';
                if (double.tryParse(v) == null) return 'Tarifa invalida';
                return null;
              }),
            const SizedBox(height: 14),
            _TarifaSugerida(anios: _anios),
            const SizedBox(height: 28),
            const _Label('Sobre ti'),
            const SizedBox(height: 12),
            TextFormField(controller: _descripcion,
              decoration: const InputDecoration(labelText: 'Descripcion / Presentacion', alignLabelWithHint: true,
                  prefixIcon: Padding(padding: EdgeInsets.only(bottom: 60), child: Icon(Icons.notes))),
              maxLines: 4, maxLength: 500,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Cuentanos sobre ti' : null),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Guardar perfil')),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF6B4EFF)));
}

class _Btn extends StatelessWidget {
  const _Btn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(width: 32, height: 32,
      decoration: BoxDecoration(color: const Color(0xFFEDEAFF), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, size: 18, color: const Color(0xFF6B4EFF))));
}

class _TarifaSugerida extends StatelessWidget {
  const _TarifaSugerida({required this.anios});
  final int anios;
  String get _nivel {
    if (anios == 0) return 'Sin experiencia: \$60-\$80/hr';
    if (anios <= 2) return 'Principiante: \$80-\$100/hr';
    if (anios <= 5) return 'Intermedio: \$100-\$130/hr';
    return 'Experto: \$130-\$180/hr';
  }
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(color: const Color(0xFFF0EDFF), borderRadius: BorderRadius.circular(10)),
    child: Row(children: [
      const Icon(Icons.lightbulb_outline, size: 16, color: Color(0xFF6B4EFF)),
      const SizedBox(width: 8),
      Expanded(child: Text('Sugerencia: $_nivel',
          style: const TextStyle(fontSize: 12, color: Color(0xFF6B4EFF)))),
    ]));
}