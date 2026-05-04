import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/services/supabase_service.dart';
import '../../widgets/common_widgets.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});
  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  List<Map<String, dynamic>> _employees = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await SupabaseService.instance.getEmployees();
      if (mounted) setState(() { _employees = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _addEmployee() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddEmployeeSheet(onSaved: _load),
    );
  }

  Future<void> _deleteEmployee(Map<String, dynamic> emp) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar empleado'),
        content: Text(
            '¿Estás seguro de que quieres eliminar a ${emp['full_name']}? Perderá acceso a la aplicación.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await SupabaseService.instance.deleteEmployee(emp['id'] as String);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Empleados', style: AppTextStyles.h2),
            Text('${_employees.length} en tu equipo',
                style: AppTextStyles.caption),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addEmployee,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Añadir empleado'),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _employees.isEmpty
              ? EmptyState(
                  icon: Icons.people_outline_rounded,
                  title: 'Sin empleados',
                  subtitle:
                      'Añade empleados para que puedan acceder a la app.',
                  action: _addEmployee,
                  actionLabel: 'Añadir empleado',
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  child: ListView.separated(
                    padding:
                        const EdgeInsets.fromLTRB(20, 16, 20, 100),
                    itemCount: _employees.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final emp = _employees[i];
                      final name = emp['full_name'] as String? ?? '';
                      final email = emp['email'] as String? ?? '';
                      final initial = name.isNotEmpty
                          ? name[0].toUpperCase()
                          : '?';
                      return AppCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(initial,
                                    style: AppTextStyles.h3.copyWith(
                                        color: AppColors.primary)),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(name,
                                      style: AppTextStyles.label),
                                  const SizedBox(height: 2),
                                  Text(email,
                                      style: AppTextStyles.caption),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.amberContainer,
                                      borderRadius:
                                          BorderRadius.circular(100),
                                    ),
                                    child: Text('Empleado',
                                        style: AppTextStyles.caption
                                            .copyWith(
                                          color: AppColors.amber,
                                          fontWeight: FontWeight.w700,
                                        )),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: AppColors.danger),
                              onPressed: () => _deleteEmployee(emp),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(
                          delay: Duration(milliseconds: i * 50),
                          duration: 300.ms);
                    },
                  ),
                ),
    );
  }
}

// ─── ADD EMPLOYEE SHEET ───────────────────────────────────────────────────────
class _AddEmployeeSheet extends StatefulWidget {
  const _AddEmployeeSheet({required this.onSaved});
  final VoidCallback onSaved;
  @override
  State<_AddEmployeeSheet> createState() => _AddEmployeeSheetState();
}

class _AddEmployeeSheetState extends State<_AddEmployeeSheet> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _saving = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty ||
        _passCtrl.text.isEmpty) {
      setState(() => _error = 'Rellena todos los campos');
      return;
    }
    if (_passCtrl.text.length < 6) {
      setState(() =>
          _error = 'La contraseña debe tener al menos 6 caracteres');
      return;
    }
    setState(() { _saving = true; _error = null; });
    try {
      await SupabaseService.instance.createEmployee(
        _emailCtrl.text.trim(),
        _passCtrl.text,
        _nameCtrl.text.trim(),
      );
      await SupabaseService.instance.client
          .from('employee_profiles')
          .insert({
            'owner_id': SupabaseService.instance.currentUserId,
            'full_name': _nameCtrl.text.trim(),
            'email': _emailCtrl.text.trim(),
          });

      widget.onSaved();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Empleado añadido correctamente')),
        );
      }
    } catch (e) {
      setState(() => _error =
          'Error al crear el empleado. El email puede que ya esté en uso.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.92,
        minChildSize: 0.5,
        expand: false,
        builder: (ctx, scroll) => Container(
          color: AppColors.surface,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                        child: Text('Nuevo empleado',
                            style: AppTextStyles.h3)),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 16),
              Expanded(
                child: ListView(
                  controller: scroll,
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  children: [
                    Text('Nombre completo', style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'Nombre del empleado',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Email', style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'empleado@email.com',
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Contraseña inicial',
                        style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        hintText: 'Mínimo 6 caracteres',
                        prefixIcon:
                            const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.danger.withOpacity(0.3)),
                        ),
                        child: Text(_error!,
                            style: AppTextStyles.body
                                .copyWith(color: AppColors.danger)),
                      ),
                    ],
                    const SizedBox(height: 24),
                    AppCard(
                      backgroundColor: AppColors.amberContainer,
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              size: 18, color: AppColors.amber),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'El empleado podrá ver productos, registrar ventas y ver alertas. No podrá editar ni eliminar productos.',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.amber),
                            ),
                          ),
                        ],
                      ),
                    ),
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
                            : const Text('Crear empleado'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}