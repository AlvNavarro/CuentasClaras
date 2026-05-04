import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/services/supabase_service.dart';
import 'dashboard/dashboard_screen.dart';
import 'products/products_screen.dart';
import 'sales/sales_screen.dart';
import 'alerts/alerts_screen.dart';
import 'history/history_screen.dart';
import 'employees/employees_screen.dart';
import '../../presentation/widgets/common_widgets.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  late final List<Widget> _screens;
  late final List<BottomNavigationBarItem> _items;
  late final bool _isAdmin;

  @override
  void initState() {
    super.initState();
    _isAdmin = SupabaseService.instance.isAdmin;

    if (_isAdmin) {
      _screens = [
        DashboardScreen(onGoToAlerts: () => _onTap(3)),
        ProductsScreen(),
        SalesScreen(),
        AlertsScreen(),
        HistoryScreen(),
      ];
      _items = const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard_rounded),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2_outlined),
          activeIcon: Icon(Icons.inventory_2_rounded),
          label: 'Productos',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_outlined),
          activeIcon: Icon(Icons.receipt_long_rounded),
          label: 'Ventas',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications_outlined),
          activeIcon: Icon(Icons.notifications_rounded),
          label: 'Alertas',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month_outlined),
          activeIcon: Icon(Icons.calendar_month_rounded),
          label: 'Histórico',
        ),
      ];
    } else {
      _screens = [
        ProductsScreen(),
        SalesScreen(),
        AlertsScreen(),
      ];
      _items = const [
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2_outlined),
          activeIcon: Icon(Icons.inventory_2_rounded),
          label: 'Productos',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_outlined),
          activeIcon: Icon(Icons.receipt_long_rounded),
          label: 'Ventas',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications_outlined),
          activeIcon: Icon(Icons.notifications_rounded),
          label: 'Alertas',
        ),
      ];
    }
  }

  void _onTap(int index) {
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
  }

  void _openProfile() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _GlobalProfileSheet(
        onSignOut: () => context.go('/login'),
        onEmployees: _isAdmin
            ? () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const EmployeesScreen()),
                );
              }
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = SupabaseService.instance.currentUser?.email ?? '';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : '?';

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: _screens),
          // Icono de perfil flotante sobre todas las pantallas
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            right: 16,
            child: GestureDetector(
              onTap: _openProfile,
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Text(initial,
                      style: AppTextStyles.label
                          .copyWith(color: AppColors.primary)),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border:
              Border(top: BorderSide(color: AppColors.divider, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTap,
          items: _items,
        ),
      ),
    );
  }
}

// ─── GLOBAL PROFILE SHEET ─────────────────────────────────────────────────────
class _GlobalProfileSheet extends StatefulWidget {
  const _GlobalProfileSheet({required this.onSignOut, this.onEmployees});
  final VoidCallback onSignOut;
  final VoidCallback? onEmployees;
  @override
  State<_GlobalProfileSheet> createState() => _GlobalProfileSheetState();
}

class _GlobalProfileSheetState extends State<_GlobalProfileSheet> {
  final _nameCtrl = TextEditingController();
  final _businessCtrl = TextEditingController();
  bool _saving = false;
  final bool _isAdmin = SupabaseService.instance.isAdmin;

  @override
  void initState() {
    super.initState();
    final user = SupabaseService.instance.currentUser;
    _nameCtrl.text = user?.userMetadata?['full_name'] as String? ?? '';
    _businessCtrl.text =
        user?.userMetadata?['business_name'] as String? ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _businessCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await SupabaseService.instance.auth.updateUser(
        UserAttributes(data: {
          'full_name': _nameCtrl.text.trim(),
          'business_name': _businessCtrl.text.trim(),
        }),
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Perfil actualizado correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar el perfil')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content:
            const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await SupabaseService.instance.signOut();
      if (mounted) {
        Navigator.pop(context);
        widget.onSignOut();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = SupabaseService.instance.currentUser;
    final email = user?.email ?? '';
    final name = user?.userMetadata?['full_name'] as String? ?? '';
    final business =
        user?.userMetadata?['business_name'] as String? ?? '';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : '?';

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (ctx, scroll) => Container(
        color: AppColors.surface,
        child: ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Avatar
            Center(
              child: Column(
                children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                          width: 2),
                    ),
                    child: Center(
                      child: Text(initial,
                          style: AppTextStyles.h1
                              .copyWith(color: AppColors.primary)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (name.isNotEmpty) Text(name, style: AppTextStyles.h3),
                  if (business.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(business,
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                  const SizedBox(height: 4),
                  Text(email, style: AppTextStyles.caption),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isAdmin
                          ? AppColors.primaryContainer
                          : AppColors.amberContainer,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      _isAdmin ? 'Administrador' : 'Empleado',
                      style: AppTextStyles.caption.copyWith(
                        color: _isAdmin
                            ? AppColors.primary
                            : AppColors.amber,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            Text('Nombre completo', style: AppTextStyles.label),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                hintText: 'Tu nombre',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            if (_isAdmin) ...[
              const SizedBox(height: 16),
              Text('Nombre del negocio', style: AppTextStyles.label),
              const SizedBox(height: 8),
              TextField(
                controller: _businessCtrl,
                decoration: const InputDecoration(
                  hintText: 'Ej: Panadería García',
                  prefixIcon: Icon(Icons.storefront_outlined),
                ),
              ),
            ],
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.onPrimary))
                    : const Text('Guardar cambios'),
              ),
            ),

            if (_isAdmin && widget.onEmployees != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: widget.onEmployees,
                  icon: const Icon(Icons.people_outline_rounded, size: 18),
                  label: const Text('Gestionar empleados'),
                ),
              ),
            ],

            const SizedBox(height: 16),
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('INFORMACIÓN DE CUENTA',
                      style: AppTextStyles.labelSm),
                  const SizedBox(height: 12),
                  Row(children: [
                    const Icon(Icons.mail_outline_rounded,
                        size: 18, color: AppColors.textMuted),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(email, style: AppTextStyles.body)),
                  ]),
                  const Divider(height: 20),
                  Row(children: [
                    const Icon(Icons.shield_outlined,
                        size: 18, color: AppColors.textMuted),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Datos protegidos con RLS · Supabase',
                          style: AppTextStyles.caption),
                    ),
                  ]),
                  const Divider(height: 20),
                  Row(children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 18, color: AppColors.textMuted),
                    const SizedBox(width: 12),
                    Text('CuentasClaras v1.0.0',
                        style: AppTextStyles.caption),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Cerrar sesión'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}