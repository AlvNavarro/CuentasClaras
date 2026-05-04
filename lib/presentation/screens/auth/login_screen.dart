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
  // 0 = login, 1 = registro, 2 = recuperar contraseña
  int _mode = 0;

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _businessCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    _businessCtrl.dispose();
    super.dispose();
  }

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

  Future<void> _register() async {
    if (_nameCtrl.text.trim().isEmpty ||
        _businessCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty ||
        _passCtrl.text.isEmpty) {
      setState(() => _error = 'Rellena todos los campos');
      return;
    }
    if (_passCtrl.text.length < 6) {
      setState(() => _error = 'La contraseña debe tener al menos 6 caracteres');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await SupabaseService.instance.signUpWithEmail(
        _emailCtrl.text.trim(),
        _passCtrl.text,
        _businessCtrl.text.trim(),
        _nameCtrl.text.trim(),
      );
      if (mounted) context.go('/dashboard');
    } catch (e) {
      setState(() => _error = 'Error al crear la cuenta. El email puede que ya esté en uso.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Introduce tu email');
      return;
    }
    setState(() { _loading = true; _error = null; _success = null; });
    try {
      await SupabaseService.instance.resetPassword(_emailCtrl.text.trim());
      setState(() => _success =
          'Te hemos enviado un email para restablecer tu contraseña');
    } catch (e) {
      setState(() => _error = 'Error al enviar el email. Comprueba la dirección.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _switchMode(int mode) {
    setState(() {
      _mode = mode;
      _error = null;
      _success = null;
    });
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
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.asset(
                  'assets/images/logo.png',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                ),
                ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3, end: 0),
              const SizedBox(height: 28),

              // Título según modo
              Text(
                _mode == 0 ? 'Bienvenido' :
                _mode == 1 ? 'Crear empresa' : 'Recuperar contraseña',
                style: AppTextStyles.display,
              ).animate().fadeIn(delay: 150.ms, duration: 500.ms),
              const SizedBox(height: 6),
              Text(
                _mode == 0
                    ? 'Gestiona tu inventario desde el móvil,\nen cualquier momento.'
                    : _mode == 1
                        ? 'Crea tu cuenta de administrador\ny empieza a gestionar tu negocio.'
                        : 'Introduce tu email y te enviaremos\nun enlace para restablecer tu contraseña.',
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              ).animate().fadeIn(delay: 250.ms, duration: 500.ms),
              const SizedBox(height: 40),

              // Campos adicionales en registro
              if (_mode == 1) ...[
                Text('Nombre completo', style: AppTextStyles.label),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'Tu nombre',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 16),
                Text('Nombre del negocio', style: AppTextStyles.label),
                const SizedBox(height: 8),
                TextField(
                  controller: _businessCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'Ej: Panadería García',
                    prefixIcon: Icon(Icons.storefront_outlined),
                  ),
                ).animate().fadeIn(delay: 350.ms),
                const SizedBox(height: 16),
              ],

              // Email (siempre visible)
              Text('Correo electrónico', style: AppTextStyles.label)
                  .animate().fadeIn(delay: 350.ms),
              const SizedBox(height: 8),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: _mode == 2
                    ? TextInputAction.done
                    : TextInputAction.next,
                onSubmitted: _mode == 2 ? (_) => _resetPassword() : null,
                decoration: const InputDecoration(
                  hintText: 'hola@tutienda.es',
                  prefixIcon: Icon(Icons.mail_outline_rounded),
                ),
              ).animate().fadeIn(delay: 400.ms),

              // Contraseña (solo login y registro)
              if (_mode != 2) ...[
                const SizedBox(height: 20),
                Text('Contraseña', style: AppTextStyles.label)
                    .animate().fadeIn(delay: 450.ms),
                const SizedBox(height: 8),
                TextField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _mode == 0 ? _signIn() : _register(),
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
              ],

              // Mensajes de error y éxito
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
                      Expanded(
                        child: Text(_error!,
                            style: AppTextStyles.body
                                .copyWith(color: AppColors.danger)),
                      ),
                    ],
                  ),
                ).animate().fadeIn().shakeX(amount: 4),
              ],

              if (_success != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.success.withOpacity(0.3), width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline,
                          color: AppColors.success, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_success!,
                            style: AppTextStyles.body
                                .copyWith(color: AppColors.success)),
                      ),
                    ],
                  ),
                ).animate().fadeIn(),
              ],

              const SizedBox(height: 28),

              // Botón principal
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null :
                      _mode == 0 ? _signIn :
                      _mode == 1 ? _register : _resetPassword,
                  child: _loading
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: AppColors.onPrimary))
                      : Text(
                          _mode == 0 ? 'Iniciar sesión' :
                          _mode == 1 ? 'Crear empresa' :
                          'Enviar enlace'),
                ),
              ).animate().fadeIn(delay: 550.ms),

              const SizedBox(height: 16),

              // Botones secundarios
              if (_mode == 0) ...[
                // Recuperar contraseña
                Center(
                  child: TextButton(
                    onPressed: () => _switchMode(2),
                    child: Text('¿Olvidaste tu contraseña?',
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.primary)),
                  ),
                ),
                const SizedBox(height: 8),
                // Crear empresa
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _switchMode(1),
                    icon: const Icon(Icons.storefront_outlined, size: 18),
                    label: const Text('Crear nueva empresa'),
                  ),
                ),
              ] else ...[
                Center(
                  child: TextButton(
                    onPressed: () => _switchMode(0),
                    child: Text('← Volver al inicio de sesión',
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.primary)),
                  ),
                ),
              ],

              const SizedBox(height: 32),
              Center(
                child: Text(
                  _mode == 0
                      ? '¿Eres empleado? Pide acceso a tu administrador.'
                      : '',
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