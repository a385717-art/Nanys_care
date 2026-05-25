// lib/core/constants/app_constants.dart
// Las credenciales se leen de secrets.dart (gitignored).
// Consulta secrets.dart.example para configurar tu entorno local.

import 'secrets.dart';

class AppConstants {
  static const supabaseUrl     = AppSecrets.supabaseUrl;
  static const supabaseAnonKey = AppSecrets.supabaseAnonKey;
  static const appName         = 'Nanys Care';
  static const avatarsBucket   = 'avatars';
}
