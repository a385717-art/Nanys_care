// lib/core/router/app_router.dart
 
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
 
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/profile/presentation/screens/role_selection_screen.dart';
import '../../features/profile/presentation/screens/cuidador_profile_screen.dart';
import '../../features/profile/presentation/screens/tutor_profile_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/reglamento/presentation/screens/reglamento_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/search/presentation/screens/cuidador_detail_screen.dart';
import '../../features/citas/presentation/screens/booking_screen.dart';
import '../../features/citas/presentation/screens/agenda_screen.dart';
import '../../features/citas/presentation/screens/citas_cuidador_screen.dart';
import '../../features/citas/presentation/screens/detalle_cita_screen.dart'; 
 
class AppRoutes {
  static const splash          = '/';
  static const login           = '/login';
  static const register        = '/register';
  static const roleSelection   = '/role-selection';
  static const cuidadorProfile = '/cuidador-profile';
  static const tutorProfile    = '/tutor-profile';
  static const home            = '/home';
  static const reglamento      = '/reglamento';
  static const search          = '/search';
  static const cuidadorDetail  = '/cuidador-detail';
  static const agendarCita     = '/agendar-cita';
  static const agenda          = '/agenda';
  static const citasCuidador   = '/citas-cuidador';
  static const detalleCita     = '/detalle-cita';
}
 
final appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  redirect: _globalRedirect,
  routes: [
    GoRoute(path: AppRoutes.splash,          builder: (_, __) => const SplashScreen()),
    GoRoute(path: AppRoutes.login,           builder: (_, __) => const LoginScreen()),
    GoRoute(path: AppRoutes.register,        builder: (_, __) => const RegisterScreen()),
    GoRoute(path: AppRoutes.roleSelection,   builder: (_, __) => const RoleSelectionScreen()),
    GoRoute(path: AppRoutes.cuidadorProfile, builder: (_, __) => const CuidadorProfileScreen()),
    GoRoute(path: AppRoutes.tutorProfile,    builder: (_, __) => const TutorProfileScreen()),
    GoRoute(path: AppRoutes.home,            builder: (_, __) => const HomeScreen()),
    GoRoute(path: AppRoutes.reglamento,      builder: (_, __) => const ReglamentoScreen()),
    GoRoute(path: AppRoutes.search,          builder: (_, __) => const SearchScreen()),
    GoRoute(path: AppRoutes.cuidadorDetail,
        builder: (_, state) => CuidadorDetailScreen(cuidador: state.extra as Map<String, dynamic>)),
    GoRoute(path: AppRoutes.agendarCita,
        builder: (_, state) => BookingScreen(cuidador: state.extra as Map<String, dynamic>)),
    GoRoute(path: AppRoutes.agenda,          builder: (_, __) => const AgendaScreen()),
    GoRoute(path: AppRoutes.citasCuidador,   builder: (_, __) => const CitasCuidadorScreen()),
    
    // 🆕 3. Agrega la definición de la ruta para recibir los datos del "extra"
    GoRoute(
      path: AppRoutes.detalleCita,
      builder: (_, state) {
        final datos = state.extra as Map<String, dynamic>;
        return DetalleCitaScreen(
          cita: datos['cita'] as Map<String, dynamic>,
          onStateChanged: datos['onStateChanged'] as VoidCallback,
        );
      },
    ),
  ],
);
 
Future<String?> _globalRedirect(BuildContext context, GoRouterState state) async {
  final session  = Supabase.instance.client.auth.currentSession;
  final isOnAuth = state.matchedLocation == AppRoutes.login ||
                   state.matchedLocation == AppRoutes.register;
  if (session == null && !isOnAuth && state.matchedLocation != AppRoutes.splash) {
    return AppRoutes.login;
  }
  return null;
}