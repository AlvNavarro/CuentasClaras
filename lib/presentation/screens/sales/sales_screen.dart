import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/download_helper.dart';
import '../../../data/models/product.dart';
import '../../../data/models/sale.dart';
import '../../../data/repositories/inventory_repository.dart';
import '../../../data/services/supabase_service.dart';
import '../../widgets/common_widgets.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});
  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final _repo = InventoryRepository.instance;
  List<Sale> _sales = [];
  bool _loading = true;
  bool get _isAdmin => SupabaseService.instance.isAdmin;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await _repo.getSales();
    if (mounted) setState(() { _sales = s; _loading = false; });
  }

  void _openNewSale() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _NewSaleSheet(repo: _repo, onCompleted: _load),
    );
  }

  void _showSaleDetail(Sale sale) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _TicketSheet(sale: sale),
    );
  }

  double get _totalToday {
    final today = DateTime.now();
    return _sales
        .where((s) =>
            s.createdAt.year == today.year &&
            s.createdAt.month == today.month &&
            s.createdAt.day == today.day)
        .fold(0, (a, b) => a + b.total);
  }

  double get _totalThisMonth {
    final now = DateTime.now();
    return _sales
        .where((s) =>
            s.createdAt.year == now.year &&
            s.createdAt.month == now.month)
        .fold(0, (a, b) => a + b.total);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ventas', style: AppTextStyles.h2),
            Text('${_sales.length} transacciones', style: AppTextStyles.caption),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'sales_fab',
        onPressed: _openNewSale,
        icon: const Icon(Icons.add_shopping_cart_rounded),
        label: const Text('Nueva venta'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                _summaryBanner(),
                Expanded(
                  child: _sales.isEmpty
                      ? EmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: 'Sin ventas registradas',
                          subtitle: 'Añade tu primera venta pulsando el botón.',
                          action: _openNewSale,
                          actionLabel: 'Registrar venta',
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: AppColors.primary,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                            itemCount: _sales.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (_, i) => SaleListTile(
                              sale: _sales[i],
                              onTap: () => _showSaleDetail(_sales[i]),
                            )
                                .animate()
                                .fadeIn(
                                    delay: Duration(milliseconds: i * 30),
                                    duration: 300.ms),
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _summaryBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('HOY',
                    style: AppTextStyles.labelSm
                        .copyWith(color: AppColors.primaryContainer)),
                const SizedBox(height: 4),
                Text(
                  Formatters.money(_totalToday),
                  style: AppTextStyles.kpiMedium(color: AppColors.onPrimary),
                ),
              ],
            ),
          ),
          if (_isAdmin)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('ESTE MES',
                    style: AppTextStyles.labelSm
                        .copyWith(color: AppColors.primaryContainer)),
                const SizedBox(height: 4),
                Text(
                  Formatters.money(_totalThisMonth),
                  style: AppTextStyles.price(color: AppColors.onPrimary, size: 18),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ─── TICKET SHEET ─────────────────────────────────────────────────────────────
class _TicketSheet extends StatelessWidget {
  const _TicketSheet({required this.sale});
  final Sale sale;

  Future<void> _shareTicket(BuildContext context) async {
    try {
      // Cargar fuentes con soporte de € y caracteres especiales
      final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      final ttf = pw.Font.ttf(fontData);
      final fontBoldData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
      final ttfBold = pw.Font.ttf(fontBoldData);

      final theme = pw.ThemeData.withFont(base: ttf, bold: ttfBold);

      final pdf = pw.Document();
      final ticketId = sale.id
          .substring(0, sale.id.length < 8 ? sale.id.length : 8)
          .toUpperCase();

      pdf.addPage(
        pw.Page(
          theme: theme,
          pageFormat: PdfPageFormat.a5,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context ctx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text('CuentasClaras',
                    style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
                pw.Text(Formatters.dateTime(sale.createdAt),
                    style: const pw.TextStyle(fontSize: 11)),
                pw.Text('No $ticketId',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                pw.SizedBox(height: 16),
                pw.Divider(),
                pw.SizedBox(height: 12),
                pw.Row(children: [
                  pw.Expanded(child: pw.Text('PRODUCTO',
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                  pw.Text('CANT.',
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(width: 16),
                  pw.SizedBox(
                    width: 60,
                    child: pw.Text('IMPORTE',
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.right),
                  ),
                ]),
                pw.SizedBox(height: 8),
                ...sale.items.map((item) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(item.productName,
                                style: pw.TextStyle(fontSize: 11,
                                    fontWeight: pw.FontWeight.bold)),
                            pw.Text(
                                '${_moneyPdf(item.unitPrice)} x ${item.quantity}',
                                style: const pw.TextStyle(
                                    fontSize: 9, color: PdfColors.grey600)),
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Text('${item.quantity}',
                          style: const pw.TextStyle(
                              fontSize: 11, color: PdfColors.grey600)),
                      pw.SizedBox(width: 16),
                      pw.SizedBox(
                        width: 60,
                        child: pw.Text(_moneyPdf(item.subtotal),
                            style: pw.TextStyle(fontSize: 11,
                                fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.right),
                      ),
                    ],
                  ),
                )),
                pw.SizedBox(height: 8),
                pw.Divider(),
                pw.SizedBox(height: 12),
                pw.Row(children: [
                  pw.Expanded(child: pw.Text('TOTAL',
                      style: pw.TextStyle(fontSize: 16,
                          fontWeight: pw.FontWeight.bold))),
                  pw.Text(_moneyPdf(sale.total),
                      style: pw.TextStyle(fontSize: 18,
                          fontWeight: pw.FontWeight.bold)),
                ]),
                pw.SizedBox(height: 8),
                pw.Row(children: [
                  pw.Expanded(child: pw.Text('Metodo de pago',
                      style: const pw.TextStyle(
                          fontSize: 10, color: PdfColors.grey600))),
                  pw.Text(sale.paymentMethod.label,
                      style: pw.TextStyle(fontSize: 10,
                          fontWeight: pw.FontWeight.bold)),
                ]),
                pw.SizedBox(height: 24),
                pw.Divider(),
                pw.SizedBox(height: 12),
                pw.Text('Gracias por tu compra!',
                    style: const pw.TextStyle(
                        fontSize: 11, color: PdfColors.grey600)),
                pw.SizedBox(height: 4),
                pw.Text('CuentasClaras - Tu negocio, sin cuentas pendientes.',
                    style: const pw.TextStyle(
                        fontSize: 9, color: PdfColors.grey500),
                    textAlign: pw.TextAlign.center),
              ],
            );
          },
        ),
      );

      final bytes = await pdf.save();

      if (kIsWeb) {
        downloadPdfWeb(bytes, 'ticket_$ticketId.pdf');
      } else {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/ticket_$ticketId.pdf');
        await file.writeAsBytes(bytes);
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'Ticket CuentasClaras - $ticketId',
          text: 'Ticket de venta por ${_moneyPdf(sale.total)}',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar el ticket: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  // Formateador de dinero sin € para el PDF (usa EUR para evitar problemas de charset)
  String _moneyPdf(double amount) {
    final formatted = amount.toStringAsFixed(2).replaceAll('.', ',');
    return '$formatted EUR';
  }

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
                width: 40, height: 4,
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
                    width: 56, height: 56,
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
                    'No ${sale.id.substring(0, sale.id.length < 8 ? sale.id.length : 8).toUpperCase()}',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textGhost),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _ticketDivider(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Text('PRODUCTO', style: AppTextStyles.labelSm)),
                Text('CANT.', style: AppTextStyles.labelSm),
                const SizedBox(width: 16),
                SizedBox(
                  width: 72,
                  child: Text('IMPORTE', style: AppTextStyles.labelSm,
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
                          Text(item.productName, style: AppTextStyles.label,
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                          Text(
                              '${Formatters.money(item.unitPrice)} x ${item.quantity}',
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
            _ticketDivider(),
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
                          AppTextStyles.label.copyWith(color: AppColors.amber)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: Text('Productos',
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.textSecondary))),
                Text('${sale.itemCount} ud.', style: AppTextStyles.label),
              ],
            ),
            const SizedBox(height: 28),
            _ticketDivider(),
            const SizedBox(height: 16),
            Center(
                child: Text('¡Gracias por tu compra!',
                    style:
                        AppTextStyles.body.copyWith(color: AppColors.textMuted))),
            const SizedBox(height: 4),
            Center(
              child: Text(
                  'CuentasClaras — Tu negocio, sin cuentas pendientes.',
                  style: AppTextStyles.caption, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _shareTicket(context),
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: Text(kIsWeb ? 'Descargar PDF' : 'Compartir'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _ticketDivider() {
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

// ─── NEW SALE SHEET ───────────────────────────────────────────────────────────
class _NewSaleSheet extends StatefulWidget {
  const _NewSaleSheet({required this.repo, required this.onCompleted});
  final InventoryRepository repo;
  final VoidCallback onCompleted;
  @override
  State<_NewSaleSheet> createState() => _NewSaleSheetState();
}

class _NewSaleSheetState extends State<_NewSaleSheet> {
  List<Product> _allProducts = [];
  final Map<String, int> _cart = {};
  PaymentMethod _method = PaymentMethod.cash;
  bool _loading = true;
  bool _saving = false;
  bool _scanning = false;
  final _search = TextEditingController();
  List<Product> _filtered = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _search.addListener(_filter);
  }

  Future<void> _loadProducts() async {
    final p = await widget.repo.getProducts();
    if (mounted) setState(() { _allProducts = p; _filtered = p; _loading = false; });
  }

  void _filter() {
    final q = _search.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _allProducts
          : _allProducts
              .where((p) =>
                  p.name.toLowerCase().contains(q) ||
                  p.sku.toLowerCase().contains(q))
              .toList();
    });
  }

  @override
  void dispose() { _search.dispose(); super.dispose(); }

  double get _cartTotal {
    double total = 0;
    for (final entry in _cart.entries) {
      final p = _allProducts.firstWhere((x) => x.id == entry.key,
          orElse: () => _allProducts.first);
      total += p.priceSale * entry.value;
    }
    return total;
  }

  int get _cartCount => _cart.values.fold(0, (a, b) => a + b);

  void _openScanner() => setState(() => _scanning = true);

  void _handleBarcode(String barcode) async {
    if (!_scanning) return;
    setState(() => _scanning = false);

    final product = await widget.repo.getProductByBarcode(barcode);
    if (!mounted) return;

    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Producto no encontrado: $barcode'),
            backgroundColor: AppColors.danger),
      );
      return;
    }

    final qty = _cart[product.id] ?? 0;
    if (product.stock > qty) {
      setState(() => _cart[product.id] = qty + 1);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('✓ ${product.name} añadido al carrito'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 1)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product.name} sin stock disponible'),
            backgroundColor: AppColors.warning),
      );
    }
  }

  Widget _buildScanner() {
    return Stack(
      children: [
        MobileScanner(
          onDetect: (capture) {
            final barcode = capture.barcodes.firstOrNull?.rawValue;
            if (barcode != null) _handleBarcode(barcode);
          },
        ),
        Positioned(
          top: 20, left: 0, right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text('Apunta al código de barras',
                  style: AppTextStyles.label.copyWith(color: Colors.white)),
            ),
          ),
        ),
        Center(
          child: Container(
            width: 240, height: 240,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary, width: 3),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        Positioned(
          bottom: 24, left: 0, right: 0,
          child: Center(
            child: ElevatedButton.icon(
              onPressed: () => setState(() => _scanning = false),
              icon: const Icon(Icons.close_rounded),
              label: const Text('Cancelar escaneo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: AppColors.onPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirm() async {
    if (_cart.isEmpty) return;
    setState(() => _saving = true);
    try {
      final items = _cart.entries.map((e) {
        final p = _allProducts.firstWhere((x) => x.id == e.key);
        return SaleItem(
          productId: p.id,
          productName: p.name,
          quantity: e.value,
          unitPrice: p.priceSale,
          sku: p.sku,
        );
      }).toList();

      final sale = await widget.repo.createSale(
        items: items,
        paymentMethod: _method,
      );

      widget.onCompleted();

      if (mounted) {
        Navigator.pop(context);
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => _TicketSheet(sale: sale),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.97,
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
                        child: Text('Nueva venta', style: AppTextStyles.h3)),
                    IconButton(
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                      tooltip: 'Escanear código de barras',
                      onPressed: _openScanner,
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 16),
              if (!_scanning)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _search,
                    decoration: const InputDecoration(
                      hintText: 'Buscar producto...',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                ),
              if (!_scanning) const SizedBox(height: 8),
              Expanded(
                child: _scanning
                    ? _buildScanner()
                    : _loading
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primary))
                        : ListView.separated(
                            controller: scroll,
                            padding:
                                const EdgeInsets.fromLTRB(20, 4, 20, 12),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final p = _filtered[i];
                              final qty = _cart[p.id] ?? 0;
                              return AppCard(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(p.name,
                                              style: AppTextStyles.label,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis),
                                          Text(
                                              '${Formatters.money(p.priceSale)} · ${p.stock} en stock',
                                              style: AppTextStyles.caption),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (qty > 0) ...[
                                          _qtyBtn(Icons.remove_rounded, () {
                                            setState(() {
                                              if (qty > 1) {
                                                _cart[p.id] = qty - 1;
                                              } else {
                                                _cart.remove(p.id);
                                              }
                                            });
                                          }),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10),
                                            child: Text('$qty',
                                                style: AppTextStyles.label),
                                          ),
                                        ],
                                        _qtyBtn(
                                          Icons.add_rounded,
                                          p.stock > qty
                                              ? () => setState(
                                                  () => _cart[p.id] = qty + 1)
                                              : null,
                                          filled: true,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
              if (_cartCount > 0 && !_scanning) ...[
                const Divider(height: 1),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text('Método de pago', style: AppTextStyles.label),
                          const Spacer(),
                          ...PaymentMethod.values.map(
                            (m) => Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: GestureDetector(
                                onTap: () => setState(() => _method = m),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _method == m
                                        ? AppColors.primary
                                        : AppColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Text(m.icon,
                                      style: const TextStyle(fontSize: 18)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _confirm,
                          child: _saving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: AppColors.onPrimary))
                              : Text(
                                  'Confirmar venta · ${Formatters.money(_cartTotal)}'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback? onTap, {bool filled = false}) {
    return Material(
      color: filled ? AppColors.primary : AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon,
              size: 16,
              color: filled
                  ? AppColors.onPrimary
                  : AppColors.textSecondary),
        ),
      ),
    );
  }
}