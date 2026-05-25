// lib/features/auth/presentation/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../data/auth_repository.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _auth = AuthRepository();

  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    // Pequeño delay estético para mostrar el logo de la app
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    final session = _auth.currentSession;

    // CASO 1: Si no hay ninguna sesión activa en el dispositivo, vamos a Login
    if (session == null) {
      context.go(AppRoutes.login);
      return;
    }

    // CASO 2: Si hay una sesión activa, intentamos obtener el rol de forma segura
    try {
      final role = await _auth.getUserRole();
      if (!mounted) return;

      // Evaluamos el rol obtenido para decidir a dónde redirigir
      if (role == null || role == 'pending') {
        context.go(AppRoutes.roleSelection);
      } else {
        context.go(AppRoutes.home);
      }
    } catch (e) {
      // CONTROL DE ERRORES: Si Supabase arroja un error (como el 403 de permisos o red),
      // lo atrapamos aquí para evitar que la aplicación se congele con el indicador de carga.
      debugPrint(" Error detectado en el flujo del Splash: $e");
      
      if (!mounted) return;
      // Mandamos al usuario al Login por seguridad para limpiar el estado corrupto
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: scheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Contenedor del ícono/logo principal
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.child_care, size: 56, color: Colors.white),
            ),
            const SizedBox(height: 24),
            // Nombre de la App
            const Text(
              'Nanys Care',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            // Eslogan o subtítulo
            Text(
              'Tu cuidado de confianza',
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 48),
            // Indicador de progreso circular
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}