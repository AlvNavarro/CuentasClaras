import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/sale.dart';
import '../../../data/repositories/inventory_repository.dart';
import '../../widgets/common_widgets.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _repo = InventoryRepository.instance;
  List<Sale> _allSales = [];
  bool _loading = true;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sales = await _repo.getSales();
    if (mounted) setState(() { _allSales = sales; _loading = false; });
  }

  List<Sale> get _selectedDaySales => _allSales.where((s) =>
      s.createdAt.year == _selectedDay.year &&
      s.createdAt.month == _selectedDay.month &&
      s.createdAt.day == _selectedDay.day).toList();

  Set<String> get _daysWithSales => _allSales.map((s) =>
      '${s.createdAt.year}-${s.createdAt.month}-${s.createdAt.day}').toSet();

  bool _hasSales(DateTime day) =>
      _daysWithSales.contains('${day.year}-${day.month}-${day.day}');

  bool _isSelected(DateTime day) =>
      day.year == _selectedDay.year &&
      day.month == _selectedDay.month &&
      day.day == _selectedDay.day;

  bool _isToday(DateTime day) {
    final now = DateTime.now();
    return day.year == now.year &&
        day.month == now.month &&
        day.day == now.day;
  }

  double get _selectedDayTotal =>
      _selectedDaySales.fold(0, (a, b) => a + b.total);

  List<DateTime?> get _calendarDays {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDay = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final List<DateTime?> days = [];

    final startWeekday = firstDay.weekday - 1;
    for (int i = 0; i < startWeekday; i++) {
      days.add(null);
    }
    for (int i = 1; i <= lastDay.day; i++) {
      days.add(DateTime(_focusedMonth.year, _focusedMonth.month, i));
    }
    return days;
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Histórico', style: AppTextStyles.h2),
            Text('Ventas por día', style: AppTextStyles.caption),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                children: [
                  AppCard(
                    child: Column(
                      children: [
                        _calendarHeader(),
                        const SizedBox(height: 12),
                        _calendarWeekdays(),
                        const SizedBox(height: 8),
                        _calendarGrid(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _dayHeader(),
                  const SizedBox(height: 12),
                  if (_selectedDaySales.isEmpty)
                    EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'Sin ventas este día',
                      subtitle:
                          'No hay ventas registradas para el ${Formatters.dateShort(_selectedDay)}.',
                    )
                  else
                    ..._selectedDaySales.asMap().entries.map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _SaleHistoryTile(
                              sale: e.value,
                              index: e.key + 1,
                            ).animate().fadeIn(
                                  delay: Duration(milliseconds: e.key * 60),
                                  duration: 300.ms,
                                ),
                          ),
                        ),
                ],
              ),
            ),
    );
  }

  Widget _calendarHeader() {
    final monthNames = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: _previousMonth,
          color: AppColors.textSecondary,
        ),
        Expanded(
          child: Text(
            '${monthNames[_focusedMonth.month - 1]} ${_focusedMonth.year}',
            style: AppTextStyles.h3,
            textAlign: TextAlign.center,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed: _nextMonth,
          color: AppColors.textSecondary,
        ),
      ],
    );
  }

  Widget _calendarWeekdays() {
    const days = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    return Row(
      children: days
          .map((d) => Expanded(
                child: Center(child: Text(d, style: AppTextStyles.labelSm)),
              ))
          .toList(),
    );
  }

  Widget _calendarGrid() {
    final days = _calendarDays;
    final rows = (days.length / 7).ceil();

    return Column(
      children: List.generate(rows, (rowIndex) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: List.generate(7, (colIndex) {
              final idx = rowIndex * 7 + colIndex;
              if (idx >= days.length || days[idx] == null) {
                return const Expanded(child: SizedBox(height: 40));
              }
              final day = days[idx]!;
              final selected = _isSelected(day);
              final today = _isToday(day);
              final hasSales = _hasSales(day);

              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedDay = day),
                  child: Container(
                    height: 40,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary
                          : today
                              ? AppColors.primaryContainer
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          '${day.day}',
                          style: AppTextStyles.label.copyWith(
                            color: selected
                                ? AppColors.onPrimary
                                : today
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                            fontWeight: today || selected
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                        if (hasSales && !selected)
                          Positioned(
                            bottom: 4,
                            child: Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        if (hasSales && selected)
                          Positioned(
                            bottom: 4,
                            child: Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: AppColors.onPrimary.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _dayHeader() {
    final count = _selectedDaySales.length;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(Formatters.dateLong(_selectedDay), style: AppTextStyles.h3),
              Text(
                '$count venta${count == 1 ? '' : 's'}',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
        if (count > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              Formatters.money(_selectedDayTotal),
              style: AppTextStyles.price(color: AppColors.primary, size: 16),
            ),
          ),
      ],
    );
  }
}

// ─── SALE HISTORY TILE ────────────────────────────────────────────────────────

class _SaleHistoryTile extends StatelessWidget {
  const _SaleHistoryTile({required this.sale, required this.index});
  final Sale sale;
  final int index;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => _TicketDetail(sale: sale),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.amberContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    sale.paymentMethod.icon,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Venta #$index · ${sale.paymentMethod.label}',
                      style: AppTextStyles.label,
                    ),
                    Text(
                      Formatters.time(sale.createdAt),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              Text(
                Formatters.money(sale.total),
                style: AppTextStyles.price(color: AppColors.amber, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          ...sale.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '${item.quantity}',
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.productName,
                      style: AppTextStyles.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    Formatters.money(item.subtotal),
                    style: AppTextStyles.bodySm,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Ver ticket →',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── TICKET DETAIL ────────────────────────────────────────────────────────────

class _TicketDetail extends StatelessWidget {
  const _TicketDetail({required this.sale});
  final Sale sale;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      expand: false,
      builder: (ctx, scroll) => Container(
        color: AppColors.surface,
        child: ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 40),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.receipt_long_rounded,
                        color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(height: 12),
                  Text('CuentasClaras', style: AppTextStyles.h3),
                  const SizedBox(height: 4),
                  Text(Formatters.dateTime(sale.createdAt),
                      style: AppTextStyles.caption),
                  const SizedBox(height: 4),
                  Text(
                    'Nº ${sale.id.substring(0, sale.id.length < 8 ? sale.id.length : 8).toUpperCase()}',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textGhost),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: Text('PRODUCTO', style: AppTextStyles.labelSm)),
                Text('CANT.', style: AppTextStyles.labelSm),
                const SizedBox(width: 16),
                SizedBox(
                  width: 72,
                  child: Text('IMPORTE',
                      style: AppTextStyles.labelSm,
                      textAlign: TextAlign.right),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...sale.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.productName,
                              style: AppTextStyles.label,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                          Text(
                              '${Formatters.money(item.unitPrice)} × ${item.quantity}',
                              style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${item.quantity}',
                        style: AppTextStyles.label
                            .copyWith(color: AppColors.textMuted)),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 72,
                      child: Text(Formatters.money(item.subtotal),
                          style: AppTextStyles.price(size: 14),
                          textAlign: TextAlign.right),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            _divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Text('TOTAL', style: AppTextStyles.h3)),
                Text(Formatters.money(sale.total),
                    style: AppTextStyles.kpiMedium(color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text('Método de pago',
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.textSecondary)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                      color: AppColors.amberContainer,
                      borderRadius: BorderRadius.circular(100)),
                  child: Text(
                    '${sale.paymentMethod.icon} ${sale.paymentMethod.label}',
                    style:
                        AppTextStyles.label.copyWith(color: AppColors.amber),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            _divider(),
            const SizedBox(height: 16),
            Center(
              child: Text('¡Gracias por tu compra!',
                  style:
                      AppTextStyles.body.copyWith(color: AppColors.textMuted)),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                  'CuentasClaras — Tu negocio, sin cuentas pendientes.',
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Row(
      children: List.generate(
        40,
        (i) => Expanded(
          child: Container(
              height: 1,
              color: i % 2 == 0 ? AppColors.border : Colors.transparent),
        ),
      ),
    );
  }
}