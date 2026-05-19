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

class AppRoutes {
  static const splash          = '/';
  static const login           = '/login';
  static const register        = '/register';
  static const roleSelection   = '/role-selection';
  static const cuidadorProfile = '/cuidador-profile';
  static const tutorProfile    = '/tutor-profile';
  static const home            = '/home';
  static const reglamento      = '/reglamento';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  redirect: _globalRedirect,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (_, __) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (_, __) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (_, __) => const RegisterScreen(),
    ),
    GoRoute(
      path: AppRoutes.roleSelection,
      builder: (_, __) => const RoleSelectionScreen(),
    ),
    GoRoute(
      path: AppRoutes.cuidadorProfile,
      builder: (_, __) => const CuidadorProfileScreen(),
    ),
    GoRoute(
      path: AppRoutes.tutorProfile,
      builder: (_, __) => const TutorProfileScreen(),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (_, __) => const HomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.reglamento,
      builder: (_, __) => const ReglamentoScreen(),
    ),
  ],
);

Future<String?> _globalRedirect(BuildContext context, GoRouterState state) async {
  final session = Supabase.instance.client.auth.currentSession;
  final isOnAuth = state.matchedLocation == AppRoutes.login ||
      state.matchedLocation == AppRoutes.register;

  if (session == null && !isOnAuth && state.matchedLocation != AppRoutes.splash) {
    return AppRoutes.login;
  }
  return null;
}