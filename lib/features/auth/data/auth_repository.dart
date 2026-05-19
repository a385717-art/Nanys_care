// lib/features/auth/data/auth_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final _client = Supabase.instance.client;

  Future<AuthResponse> signUp({required String email, required String password}) async {
    return await _client.auth.signUp(email: email.trim(), password: password);
  }

  Future<AuthResponse> signIn({required String email, required String password}) async {
    return await _client.auth.signInWithPassword(email: email.trim(), password: password);
  }

  Future<void> signOut() async => await _client.auth.signOut();

  Session? get currentSession => _client.auth.currentSession;
  User?    get currentUser    => _client.auth.currentUser;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<String?> getUserRole() async {
    final userId = currentUser?.id;
    if (userId == null) return null;
    final data = await _client
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .maybeSingle();
    return data?['role'] as String?;
  }
}