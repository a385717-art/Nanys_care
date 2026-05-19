// lib/features/auth/presentation/screens/register_screen.dart
// US01 — Registro con correo electronico

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/router/app_router.dart';
import '../../data/auth_repository.dart';
import '../widgets/auth_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _email      = TextEditingController();
  final _password   = TextEditingController();
  final _confirm    = TextEditingController();
  final _auth       = AuthRepository();
  bool _loading     = false;
  bool _acceptTerms = false;

  @override
  void dispose() { _email.dispose(); _password.dispose(); _confirm.dispose(); super.dispose(); }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) { _showError('Debes aceptar los terminos.'); return; }
    setState(() => _loading = true);
    try {
      final res = await _auth.signUp(email: _email.text, password: _password.text);
      if (!mounted) return;
      if (res.session != null) {
        context.go(AppRoutes.roleSelection);
      } else {
        _showConfirmDialog();
      }
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('Error inesperado. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Theme.of(context).colorScheme.error));

  void _showConfirmDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Verifica tu correo'),
        content: Text('Enviamos un enlace a ${_email.text}. Revisalo y haz clic para activar tu cuenta.'),
        actions: [
          ElevatedButton(
            onPressed: () { Navigator.pop(context); context.go(AppRoutes.login); },
            child: const Text('Ir al login'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => context.pop())),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text('Crear cuenta',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('Unete a Nanys Care',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                const SizedBox(height: 32),
                AuthTextField(
                  label: 'Correo electronico', controller: _email,
                  icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ingresa tu correo';
                    if (!v.contains('@')) return 'Correo invalido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  label: 'Contrasena', controller: _password,
                  icon: Icons.lock_outline, isPassword: true,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ingresa una contrasena';
                    if (v.length < 6) return 'Minimo 6 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  label: 'Confirmar contrasena', controller: _confirm,
                  icon: Icons.lock_outline, isPassword: true,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _register(),
                  validator: (v) => v != _password.text ? 'Las contrasenas no coinciden' : null,
                ),
                const SizedBox(height: 20),
                _PasswordStrength(password: _password),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _acceptTerms,
                      activeColor: scheme.primary,
                      onChanged: (v) => setState(() => _acceptTerms = v ?? false),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(color: Colors.black87),
                            children: [
                              const TextSpan(text: 'Acepto los '),
                              TextSpan(text: 'Terminos y condiciones',
                                  style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600)),
                              const TextSpan(text: ' y el Reglamento de la plataforma'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loading ? null : _register,
                  child: _loading
                      ? const SizedBox(height: 20, width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Crear cuenta'),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Ya tienes cuenta?'),
                    TextButton(onPressed: () => context.pop(), child: const Text('Inicia sesion')),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordStrength extends StatefulWidget {
  const _PasswordStrength({required this.password});
  final TextEditingController password;
  @override
  State<_PasswordStrength> createState() => _PasswordStrengthState();
}

class _PasswordStrengthState extends State<_PasswordStrength> {
  @override
  void initState() { super.initState(); widget.password.addListener(() => setState(() {})); }

  int get _strength {
    final v = widget.password.text;
    if (v.isEmpty) return 0;
    int s = 0;
    if (v.length >= 8) s++;
    if (RegExp(r'[A-Z]').hasMatch(v)) s++;
    if (RegExp(r'[0-9]').hasMatch(v)) s++;
    if (RegExp(r'[!@#\$%^&*]').hasMatch(v)) s++;
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final labels = ['', 'Debil', 'Regular', 'Buena', 'Fuerte'];
    final colors = [Colors.transparent, Colors.red, Colors.orange, Colors.amber, Colors.green];
    final s = _strength;
    if (s == 0) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) => Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: i < s ? colors[s] : Colors.grey.shade200,
              ),
            ),
          )),
        ),
        const SizedBox(height: 4),
        Text('Seguridad: ${labels[s]}', style: TextStyle(fontSize: 12, color: colors[s])),
      ],
    );
  }
}