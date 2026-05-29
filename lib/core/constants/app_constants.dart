// lib/core/constants/app_constants.dart
//
// Las claves SE LEEN del entorno en tiempo de compilacion.
// Para correr en desarrollo:
//   flutter run --dart-define-from-file=.env
//
// Para hacer build:
//   flutter build apk --dart-define-from-file=.env
//
// NUNCA pongas las claves reales aqui directamente.

class AppConstants {
  // Leidas desde .env via --dart-define-from-file
  static const supabaseUrl =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  static const appName       = 'Nanys Care';
  static const avatarsBucket = 'avatars';

  // Validacion en tiempo de ejecucion (lanza error claro si faltan claves)
  static void validate() {
    assert(supabaseUrl.isNotEmpty,
        'Falta SUPABASE_URL. Ejecuta con --dart-define-from-file=.env');
    assert(supabaseAnonKey.isNotEmpty,
        'Falta SUPABASE_ANON_KEY. Ejecuta con --dart-define-from-file=.env');
  }
}
