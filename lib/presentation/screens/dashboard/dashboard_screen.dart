import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/repositories/inventory_repository.dart';
import '../../../data/services/supabase_service.dart';
import '../../widgets/common_widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.onGoToAlerts});
  final VoidCallback? onGoToAlerts;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _repo = InventoryRepository.instance;
  DashboardMetrics? _metrics;
  bool _loading = true;
  late StreamSubscription _sub;

  @override
  void initState() {
    super.initState();
    _load();
    _sub = InventoryRepository.instance.onStockChanged.listen((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final m = await _repo.getDashboardMetrics();
    if (mounted) setState(() { _metrics = m; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            if (_loading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 24),
                    _kpiRow(),
                    const SizedBox(height: 12),
                    _kpiRowSecond(),
                    const SizedBox(height: 28),
                    _chartSection(),
                    const SizedBox(height: 28),
                    if (_metrics!.topLowStock.isNotEmpty) ...[
                      _lowStockSection(),
                      const SizedBox(height: 28),
                    ],
                    _recentSalesSection(),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Buenos días'
        : now.hour < 19
            ? 'Buenas tardes'
            : 'Buenas noches';

    return SliverAppBar(
      backgroundColor: AppColors.background,
      floating: true,
      snap: true,
      toolbarHeight: 80,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(greeting, style: AppTextStyles.caption),
          Text('Panel de control', style: AppTextStyles.h2),
        ],
      ),
      // Espacio para el icono de perfil del MainShell
      actions: const [SizedBox(width: 56)],
    );
  }

  Widget _kpiRow() {
    final m = _metrics!;
    return Row(
      children: [
        Expanded(
          child: KpiCard(
            label: 'VENTAS HOY',
            value: Formatters.money(m.todayRevenue),
            subtitle:
                '${m.todaySalesCount} transacción${m.todaySalesCount == 1 ? '' : 'es'}',
            icon: Icons.today_rounded,
            accentColor: AppColors.primary,
          ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.3, end: 0),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: KpiCard(
            label: 'ESTA SEMANA',
            value: Formatters.money(m.weekRevenue),
            subtitle: '${m.weekSalesCount} ventas',
            icon: Icons.calendar_view_week_rounded,
            accentColor: AppColors.amber,
          )
              .animate()
              .fadeIn(delay: 100.ms, duration: 500.ms)
              .slideY(begin: 0.3, end: 0),
        ),
      ],
    );
  }

  Widget _kpiRowSecond() {
    final m = _metrics!;
    return Row(
      children: [
        Expanded(
          child: KpiCard(
            label: 'PRODUCTOS',
            value: '${m.totalProducts}',
            subtitle: 'en catálogo',
            icon: Icons.inventory_2_outlined,
            accentColor: AppColors.info,
          )
              .animate()
              .fadeIn(delay: 150.ms, duration: 500.ms)
              .slideY(begin: 0.3, end: 0),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: KpiCard(
            label: 'ALERTAS',
            value: '${m.lowStockCount}',
            subtitle: 'con stock bajo',
            icon: Icons.warning_amber_rounded,
            accentColor:
                m.lowStockCount > 0 ? AppColors.danger : AppColors.success,
          )
              .animate()
              .fadeIn(delay: 200.ms, duration: 500.ms)
              .slideY(begin: 0.3, end: 0),
        ),
      ],
    );
  }

  Widget _chartSection() {
    final days = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    final data = _metrics!.weekSalesByDay;
    final maxY = data.reduce((a, b) => a > b ? a : b);
    final safeMax = maxY > 0 ? maxY * 1.25 : 50.0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('VENTAS SEMANALES', style: AppTextStyles.labelSm),
                    const SizedBox(height: 4),
                    Text(Formatters.money(_metrics!.weekRevenue),
                        style: AppTextStyles.kpiMedium()),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'Esta semana',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                maxY: safeMax,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: safeMax / 4,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.border,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= days.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(days[idx],
                              style: AppTextStyles.caption),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(data.length, (i) {
                  final today = DateTime.now().weekday - 1;
                  final isToday = i == today;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: data[i],
                        color: isToday
                            ? AppColors.primary
                            : AppColors.primaryContainer,
                        width: 20,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        Formatters.money(rod.toY),
                        AppTextStyles.label.copyWith(
                          color: AppColors.onPrimary,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 250.ms, duration: 500.ms);
  }

  Widget _lowStockSection() {
    final items = _metrics!.topLowStock;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Alertas de stock',
          action: widget.onGoToAlerts,
          actionLabel: 'Ver todas',
        ),
        const SizedBox(height: 12),
        ...items.asMap().entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AlertTile(product: e.value)
                    .animate()
                    .fadeIn(
                        delay: Duration(milliseconds: 300 + e.key * 60))
                    .slideX(begin: 0.05, end: 0),
              ),
            ),
      ],
    );
  }

  Widget _recentSalesSection() {
    final sales = _metrics!.recentSales.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Ventas recientes'),
        const SizedBox(height: 12),
        if (sales.isEmpty)
          const EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'Sin ventas aún',
            subtitle: 'Las ventas registradas aparecerán aquí.',
          )
        else
          ...sales.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SaleListTile(sale: e.value)
                      .animate()
                      .fadeIn(delay:
                          Duration(milliseconds: 350 + e.key * 60))
                      .slideX(begin: 0.05, end: 0),
                ),
              ),
      ],
    );
  }
}