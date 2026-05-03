import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cuentas_claras/core/theme/app_colors.dart';
import 'package:cuentas_claras/core/theme/app_text_styles.dart';
import 'package:cuentas_claras/core/utils/formatters.dart';
import 'package:cuentas_claras/data/models/product.dart';
import 'package:cuentas_claras/data/models/sale.dart';
import 'package:cuentas_claras/data/repositories/inventory_repository.dart';
import 'package:cuentas_claras/data/services/supabase_service.dart';
import 'package:cuentas_claras/presentation/widgets/common_widgets.dart';
import 'package:cuentas_claras/presentation/screens/products/products_screen.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});
  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _repo = InventoryRepository.instance;
  List<Product> _lowStock = [];
  List<Product> _outOfStock = [];
  List<AppNotification> _notifications = [];
  bool _loading = true;
  late TabController _tabs;
  late StreamSubscription _sub;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addObserver(this);
    _load();
    _sub = InventoryRepository.instance.onStockChanged.listen((_) async {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) _load();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  @override
  void dispose() {
    _sub.cancel();
    _tabs.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _load() async {
    final all = await _repo.getLowStockProducts();
    final notifs = await _repo.getNotifications();
    if (mounted) {
      setState(() {
        _outOfStock = all.where((p) => p.isOutOfStock).toList();
        _lowStock = all.where((p) => p.isLowStock).toList();
        _notifications = notifs;
        _loading = false;
      });
    }
  }

  Future<void> _openProduct(Product product) async {
    final categories = await _repo.getCategories();
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ProductDetail(
        product: product,
        repo: _repo,
        categories: categories,
        onUpdate: _load,
        isAdmin: SupabaseService.instance.isAdmin,
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final alertCount = _lowStock.length + _outOfStock.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Alertas', style: AppTextStyles.h2),
            Text(
              alertCount == 0
                  ? 'Sin alertas activas'
                  : '$alertCount producto${alertCount == 1 ? '' : 's'} requieren atención',
              style: AppTextStyles.caption.copyWith(
                color: alertCount > 0 ? AppColors.danger : AppColors.success,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
            tooltip: 'Actualizar',
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelStyle: AppTextStyles.label,
          unselectedLabelStyle: AppTextStyles.body,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: [
            Tab(text: 'Stock (${_lowStock.length + _outOfStock.length})'),
            Tab(text: 'Historial (${_notifications.length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabs,
              children: [
                _stockTab(),
                _historyTab(),
              ],
            ),
    );
  }

  Widget _stockTab() {
    if (_lowStock.isEmpty && _outOfStock.isEmpty) {
      return const EmptyState(
        icon: Icons.check_circle_outline_rounded,
        title: '¡Todo en orden!',
        subtitle: 'No hay productos con stock bajo en este momento.',
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          if (_outOfStock.isNotEmpty) ...[
            _sectionLabel('AGOTADOS', AppColors.danger),
            const SizedBox(height: 8),
            ..._outOfStock.asMap().entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AlertTile(
                      product: e.value,
                      onTap: () => _openProduct(e.value),
                    )
                        .animate()
                        .fadeIn(delay: Duration(milliseconds: e.key * 50)),
                  ),
                ),
            const SizedBox(height: 16),
          ],
          if (_lowStock.isNotEmpty) ...[
            _sectionLabel('STOCK BAJO', AppColors.warning),
            const SizedBox(height: 8),
            ..._lowStock.asMap().entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AlertTile(
                      product: e.value,
                      onTap: () => _openProduct(e.value),
                    )
                        .animate()
                        .fadeIn(
                            delay: Duration(milliseconds: e.key * 50 + 100)),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  Widget _historyTab() {
    if (_notifications.isEmpty) {
      return const EmptyState(
        icon: Icons.notifications_none_rounded,
        title: 'Sin notificaciones',
        subtitle: 'Las alertas de stock aparecerán aquí.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      itemCount: _notifications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final n = _notifications[i];
        final isOut = n.currentStock == 0;
        final color = isOut ? AppColors.danger : AppColors.warning;
        return AppCard(
          borderColor: color.withOpacity(0.25),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isOut
                      ? Icons.remove_shopping_cart_outlined
                      : Icons.warning_amber_rounded,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(n.productName, style: AppTextStyles.label),
                    const SizedBox(height: 2),
                    Text(n.message, style: AppTextStyles.bodySm),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.relative(n.createdAt),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: Duration(milliseconds: i * 40));
      },
    );
  }

  Widget _sectionLabel(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 14,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Text(text, style: AppTextStyles.labelSm.copyWith(color: color)),
      ],
    );
  }
}