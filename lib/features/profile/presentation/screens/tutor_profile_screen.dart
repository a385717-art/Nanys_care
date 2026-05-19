// lib/features/profile/presentation/screens/tutor_profile_screen.dart
// US05 — Perfil del tutor con info de hijos

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/router/app_router.dart';
import '../../data/profile_repository.dart';

class TutorProfileScreen extends StatefulWidget {
  const TutorProfileScreen({super.key});
  @override
  State<TutorProfileScreen> createState() => _TutorProfileScreenState();
}

class _TutorProfileScreenState extends State<TutorProfileScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _repo      = ProfileRepository();
  final _nombre    = TextEditingController();
  final _telefono  = TextEditingController();
  final _direccion = TextEditingController();
  File? _avatarFile;
  bool _loading = false;
  final List<_HijoData> _hijos = [];

  @override
  void dispose() { _nombre.dispose(); _telefono.dispose(); _direccion.dispose(); super.dispose(); }

  Future<void> _pickImage() async {
    final p = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 600);
    if (p != null) setState(() => _avatarFile = File(p.path));
  }

  void _addHijo() => showModalBottomSheet(
    context: context, isScrollControlled: true, backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => _AddHijoSheet(onAdd: (h) => setState(() => _hijos.add(h))),
  );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      String? avatarUrl;
      if (_avatarFile != null) avatarUrl = await _repo.uploadAvatar(_avatarFile!);
      await _repo.saveTutorProfile(nombre: _nombre.text.trim(), telefono: _telefono.text.trim(),
          direccion: _direccion.text.trim(), avatarUrl: avatarUrl);
      for (final h in _hijos) { await _repo.addHijo(nombre: h.nombre, edad: h.edad, notas: h.notas); }
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
        title: const Text('Mi perfil de tutor'), automaticallyImplyLeading: false,
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
                    backgroundColor: scheme.secondary.withOpacity(0.15),
                    backgroundImage: _avatarFile != null ? FileImage(_avatarFile!) : null,
                    child: _avatarFile == null ? Icon(Icons.person, size: 52, color: scheme.secondary) : null),
                  Positioned(bottom: 0, right: 0,
                    child: Container(padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: scheme.secondary, shape: BoxShape.circle),
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
            TextFormField(controller: _direccion,
              decoration: const InputDecoration(labelText: 'Direccion / Colonia', prefixIcon: Icon(Icons.home_outlined)),
              validator: (v) => (v == null || v.isEmpty) ? 'Ingresa tu direccion' : null),
            const SizedBox(height: 28),
            Row(children: [
              _Label('Mis hijos (${_hijos.length})'),
              const Spacer(),
              TextButton.icon(onPressed: _addHijo, icon: const Icon(Icons.add, size: 18), label: const Text('Agregar')),
            ]),
            const SizedBox(height: 12),
            if (_hijos.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFE0EF))),
                child: const Center(child: Text('Agrega la informacion de tus hijos para recibir propuestas adecuadas.',
                    textAlign: TextAlign.center, style: TextStyle(color: Colors.grey))))
            else
              ...List.generate(_hijos.length, (i) => _HijoTile(hijo: _hijos[i], onDelete: () => setState(() => _hijos.removeAt(i)))),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _loading ? null : _save,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF7BAC)),
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
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFFFF7BAC)));
}

class _HijoData { final String nombre; final int edad; final String? notas;
  _HijoData({required this.nombre, required this.edad, this.notas}); }

class _HijoTile extends StatelessWidget {
  const _HijoTile({required this.hijo, required this.onDelete});
  final _HijoData hijo; final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE0EF))),
    child: Row(children: [
      Container(width: 40, height: 40,
        decoration: const BoxDecoration(color: Color(0xFFFFECF4), shape: BoxShape.circle),
        child: const Icon(Icons.child_friendly, color: Color(0xFFFF7BAC), size: 20)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(hijo.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
        Text('${hijo.edad} años', style: const TextStyle(color: Colors.grey, fontSize: 13)),
        if (hijo.notas != null && hijo.notas!.isNotEmpty)
          Text(hijo.notas!, style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
      ])),
      IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: onDelete),
    ]));
}

class _AddHijoSheet extends StatefulWidget {
  const _AddHijoSheet({required this.onAdd});
  final ValueChanged<_HijoData> onAdd;
  @override
  State<_AddHijoSheet> createState() => _AddHijoSheetState();
}

class _AddHijoSheetState extends State<_AddHijoSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nombre  = TextEditingController();
  final _notas   = TextEditingController();
  int _edad = 1;
  @override
  void dispose() { _nombre.dispose(); _notas.dispose(); super.dispose(); }
  void _confirm() {
    if (!_formKey.currentState!.validate()) return;
    widget.onAdd(_HijoData(nombre: _nombre.text.trim(), edad: _edad, notas: _notas.text.trim().isEmpty ? null : _notas.text.trim()));
    Navigator.pop(context);
  }
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
    child: Form(key: _formKey, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Agregar hijo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 20),
      TextFormField(controller: _nombre,
        decoration: const InputDecoration(labelText: 'Nombre del nino'), autofocus: true,
        validator: (v) => (v == null || v.isEmpty) ? 'Ingresa el nombre' : null),
      const SizedBox(height: 14),
      Row(children: [
        const Expanded(child: Text('Edad', style: TextStyle(color: Colors.grey))),
        IconButton(onPressed: () { if (_edad > 0) setState(() => _edad--); }, icon: const Icon(Icons.remove_circle_outline)),
        Text('$_edad', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        IconButton(onPressed: () => setState(() => _edad++), icon: const Icon(Icons.add_circle_outline)),
        const Text('años'),
      ]),
      const SizedBox(height: 14),
      TextFormField(controller: _notas,
        decoration: const InputDecoration(labelText: 'Notas especiales (alergias, etc.) - opcional'), maxLines: 2),
      const SizedBox(height: 24),
      ElevatedButton(onPressed: _confirm, child: const Text('Agregar')),
    ])),
  );
}