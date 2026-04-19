import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:cuentas_claras/core/theme/app_colors.dart';
import 'package:cuentas_claras/core/theme/app_text_styles.dart';
import 'package:cuentas_claras/data/services/supabase_service.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  Future<void> _signIn() async {
    setState(() { _loading = true; _error = null; });
    try {
      await SupabaseService.instance.signInWithEmail(
        _emailCtrl.text.trim(),
        _passCtrl.text,
      );
      if (mounted) context.go('/dashboard');
    } catch (e) {
      setState(() => _error = 'Email o contraseña incorrectos');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              // Logo
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: AppColors.onPrimary,
                  size: 32,
                ),
              ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3, end: 0),
              const SizedBox(height: 28),
              Text('Bienvenido', style: AppTextStyles.display)
                  .animate()
                  .fadeIn(delay: 150.ms, duration: 500.ms)
                  .slideY(begin: 0.2, end: 0),
              const SizedBox(height: 6),
              Text(
                'Gestiona tu inventario desde el móvil,\nen cualquier momento.',
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textSecondary),
              )
                  .animate()
                  .fadeIn(delay: 250.ms, duration: 500.ms)
                  .slideY(begin: 0.2, end: 0),
              const SizedBox(height: 48),

              // Fields
              Text('Correo electrónico', style: AppTextStyles.label)
                  .animate()
                  .fadeIn(delay: 350.ms),
              const SizedBox(height: 8),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'hola@tutienda.es',
                  prefixIcon: Icon(Icons.mail_outline_rounded),
                ),
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 20),
              Text('Contraseña', style: AppTextStyles.label)
                  .animate()
                  .fadeIn(delay: 450.ms),
              const SizedBox(height: 8),
              TextField(
                controller: _passCtrl,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _signIn(),
                decoration: InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ).animate().fadeIn(delay: 500.ms),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.danger.withOpacity(0.3), width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.danger, size: 18),
                      const SizedBox(width: 8),
                      Text(_error!,
                          style: AppTextStyles.body
                              .copyWith(color: AppColors.danger)),
                    ],
                  ),
                ).animate().fadeIn().shakeX(amount: 4),
              ],

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _signIn,
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.onPrimary,
                          ),
                        )
                      : const Text('Iniciar sesión'),
                ),
              ).animate().fadeIn(delay: 550.ms),
  
              const SizedBox(height: 40),
              Center(
                child: Text(
                  '¿No tienes cuenta? Habla con tu administrador.',
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
              ).animate().fadeIn(delay: 700.ms),
            ],
          ),
        ),
      ),
    );
  }
}
