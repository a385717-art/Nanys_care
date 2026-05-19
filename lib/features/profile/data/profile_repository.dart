// lib/features/profile/data/profile_repository.dart

import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';

class ProfileRepository {
  final _client = Supabase.instance.client;
  String get _userId => _client.auth.currentUser!.id;

  Future<void> setRole(String role) async =>
      await _client.from('profiles').update({'role': role}).eq('id', _userId);

  Future<Map<String, dynamic>?> getProfile() async =>
      await _client.from('profiles').select().eq('id', _userId).maybeSingle();

  Future<String?> uploadAvatar(File file) async {
    final ext  = file.path.split('.').last;
    final path = '$_userId/avatar.$ext';
    await _client.storage.from(AppConstants.avatarsBucket)
        .upload(path, file, fileOptions: const FileOptions(upsert: true));
    return _client.storage.from(AppConstants.avatarsBucket).getPublicUrl(path);
  }

  Future<void> saveCuidadorProfile({
    required String nombre, required String telefono,
    required String descripcion, required int experienciaAnios,
    required double tarifaHora, required String zona, String? avatarUrl,
  }) async {
    await _client.from('profiles').update({
      'nombre': nombre, 'telefono': telefono,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    }).eq('id', _userId);
    await _client.from('cuidadores').upsert({
      'id': _userId, 'descripcion': descripcion,
      'experiencia_anios': experienciaAnios, 'tarifa_hora': tarifaHora,
      'zona': zona, 'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> saveTutorProfile({
    required String nombre, required String telefono,
    required String direccion, String? avatarUrl,
  }) async {
    await _client.from('profiles').update({
      'nombre': nombre, 'telefono': telefono,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    }).eq('id', _userId);
    await _client.from('tutores').upsert({
      'id': _userId, 'direccion': direccion,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> addHijo({required String nombre, required int edad, String? notas}) async =>
      await _client.from('hijos').insert({'tutor_id': _userId, 'nombre': nombre, 'edad': edad, 'notas': notas});

  Future<List<Map<String, dynamic>>> getHijos() async {
    final data = await _client.from('hijos').select().eq('tutor_id', _userId).order('created_at');
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> deleteHijo(String hijoId) async =>
      await _client.from('hijos').delete().eq('id', hijoId);
}